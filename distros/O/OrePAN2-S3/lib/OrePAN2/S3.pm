package OrePAN2::S3;

use strict;
use warnings;

use Amazon::Credentials;
use Amazon::S3;
use Archive::Tar;
use Bedrock::Template;
use Carp;
use CLI::Simple;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::Temp qw(tempfile);
use JSON;
use OrePAN2::Index;
use YAML;

use Readonly;

Readonly::Scalar our $PACKAGE_INDEX  => '02packages.details.txt.gz';
Readonly::Scalar our $DEFAULT_CONFIG => $ENV{HOME} . '/.orepan2-s3.json';
Readonly::Scalar our $TRUE           => 1;
Readonly::Scalar our $FALSE          => 0;

use parent qw(CLI::Simple);

our $VERSION = '0.01';

caller or __PACKAGE__->main();

########################################################################
sub slurp_file {
########################################################################
  my ($file) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or die "could not open $file\n";

  my $content = <$fh>;

  close $fh;

  return $content;
}

########################################################################
sub fetch_config {
########################################################################
  my ($self) = @_;

  my $file = $self->get_config_file;

  die "no config file specified\n"
    if !$file;

  die "$file not found\n"
    if !-e $file;

  my $config = eval { return JSON->new->decode( slurp_file($file) ); };

  die "could not read config file\n$EVAL_ERROR"
    if !$config || $EVAL_ERROR;

  $self->set_config($config);

  return $config;
}

########################################################################
sub get_bucket {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my ( $bucket_name, $prefix, $profile ) = @{ $config->{AWS} }{qw(bucket prefix profile)};

  my $s3 = $self->get_s3;

  my $credentials = $self->get_credentials;

  if ( !$s3 ) {
    $s3 = Amazon::S3->new( credentials => $credentials );
    $self->set_s3($s3);
  }

  return $s3->bucket($bucket_name);
}

########################################################################
sub fetch_orepan_index {
########################################################################
  my ( $self, $unlink ) = @_;

  $unlink //= $TRUE;

  my ( $fh, $filename ) = tempfile(
    'XXXXXX',
    SUFFIX => '.gz',
    UNLINK => $unlink,
  );

  my $config = $self->get_config;

  my $object = sprintf '%s/modules/%s', $config->{AWS}->{prefix}, $PACKAGE_INDEX;

  my $bucket = $self->get_bucket;
  $bucket->get_key_filename( $object, GET => $filename );

  return $filename;
}

########################################################################
sub invalidate_index {
########################################################################
  my ($self) = @_;

  # TBD
  return;
}

########################################################################
sub create_invalidation_batch {
########################################################################
  my (%args) = @_;

  local $LIST_SEPARATOR = q{};

  my @now = localtime;

  my $caller_reference = $args{CallerReference} || "@now";

  my $invalidation_batch = {
    DistributionId    => $args{DistributionId},
    InvalidationBatch => {
      CallerReference => $caller_reference,
      Paths           => {
        Items    => $args{Items},
        Quantity => scalar @{ $args{Items} },
      }
    }
  };

  return $invalidation_batch;
}

########################################################################
sub upload_index {
########################################################################
  my ($self) = @_;

  my ($index) = $self->get_args();
  $index //= 'index.html';

  croak sprintf '%s not found', $index
    if !-e $index;

  my $bucket = $self->get_bucket();
  $bucket->add_key_filename( 'index.html', $index, { 'content-type' => 'text/html' } );

  return;
}

########################################################################
sub show_orepan_index {
########################################################################
  my ($self) = @_;

  my $file = $self->fetch_orepan_index;

  my $index = OrePAN2::Index->new();

  $index->load($file);

  my $listing = $index->as_string;

  return $self->send_output($listing);
}

########################################################################
sub create_index {
########################################################################
  my ($self) = @_;

  my $file = $self->fetch_orepan_index;

  my $repo = $self->parse_index($file);

  no strict 'refs';  ## no critic

  *{'utils::module_name'} = sub {
    my ( $self, $distribution ) = @_;

    my ($module_name) = split /[\-]/xsm, basename($distribution);

    return $module_name;
  };

  my $utils = bless {}, 'utils';

  my $params = {
    utils     => $utils,
    repo      => $repo,
    localtime => scalar localtime
  };

  my $bedrock = Bedrock::Template->new(
    { text   => $self->get_template,
      params => $params,
    }
  );

  my $index = $bedrock->parse();

  return $self->send_output($index);

}

########################################################################
sub send_output {
########################################################################
  my ( $self, $content ) = @_;

  my $outfile = $self->get_output;

  my $fh = eval {

    return *STDOUT
      if !$outfile;

    open my $fh, '>', $outfile;

    return $fh;
  };

  die "could not open file for output\n$EVAL_ERROR"
    if !$fh;

  print {$fh} $content;

  $outfile && close $fh;

  return 0;
}

########################################################################
sub parse_index {
########################################################################
  my ( $self, $file ) = @_;

  my $index = OrePAN2::Index->new();

  $index->load($file);

  my $listing = $index->as_string;
  $listing =~ s/^(.*)\n\n//xsm;

  my %repo;

  foreach ( split /\n/xsm, $listing ) {
    my ( $module, $version, $package ) = split /\s+/xsm;
    $repo{$package} //= [];
    push @{ $repo{$package} }, [ $module, $version ];
  }

  return \%repo;
}

########################################################################
sub download_orepan_index {
########################################################################
  my ($self) = @_;

  my $filename = eval { return $self->fetch_orepan_index(); };

  die "could not download $PACKAGE_INDEX\n$EVAL_ERROR"
    if !$filename || !-s "$filename";

  rename $filename, $PACKAGE_INDEX;

  print {*STDOUT} $PACKAGE_INDEX . "\n";

  return;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  $self->fetch_config;

  my $profile = $self->get_config->{AWS}->{profile};

  my $credentials = Amazon::Credentials->new( profile => $profile );

  $self->set_credentials($credentials);

  $self->fetch_template;

  return;
}

########################################################################
sub fetch_template {
########################################################################
  my ($self) = @_;

  local $RS = undef;

  my $fh = *DATA;

  my $index_template = <$fh>;
  $index_template =~ s/\n\n=pod.*$/\n/xsm;

  $self->set_template($index_template);

  return;
}

########################################################################
sub extract_from_tarball {
########################################################################
  my ( $tarball, $file ) = @_;

  my $t = Archive::Tar->new;

  $t->read( $tarball, 1 )
    or croak "failed to read tarball: $tarball";

  my $prefix = basename($tarball);
  $prefix =~ s/[.]tar.*$//xsm;

  croak "file not found ($prefix/$file)"
    if !$t->contains_file("$prefix/$file");

  my $content = eval { return Load( $t->get_content("$prefix/$file") ); };

  return $content;
}

########################################################################
sub main {
########################################################################
  my $cli = OrePAN2::S3->new(
    option_specs => [
      qw(
        help|h
        config-file|c=s
        output|o=s
      )
    ],
    default_options => { config_file => $DEFAULT_CONFIG, },
    extra_options   => [qw(config s3 credentials template)],
    commands        => {
      create   => \&create_index,
      show     => \&show_orepan_index,
      download => \&download_orepan_index,
      upload   => \&upload_index,
    },
  );

  return $cli->run();
}

1;

__DATA__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-15">
    <title>TBC CPAN Repository</title>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"
    integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo="
    crossorigin="anonymous"></script>

    <script>
    $(function() {
        $('.collapsable').hide();

        $('h2').on('click', function() {
            $(this).next().toggle();
        });
    });

    </script>
    <style>
    h2 {
      cursor: pointer;
      color: purple;
    }
    h2:hover {
      color: green;
    }
    body {
      font-family: monospace;
    }
    </style>
  </head>
  
  <body>
    <h1>TBC CPAN Repository</h1>
    
<foreach --define-var="distribution" $repo.keys()->
      <h2><var $distribution></h2>

      <ul class="collapsable" id="<var $utils.module_name($distribution)>">
<foreach --define-var="module" $repo.get($distribution) ->
        <li><var $module.[0]></li>
</foreach->
      </ul>
</foreach->
    
    <hr>
    <address>Generated on <var $localtime></address>
  </body>
</html>

=pod

=head1 USAGE

 orepan2-s3 Options Command

Script for maintaining a DarkPAN mirror using S3 + CloudFront

=head2 Commmands

=over 5

=item * create - Create a new F<index.html> from the mirror's manifest file.

=item * download - Download the mirror's manifest file (F<02packages.details.text.gz>).

=item * show - Print the manifest file to STDOUT or a file.

=item * upload - Upload the index.html file to the mirror's root.

=back

=head2 Options

 -h, --help         Display this help message
 -c, --config-file  Name of the configuration file (default: cf-cpan-mirror.json)
 -o, --output       Name of the output file

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut
