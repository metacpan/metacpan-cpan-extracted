package OrePAN2::S3;

use strict;
use warnings;

use Amazon::Credentials;
use Amazon::S3::Lite;
use Carp;
use CLI::Simple::Utils qw(choose);
use CLI::Simple::Constants qw(:booleans);
use Data::Dumper;
use English qw(-no_match_vars);
use Encode qw(encode_utf8);
use File::Basename qw(basename);
use File::Temp qw(tempfile);
use JSON;
use List::Util qw(pairs);
use Scalar::Util qw(openhandle);

use Readonly;

Readonly::Scalar our $PACKAGE_INDEX  => '02packages.details.txt.gz';
Readonly::Scalar our $DEFAULT_CONFIG => $ENV{HOME} . '/.orepan2-s3.json';
Readonly::Scalar our $METACPAN_URL   => 'https://metacpan.org/pod';
Readonly::Scalar our $AUTHOR_PATH    => 'D/DU/DUMMY';

use Role::Tiny::With;

with 'OrePAN2::S3::Role::Inject';
with 'OrePAN2::S3::Role::Delete';
with 'OrePAN2::S3::Role::UploadArtifacts';

use parent qw(CLI::Simple);

our $VERSION = '1.2.1';

__PACKAGE__->use_log4perl( level => 'info' );

caller or __PACKAGE__->main();

########################################################################
sub slurp_file {
########################################################################
  my ( $file, $json ) = @_;

  local $RS = undef;

  my $content;

  if ( openhandle $file ) {
    $content = <$file>;
  }
  else {
    open my $fh, '<', $file
      or die "could not open $file for reading: $OS_ERROR";

    $content = <$fh>;

    close $fh;
  }

  return JSON->new->decode($content)
    if $json;

  return wantarray ? split /\n/xsm, $content : $content;
}

########################################################################
sub write_config {
########################################################################
  my ( $self, $config ) = @_;

  my $file = $self->get_config_file;

  croak "ERROR: no config file set or config not found\n"
    if !$file || !-e $file;

  croak "ERROR: $file is not writable\n"
    if !-w $file;

  my $full_config = slurp_file( $file, $TRUE );  # slurp as JSON
  my $profile_name //= $self->get_profile_name // 'default';

  $full_config->{$profile_name} = $config;

  open my $fh, '>', $file
    or croak "ERROR: Could not open $file for writing: $OS_ERROR\n";

  print {$fh} JSON->new->pretty->encode($full_config);

  close $fh;

  return;
}

########################################################################
sub fetch_config {
########################################################################
  my ( $self, $profile_name ) = @_;

  $profile_name //= $self->get_profile_name // 'default';

  my $file = $self->get_config_file;

  die "no config file specified\n"
    if !$file;

  die "$file not found\n"
    if !-e $file;

  my $config = eval { return JSON->new->decode( scalar slurp_file($file) ); };

  die "could not read config file ($file)\n$EVAL_ERROR"
    if !$config || $EVAL_ERROR;

  if ( $config->{$profile_name} && ref $config->{$profile_name} ) {
    $config = $config->{$profile_name};
  }
  elsif ( $config->{$profile_name} ) {
    $config = $config->{ $config->{$profile_name} };
  }

  croak sprintf "ERROR: %s not a valid profile name\n", $profile_name
    if !ref $config;

  $self->set_config($config);

  return $config;
}

########################################################################
sub init_s3 {
########################################################################
  my ($self) = @_;

  my $config      = $self->get_config;
  my $credentials = $self->get_credentials;

  my $region = $config->{AWS}{region} // $credentials->get_region // $ENV{AWS_REGION} // $ENV{AWS_DEFAULT_REGION}
    // 'us-east-1';

  my $s3 = Amazon::S3::Lite->new(
    { region      => $region,
      credentials => $credentials,
    }
  );

  $self->set_s3($s3);

  return;
}

########################################################################
sub fetch_orepan_index {
########################################################################
  my ($self) = @_;

  my ( $fh, $filename ) = tempfile(
    'XXXXXX',
    SUFFIX => '.gz',
    UNLINK => $FALSE,
  );

  my $config = $self->get_config;

  my $key = sprintf '%s/modules/%s', $config->{AWS}{prefix}, $PACKAGE_INDEX;
  $self->get_s3->get_object( $self->get_bucket_name, $key, filename => $filename );

  return $filename;
}

########################################################################
sub cmd_invalidate_index {
########################################################################
  my ($self) = @_;

  warn "Not implemented yet\n";

  return $SUCCESS;
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
sub _upload_html {
########################################################################
  my ( $self, $file, $key ) = @_;

  croak sprintf '%s not found', $file
    if !ref $file && !-e $file;

  my $content = ref $file ? ${$file} : slurp_file($file);
  my $encoded = encode_utf8($content);
  $self->get_s3->put_object( $self->get_bucket_name, $key, $encoded, content_type => 'text/html', );

  return;
}

# should be a method of OrePAN2::Index (someday)
########################################################################
sub _packages_for_archive {
########################################################################
  my ( $self, $index, $archive_path ) = @_;

  return grep {
    my ( undef, $path ) = $index->lookup($_);
    $path eq $archive_path;
  } $index->packages;
}

########################################################################
sub update_index {
########################################################################
  my ( $self, $code ) = @_;

  require IO::Compress::Gzip;
  require OrePAN2::Index;

  my $config = $self->get_config;
  my $prefix = $config->{AWS}{prefix};

  my $index_file = $self->fetch_orepan_index;
  my $index      = OrePAN2::Index->new;
  $index->load($index_file);
  unlink $index_file;

  $code->($index);

  my $gz_content;
  my $gz = IO::Compress::Gzip->new( \$gz_content ) or die "gzip failed\n";
  $gz->print( $index->as_string );
  $gz->close;

  my $index_key = sprintf '%s/modules/02packages.details.txt.gz', $prefix;
  $self->get_s3->put_object( $self->get_bucket_name, $index_key, $gz_content, content_type => 'application/gzip', );

  $self->get_logger->info( sprintf 'updated index at %s', $index_key );

  return;
}

########################################################################
sub scan_provides {
########################################################################
  my ( $self, $file ) = @_;

  require Archive::Tar;
  require CPAN::Meta;

  my $tar = Archive::Tar->new;
  $tar->read($file);

  # find the top-level prefix, e.g. "CPAN-Maker-1.8.2"
  my ($entry) = grep { $_->name =~ m{/META\.(?:json|yml|yaml)$}xsm } $tar->get_files;

  if ( !$entry ) {
    $self->get_logger->warn("no META file found in $file");
    return {};
  }

  my ($prefix) = ( split m{/}xsm, $entry->name )[0];

  for my $metafile (qw(META.json META.yml META.yaml)) {
    my $content = eval { $tar->get_content("$prefix/$metafile") };
    next if !$content;

    my $meta = eval { CPAN::Meta->load_string($content) };
    next if !$meta || $EVAL_ERROR;

    return $meta->{provides} if $meta->{provides};
  }

  # Should not happen - injecting tarballs we create with CPAN::Maker
  $self->get_logger->warn("META found but no provides in $file");

  return {};
}

########################################################################
# COMMANDS
########################################################################

########################################################################
sub cmd_upload_index {
########################################################################
  my ( $self, $index ) = @_;

  if ( !$index ) {
    ($index) = $self->get_args();
  }

  $index //= 'index.html';

  return $self->_upload_html( $index, 'index.html' );
}

########################################################################
sub cmd_show_orepan_index {
########################################################################
  my ($self) = @_;

  my $file = $self->fetch_orepan_index;

  require OrePAN2::Index;

  my $index = OrePAN2::Index->new();

  $index->load($file);

  my $listing = $index->as_string;

  unlink $file;

  return $self->send_output($listing);
}

########################################################################
sub cmd_create_docs {
########################################################################
  my ($self) = @_;

  require DarkPAN::Utils;

  my ($distribution) = $self->get_args();
  $distribution //= $self->get_distribution();

  die "use -d or pass distribution name as an argument\n"
    if !$distribution;

  my ( $key_prefix, $version ) = DarkPAN::Utils::parse_distribution_path($distribution);

  my $dpu = choose {
    if ( -e $distribution && $distribution !~ /^(?:http|D\/DU)/xsm ) {
      require Archive::Tar;

      my $tar = Archive::Tar->new;
      $tar->read($distribution);
      return DarkPAN::Utils->new( package => $tar );
    }

    $distribution = basename($distribution);

    if ( $distribution !~ /^http/xsm ) {
      $distribution = sprintf 'D/DU/DUMMY/%s', $distribution;
    }

    my $orepan_url = $self->get_url // $self->get_config->{url};

    die "use --url or set url in config\n"
      if !$orepan_url;

    my $dpu = DarkPAN::Utils->new( base_url => $orepan_url );

    $dpu->fetch_package($distribution);

    return $dpu;
  };

  my $module_name = $key_prefix;
  $module_name =~ s/\-/::/gxsm;

  my $file = $dpu->extract_module( $distribution, $module_name );

  if ( $self->get_upload ) {
    if ($file) {
      $self->upload_html(
        name         => "$key_prefix.html",
        content      => $file,
        prefix       => $key_prefix,
        wrap         => $TRUE,
        distribution => basename($distribution),
      );
    }
  }
  else {
    open my $fh, '>', "$key_prefix.html"
      or die "could not open $key_prefix.html for writing\n";

    print {$fh} $file;

    close $fh;
  }

  my $readme = $dpu->extract_file( sprintf '%s-%s/README.md', $key_prefix, $version );

  if ( $self->get_upload && $readme ) {
    $self->upload_html(
      name     => 'README.html',
      markdown => $readme,
      prefix   => $key_prefix,
      wrap     => $TRUE,
    );
  }
  elsif ($readme) {
    open my $fh, '>', 'README.html'
      or die "could not open README.html for writing\n";

    print {$fh} $readme;

    close $fh;
  }

  return 0;
}

########################################################################
sub upload_html {
########################################################################
  my ( $self, %args ) = @_;

  my ( $content, $prefix, $name, $markdown, $distribution ) = @args{qw(content prefix name markdown distribution)};

  my $perldoc_url_distros = $self->get_config->{perldoc_url_distros} // [];
  my $perldoc_url_prefix;

  if ($distribution) {
    foreach my $p ( pairs @{$perldoc_url_distros} ) {

      my ( $pattern, $flags ) = @{$p};
      my $qr = qr/(?$flags:$pattern)/;
      next if $distribution !~ $qr;

      $perldoc_url_prefix = $self->get_config->{perldoc_url_prefix};
      last;
    }
  }

  $perldoc_url_prefix //= $METACPAN_URL;

  my $html = choose {
    if ($markdown) {
      require Text::Markdown::Discount;

      Text::Markdown::Discount::markdown($markdown);
    }

    require DarkPAN::Utils::Docs;

    my $docs = DarkPAN::Utils::Docs->new(
      text       => $content,
      url_prefix => $perldoc_url_prefix,
    );

    return $docs->get_html;
  };

  if ( $args{wrap} ) {
    $html = <<"END_OF_HTML";
<!DOCTYPE HTML>
<html>
 <head>
   <title>README</title>
   <link rel="stylesheet" href="/css/pod.css">
 </head>
 <body>
  $html
 </body>
</html>
END_OF_HTML
  }

  my $key = sprintf 'docs/%s/%s', $prefix, $name;

  $self->_upload_html( \$html, $key );

  return;
}

########################################################################
sub look_for_object {
########################################################################
  my ( $self, $prefix, $name ) = @_;

  my $key = sprintf 'docs/%s/%s', $prefix, $name;

  return sprintf '/docs/%s/%s', $prefix, $name
    if $self->get_s3->head_object( $self->get_bucket_name, $key );

  return;
}

########################################################################
sub cmd_create_index {
########################################################################
  my ($self) = @_;

  require DarkPAN::Utils;

  my $config = $self->get_config;

  my $file = $self->fetch_orepan_index;

  my $repo = $self->parse_index($file);

  unlink $file;

  $self->get_logger->debug( Dumper( [ repo => $repo ] ) );

  no strict 'refs'; ## no critic

  *{'utils::module_name'} = sub {
    my ( $self, $distribution ) = @_;

    my $module_name = basename("/$distribution");
    $module_name =~ s/-\d+[.].*$//xsm;

    return $module_name;
  };

  my $utils = bless {}, 'utils';

  my $sections = $config->{custom_sections} // {};

  foreach my $var ( keys %{$sections} ) {
    my ( $pattern, $flags ) = @{ $sections->{$var} };

    my $qr = qr/(?$flags:$pattern)/;
    $sections->{$var} = [ $pattern, $flags, $qr ];
  }

  my %readme_links;
  my %pod_links;

  foreach my $distribution ( keys %{$repo} ) {

    my ($distribution_name) = DarkPAN::Utils::parse_distribution_path($distribution);

    my $readme = $self->look_for_object( $distribution_name, 'README.html' );

    my $pod = $self->look_for_object( $distribution_name, "${distribution_name}.html" );

    my $old_name = $distribution;
    $distribution =~ s/^.*\/([^\/]+)/$1/xsm;
    $repo->{$distribution} = delete $repo->{$old_name};

    if ($readme) {
      $readme_links{$distribution} = $readme;
    }

    if ($pod) {
      $pod_links{$distribution} = $pod;
    }

    if ($sections) {
      foreach my $var ( keys %{$sections} ) {
        if ( $distribution =~ $sections->{$var}->[2] ) {
          $sections->{$var}->[3] //= {};
          $sections->{$var}->[3]->{$distribution} = delete $repo->{$distribution};
        }
      }
    }
  }

  my $params = {
    utils        => $utils,
    repo         => $repo,
    readme_links => \%readme_links,
    pod_links    => \%pod_links,
    localtime    => scalar localtime,
    map { ( $_ => $sections->{$_}->[3] ) } keys %{$sections},

  };

  $self->get_logger->trace( Dumper( [ params => $params ] ) );

  my $text = $self->get_template;

  require Template;

  my $template = Template->new();

  my $output = q{};

  $template->process( \$text, $params, \$output )
    or die $template->error();

  if ( $self->get_upload ) {
    $self->_upload_html( \$output, 'index.html' );
    $self->get_logger->debug($output);
  }
  else {
    $self->send_output($output);
  }

  return 0;
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

  require OrePAN2::Index;

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
sub cmd_download_orepan_index {
########################################################################
  my ($self) = @_;

  my $filename = eval { return $self->fetch_orepan_index(); };

  die "ERROR: Could not download $PACKAGE_INDEX\n$EVAL_ERROR"
    if !$filename || !-s "$filename";

  rename $filename, $PACKAGE_INDEX;

  print {*STDOUT} $PACKAGE_INDEX . "\n";

  return;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my $config = $self->fetch_config;

  my $profile = $config->{AWS}->{profile};

  my $credentials = Amazon::Credentials->new( profile => $profile );
  $self->set_credentials($credentials);

  my $bucket_name = $self->get_bucket_name // $config->{AWS}->{bucket};

  $self->set_bucket_name($bucket_name);

  $self->init_s3;

  my $author_path = $config->{author_path} // $AUTHOR_PATH;
  $self->set_author_path($author_path);

  $self->fetch_template;

  return;
}

########################################################################
sub fetch_template {
########################################################################
  my ($self) = @_;

  my $template = $self->get_template;

  my $index = $self->get_config->{index} // {};

  # see if the index is set in the config file...
  if ( !$template && $index->{template} ) {
    $template = $index->{template};
  }

  my $index_template = $template eq 'default' ? slurp_file(*DATA) : slurp_file($template);

  $index_template =~ s/\n\n=pod.*$/\n/xsm;

  $self->set_template($index_template);

  return;
}

########################################################################
sub extract_from_tarball {
########################################################################
  my ( $tarball, $file ) = @_;

  require Archive::Tar;

  my $t = Archive::Tar->new;

  $t->read( $tarball, 1 )
    or croak "failed to read tarball: $tarball";

  my $prefix = basename($tarball);
  $prefix =~ s/[.]tar.*$//xsm;

  croak "file not found ($prefix/$file)"
    if !$t->contains_file("$prefix/$file");

  return $t->get_content("$prefix/$file");
}

########################################################################
sub main {
########################################################################
  my $cli = OrePAN2::S3->new(
    option_specs => [
      qw(
        help|h
        bucket-name|b=s
        config-file|c=s
        output|o=s
        profile|p=s
        profile-name|n=s
        template|t=s
        url|U=s
        distribution|d=s
        upload|u
      )
    ],
    default_options => {
      config_file  => $DEFAULT_CONFIG,
      profile_name => 'default',
      profile      => $ENV{AWS_PROFILE}
    },
    extra_options => [qw(config credentials template author_path s3)],
    commands      => {
      'create-docs'   => \&cmd_create_docs,
      create          => \&cmd_create_index,
      delete          => \&cmd_delete,
      download        => \&cmd_download_orepan_index,
      'dump-template' => sub {
        print {*STDOUT} shift->get_template;
        return 0;
      },
      inject             => \&cmd_inject,
      'invalidate-index' => \&cmd_invalidate_index,
      show               => \&cmd_show_orepan_index,
      upload             => \&cmd_upload_index,
      'upload-artifacts' => \&cmd_upload_artifacts,
    },
  );

  return $cli->run();
}

1;

__DATA__
<!DOCTYPE HTML>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-15">
    <title>CPAN Repository</title>
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
    <h1>CPAN Repository</h1>
    
[% FOREACH distribution = repo.keys %]
      <h2>[% distribution %]</h2>

      <ul class="collapsable" id="[% utils.module_name(distribution) %]">
[% FOREACH module IN repo.$distribution %]
        <li>[%  module.0 %]</li>
[% END %]
      </ul>
[% END %]
    
    <hr>
    <address>Generated on [% localtime %] by Template::Toolkit</address>
  </body>
</html>

=pod

=head1 NAME

 OrePAN2::S3 - Manage a DarkPAN CPAN mirror on Amazon S3

=head1 SYNOPSIS

  # via the bash wrapper (recommended)
  orepan2-s3 add My-Dist-1.0.tar.gz
  orepan2-s3 index

  # or directly via the modulino
  orepan2-s3-index create --upload

  # add and index a new distribution
  orepan2-s3-index inject My-App-1.0.0.tar.gz

  # upload artifacts listed in config file
  orepan2-s3-index upload-artifacts

=head1 DESCRIPTION

This class is used to add distributions to your own DarkPAN
repository housed on Amazon's S3 storage. It leverages L<OrePAN2> to
create and maintain your own DarkPAN repository. You can read more
about setting up a DarkPAN on Amazon using S3 + Cloudfront
L<here|https://github.com/rlauer6/OrePAN2-S3/blob/master/README.md>.

You can read more about creating a secure static website using Amazon
S3 L<here|https://blog.tbcdevelopmentgroup.com/2025-02-18-post.html>.

=head1 USAGE

 orepan2-s3 options command

Perl script for maintaining a DarkPAN mirror using S3 + CloudFront.

I<NOTE: C<orepan2-s3> is the bash script that calls this Perl class
that doubles as a modulino.  The documentation here refers to the
script (not the class)>.

=head2 Options

 -h, --help           Display this help message
 -b, --bucket-name    Overrides bucket in configuration
 -c, --config-file    Name of the configuration file (default: ~/.orepan2-s3.json)
 -o, --output         Name of the output file
 -p, --profile        Your AWS profile if not provided in configuration
 -n, --profile-name   Name of a profile inside the config file
 -t, --template       Name of a template that will be used as the index.html page
 -d, --distribution   Path to distribution tarball
 -u, --upload         Upload files after processing (for create-index, create-docs)
 -U, --url            Cloudfront URL

=head2 Commands

=over 5

=item * create - Create a new F<index.html> from the mirror's manifest file.

=item * delete - Delete a distribution from repo and reindex

=item * download - Download the mirror's manifest file (F<02packages.details.txt.gz>).

=item * inject - Uploads a tarball and adds to the DarkPAN index

=item * show - Print the manifest file to STDOUT or a file.

=item * dump-template - Outputs the default index.html template.

=item * create-docs - parse distribution looking for a README.md and/or pod

=item * invalidate-index - I<not currently implemented>

=item * upload - Upload the index.html file to the mirror's root.

=item * upload-artifacts - Uploads the files listed in the C<index: files:> section of the config file.

=back

=head2 Notes

=over 5

=item The preferred way of using this utility is through the bash wrapper.

I<The following commands are available only through the C<orepan2-s3>
bash wrapper, not the modulino directly:>

=over 5

=item * add {file} - inject a tarball into the repository and re-index

=item * delete {file} - remove a distribution and re-index

=item * invalidate - invalidate the CloudFront cache

=back

=back

=head2 Configuration File

The configuration file for C<orepan2-s3> is a JSON file that can
contain multiple profiles (or none). Each profile represents a DarkPAN
S3 repository. The format should look something like this:

  {
      "default" : "bedrock",
      "tbc" : {
          "author_path": "D/DU/DUMMY",
          "AWS": {
              "profile" : "prod",
              "region" : "us-east-1",
              "bucket" : "tbc-cpan-mirror",
              "prefix" : "orepan2"
          },
          "CloudFront" : {
              "DistributionId" : "E2ABCDEFGHIJK"
          }
      },
      "bedrock" : {
          "author_path": "D/DU/DUMMY",
          "index" : {
              "template" : "/path/to/template",
              "files": {
                 "src" : "dest"
              }
          },
          "AWS": {
              "profile" : "prod",
              "region" : "us-east-1",
              "bucket" : "cpan.openbedrock.net",
              "prefix" : "orepan2"
          },
          "CloudFront" : {
              "DistributionId" : "E2JKLMNOPQRXYZ",
              "InvalidationPaths" : [],
              "url" : "https://cpan.openbedrock.net/orepan2"
          }
      }
  }

Each profile can contain the keys described below. If you only have one
profile you don't need to place it in a 'default' section.

The value for the 'default' key can be the name of a profile or a hash
of the profile.

=over 5

=item author_path 

Overrides default C<D/DU/DUMMY>. For a personal DarkPAN you should
place all modules in one path.

=item index

This section allows you to create custom template for the DarkPAN home page.

=over 10

=item template

The name of a template file that will be parsed and uploaded as
F</index.html>. If you do not provide a template file a default
template is used. The default template is a L<Template::Toolkit> style
template. To see the default template use the C<dump-template> command
to the F<orepan2-s3-index> script.

 orepan2-s3-index dump-template

The templating process is provided with these variables:

=over 15

=item utils

A blessed reference to an object with one method (C<module_name>) that
returns a version of the module name suitable for use as unique CSS id.

=item repo

A hash of key value pairs where the key is the name of a DarkPAN
distribution and value is an array or arrays. Each array is of the
form:

 [0] => Perl module name
 [1] => Module version

=item localtime

The current time and date as a string.

=item pod_links

A hash where the keys are distribution names and the values are links
to the POD for a module.

=item readme_links

A hash where the keys are distribution names and the values are links
to a README for a module.

I<NOTE: Sometimes the README and the POD will contain the same information.>

=back

=item files

A hash of source/destination pairs that specify additional files you
want uploaded to your S3 bucket.

Example:

 "files": { 
    "/home/rlauer/git/some-project/foo.css" : "/css/foo.css",
    "/home/rlauer/git/some-project/foo.js" : "/javascript/foo.js"
 }

=back

=item AWS

=over 10

=item profile

The IAM profile that allows access to the S3 bucket and CloudFront.

=item region

AWS region. Default: us-east-1

=item bucket

S3 bucket name

=item prefix

The prefix where the CPAN distribution files will be stored. Default: orepan2.

=back

=item CloudFront

I<NOTE: Your profile must have the ability to invalidate the CloudFront cache!>

=over 10

=item DistributionId

CloudFront distribution id

=item InvalidationPaths

C<OrePAN2::S3> is designed to work with CloudFront + Amazon
S3. CloudFront is a CDN and will read content from your S3 bucket when
clients make HTTP requests. CloudFront will cache content to avoid
costly reads to the S3 bucket. If you change some of the static assets
(like the index page) you may want to invalidate the cache to see
your new assets. You could wait until the cache is updated (the
default time is 24 hours)...but why?  The script will automatically
invalidate the cache for you if you tell it what assets to invalidate
when you add a new distribution.

An array of additional paths to invalidate when adding new distributions.

I<Note: There is no additional charge for adding additional
paths. Each invalidation batch is considered as one billing unit by
AWS. However, keep in mind you get 1000 invalidation paths for free
each month. Thereafter each path costs $0.005 per path.>

=back

=item custom_sections

This section contains key/value pairs where the key is the name of a
variable that will be exposed to your template and the values
are a two element array that contains a regular expression and
possible regexp flags. The script will use the regexp to filter your
distributions and add them to a hash whose name is the key you
provided.

The purpose of this section is to allow you to possibly organize your
distributions under possible HTML headings.

Example:

 "custom_sections" : {
     "plugins" : ["^BLM\-(?!Startup)", "xsm"],
     "app_plugins" : ["^BLM\-Startup", "xsm"],
  }

...then in your template:

      <h1>Application Plugin Index</h1>
      
  [% FOREACH distribution = app_plugins.sort %]
        <h2>
         <span class="collapse-section-icon">&#9660;</span>
         [% distribution %]
         [% IF readme_links.$distribution %]
         <a title="README"  class='doc-link' href="[% readme_links.$distribution %]"><span class="material-symbols-outlined">docs</span></a>
         [% END %]
         [% IF pod_links.$distribution %]
         <a title="pod" class='doc-link' href="[% pod_links.$distribution %]"><span class="material-symbols-outlined">docs</span></a>
         [% END %]
        </h2>
  
        <ul class="collapsable" id="[% utils.module_name(distribution) %]">
  [% FOREACH module IN app_plugins.$distribution %]
          <li>[%  module.0 %]</li>
  [% END %]
        </ul>
  [% END %]
     <hr>

=back

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO

L<OrePAN2>, L<Amazon::S3::Lite>, L<DarkPAN::Utils>, L<CLI::Simple>, L<Template>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
