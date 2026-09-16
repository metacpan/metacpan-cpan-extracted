package OrePAN2::S3;

use strict;
use warnings;

use Amazon::Credentials;
use Amazon::S3::Lite;
use Carp;
use CLI::Simple::Utils qw(choose);
use CLI::Simple::Constants qw(:booleans);
use Cwd qw(abs_path);
use Data::Dumper;
use English qw(-no_match_vars);
use Encode qw(encode_utf8);
use File::Basename qw(basename dirname);
use File::ShareDir qw(dist_dir);
use File::Copy;
use File::Temp qw(tempfile tempdir);
use JSON;
use List::Util qw(pairs);
use Scalar::Util qw(openhandle reftype);

use Readonly;

Readonly::Scalar our $PACKAGES_DETAILS_INDEX => '02packages.details.txt.gz';
Readonly::Scalar our $DEFAULT_CONFIG         => sprintf '%s/%s', $ENV{HOME} // q{}, '/.orepan2-s3.json';
Readonly::Scalar our $METACPAN_URL           => 'https://metacpan.org/pod';
Readonly::Scalar our $AUTHOR_PATH            => 'D/DU/DUMMY';

use Role::Tiny::With;

with 'OrePAN2::S3::Role::Inject';
with 'OrePAN2::S3::Role::Delete';
with 'OrePAN2::S3::Role::Upload';
with 'OrePAN2::S3::Role::UploadArtifacts';

use parent qw(CLI::Simple);

our $VERSION   = '2.1.1';
our $GIT_SHA   = '7f6970e14718af2b93d4ee2b2e6487c1c879944d';
our $GIT_DIRTY = '7f6970e14718af2b93d4ee2b2e6487c1c879944d';

our %DOC_INDEX;

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

  return $self->get_config
    if $self->get_config;

  my $file = $self->get_config_file;

  croak "ERROR: no config file specified\n"
    if !$file;

  $file = abs_path($file);

  die "$file not found\n"
    if !-e $file;

  $profile_name //= $self->get_profile_name // 'default';
  $self->get_logger->debug( sprintf 'using profile: "%s" from: "%s"', $profile_name, $file );

  $self->set_config_file($file);

  my $config = eval { return JSON->new->decode( scalar slurp_file($file) ); };

  croak "ERROR: could not read config file ($file)\n$EVAL_ERROR"
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
sub has_packages_version_index {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  return $config->{packages_version_index};
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
sub cmd_download_version_index {
########################################################################
  my ($self) = @_;

  my $packages_index = $self->has_packages_version_index;

  die "ERROR: no 'packages_version_index' defined in configuration\n"
    if !$packages_index;

  require DarkPAN::Indexer;

  my $indexer = DarkPAN::Indexer->new( config => $self->get_config );

  my $database = $indexer->get_storage->retrieve_index($packages_index);

  die sprintf "ERROR: could not download %s\n%s", $packages_index, $EVAL_ERROR
    if $EVAL_ERROR;

  my $packages_db = basename( $packages_index, '.gz' );
  move $database, $packages_db;

  if ( -e $packages_db ) {
    print {*STDOUT} "$packages_db\n";
    return $SUCCESS;
  }

  die sprintf "ERROR: could not move %s => %s\n", $database, $packages_db;
}

########################################################################
sub fetch_orepan_index {
########################################################################
  my ($self) = @_;

  my ( $fh, $filename ) = tempfile(
    'XXXXXX',
    SUFFIX => '.gz',
    UNLINK => $FALSE,
    DIR    => '/tmp',
  );

  my $config = $self->get_config;

  my $key = sprintf '%s/modules/%s', $config->{AWS}{prefix}, $PACKAGES_DETAILS_INDEX;
  $self->get_s3->get_object( $self->get_bucket_name, $key, filename => $filename );

  return $filename;
}

########################################################################
sub cmd_invalidate_index {
########################################################################
  my ($self) = @_;

  my (@paths) = $self->get_args;

  my $rsp = eval { $self->_invalidate_index(@paths); };

  if ( !$rsp || $EVAL_ERROR ) {
    print {*STDERR} $EVAL_ERROR;
    return $FAILURE;
  }

  print {*STDOUT} JSON->new->pretty->encode($rsp);

  return $SUCCESS;
}

########################################################################
sub _invalidate_index {
########################################################################
  my ( $self, @invalidation_paths ) = @_;

  my $config = $self->get_config;

  my $distribution_id = $config->{CloudFront}{DistributionId};

  croak "ERROR: no CloudFront configuration found\n"
    if !$distribution_id;

  eval { require Amazon::API::CloudFront; };

  croak "ERROR: install Amazon::API::CloudFront\n"
    if $EVAL_ERROR;

  push @invalidation_paths, @{ $config->{CloudFront}{InvalidationPaths} // [] };
  push @invalidation_paths, '/index.html', '/docs/*', '/orepan2/modules/02packages.details.txt.gz';

  my $packages_index = $self->has_packages_version_index;

  if ($packages_index) {
    push @invalidation_paths, "/$packages_index";
  }

  my $invalidation_batch = $self->create_invalidation_batch( $distribution_id, \@invalidation_paths );

  local $ENV{AWS_PROFILE} = $self->get_profile // $config->{AWS}{profile};

  my $cf = Amazon::API::CloudFront->new;

  return $cf->CreateInvalidation($invalidation_batch);
}

########################################################################
sub create_invalidation_batch {
########################################################################
  my ( $self, $distribution_id, $items, $reference ) = @_;

  if ( !$reference ) {
    require Data::UUID;
    $reference = Data::UUID->new->create_str;
  }

  croak "ERROR: items missing\n"
    if !$items;

  croak "ERROR: items must be an array\n"
    if !ref $items || reftype($items) ne 'ARRAY';

  croak "ERROR: no items to invalidate\n"
    if !@{$items};

  my $invalidation_batch = {
    DistributionId    => $distribution_id,
    InvalidationBatch => {
      CallerReference => $reference,
      Paths           => {
        Items    => $items,
        Quantity => scalar @{$items},
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

  $self->get_logger->info( sprintf 'adding %s to document index', $key );

  $DOC_INDEX{$key} = q{/} . $key;

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
# COMMANDS
########################################################################

########################################################################
sub cmd_list_packages {
########################################################################
  my ($self) = @_;

  my $s3 = $self->get_s3;

  my $config = $self->get_config;

  my $prefix = $config->{AWS}{prefix};
  my $path   = sprintf '%s/authors/id/%s', $prefix, $self->get_author_path;

  my @objects = $s3->list_all_objects_v2( $self->get_bucket_name, prefix => $path );

  my %packages;

  foreach my $o (@objects) {
    my $key = $o->{key};

    if ( my ($package_prefix) = $key =~ /^(.*?)[-]([\d.]+)[.]tar[.]gz$/xsm ) {
      $packages{$1} //= [];
      push @{ $packages{$1} }, $2;
    }
  }

  return $SUCCESS
    if !keys %packages;

  my $has_ascii_table = eval {
    require Text::ASCIITable; ## scandeps: suggests
    1;
  };

  if ( !$has_ascii_table || $self->get_format eq 'json' ) {
    print {*STDOUT} JSON->new->pretty->encode( \%packages );
    return $SUCCESS;
  }

  my $has_pager = $self->_has_pager;

  my $t = Text::ASCIITable->new( { headingText => sprintf 'DarkPAN: https://%s/%s', $self->get_bucket_name, $prefix } );
  $t->setCols( 'Packages', 'Versions' );

  foreach my $p ( sort keys %packages ) {
    $t->addRow( basename($p), join "\n", sort @{ $packages{$p} } );
  }

  print {*STDOUT} $t;

  return $SUCCESS;
}

########################################################################
sub _has_pager {
########################################################################
  my ($self) = @_;

  return eval {
    return
      if !$self->get_cli_pager;

    require IO::Interactive;

    return
      if !IO::Interactive::is_interactive

      require IO::Pager;

    IO::Pager->new(*STDOUT);

    1;
  };
}

########################################################################
sub cmd_upload_site_index {
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
      $distribution = sprintf '%s/%s', $self->get_author_path, $distribution;
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

  my $file   = $dpu->extract_module( $distribution, $module_name );
  my $readme = $dpu->extract_file( sprintf '%s-%s/README.md', $key_prefix, $version );

  my $changelog = $dpu->extract_file( sprintf '%s-%s/Changes', $key_prefix, $version );
  $changelog //= $dpu->extract_file( sprintf '%s-%s/CHANGES',   $key_prefix, $version );
  $changelog //= $dpu->extract_file( sprintf '%s-%s/ChangeLog', $key_prefix, $version );

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

    if ($readme) {
      $self->upload_html(
        name     => 'README.html',
        markdown => $readme,
        prefix   => $key_prefix,
        wrap     => $TRUE,
      );
    }
  }

  my $tar = Archive::Tar->new;

  $tar->add_data( 'README.md',      $readme    // q{} );
  $tar->add_data( "$key_prefix.pm", $file      // q{} );
  $tar->add_data( 'ChangeLog',      $changelog // q{} );

  $tar->write( 'docs.tar.gz', $TRUE );

  return $SUCCESS;
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

  $DOC_INDEX{ sprintf 'docs/%s/%s', $prefix, $name };

}

########################################################################
sub cmd_create_site_index {
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
    $self->get_logger->debug( 'distribution: ' . $distribution );

    my ($distribution_name) = DarkPAN::Utils::parse_distribution_path($distribution);

    if ( !$distribution_name ) {
      $self->get_logger->warn("WARN: could not get distribution name from $distribution");
      next;
    }

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

  return $self->send_output($output)
    if !$self->get_upload;

  $self->_upload_html( \$output, 'index.html' );

  $self->get_logger->debug($output);

  if ( $self->get_config->{CloudFront}{DistributionId} && $self->get_invalidate_index ) {
    $self->_invalidate_index;
  }

  return $SUCCESS;
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

  return $SUCCESS;
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

  die "ERROR: Could not download $PACKAGES_DETAILS_INDEX\n$EVAL_ERROR"
    if !$filename || !-s "$filename";

  print {*STDERR} "copying $filename => $PACKAGES_DETAILS_INDEX\n";

  copy $filename, $PACKAGES_DETAILS_INDEX
    or die "ERROR: could not copy $filename -> $PACKAGES_DETAILS_INDEX\n";

  unlink $filename;

  print {*STDOUT} $PACKAGES_DETAILS_INDEX . "\n";

  return;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my $config = $self->fetch_config;

  my $profile = $self->get_profile // $config->{AWS}{profile};

  my $dist = __PACKAGE__;
  $dist =~ s/::/-/xsmg;
  my $dist_dir = $self->set_dist_dir( dist_dir($dist) );

  my $credentials = Amazon::Credentials->new( profile => $profile );
  $self->set_credentials($credentials);

  my $bucket_name = $self->get_bucket_name // $config->{AWS}->{bucket};

  $self->set_bucket_name($bucket_name);

  $self->init_s3;

  $self->_init_doc_index;

  $self->set_author_path( $config->{author_path} // $AUTHOR_PATH );

  $self->fetch_template;

  return;
}

########################################################################
sub _init_doc_index {
########################################################################
  my ($self) = @_;

  my $s3 = $self->get_s3;

  my $bucket_name = $self->get_bucket_name;

  my (@object_list) = $s3->list_all_objects_v2( $bucket_name, prefix => 'docs/' );

  foreach (@object_list) {
    $DOC_INDEX{ $_->{key} } = q{/} . $_->{key};
  }

  return;
}

########################################################################
sub fetch_template {
########################################################################
  my ($self) = @_;

  my $template = $self->get_template;

  my $index = $self->get_config->{index} // {};

  my $config_dir = dirname( $self->get_config_file );

  # see if the index is set in the config file...
  if ( !$template && $index->{template} ) {
    $template = $index->{template};
  }
  else {
    $template = 'default';
  }

  $self->get_logger->debug( sprintf 'using index template: "%s"', $template ne 'default' ? $template : '__DATA__' );
  my $bucket_name = $self->get_bucket_name;

  if ( $template =~ m{\As3://(.*)$}xsm ) {
    my $key    = $1;
    my $object = eval { $self->get_s3->get_object( $bucket_name, $key ); };

    croak sprintf "ERROR: could not retrieve %s from %s\n%s", $key, $bucket_name, $OS_ERROR
      if !$object || $EVAL_ERROR;

    $self->set_template( $object->{content} );

    $self->get_logger->debug( sprintf 'successfully loaded index template: "%s" from "%s"', $key, $bucket_name );
  }
  else {
    $template = $template =~ /^\//xsm ? $template : sprintf '%s/%s', $config_dir, $template;
    my $index_template = $template eq 'default' ? slurp_file(*DATA) : slurp_file($template);
    $index_template =~ s/\n\n=pod.*$/\n/xsm;

    $self->set_template($index_template);
  }

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
        bucket-name|b=s
        cli-pager!
        config-file|c=s
        delete-all
        dirty-check!
        distribution|d=s
        dryrun
        force|f
        format=s
        help|h
        invalidate-index!
        output|o=s
        profile-name|n=s
        profile|p=s
        save-index
        template|t=s
        url|U=s
        update-site-index!
        upload
      )
    ],
    default_options => {
      config_file       => $DEFAULT_CONFIG,
      cli_pager         => $TRUE,
      profile_name      => 'default',
      profile           => $ENV{AWS_PROFILE},
      dirty_check       => $TRUE,
      invalidate_index  => $TRUE,
      update_site_index => $TRUE,
      format            => 'json',
    },
    extra_options => [qw(config credentials template author_path s3 dist_dir)],
    commands      => {
      'create-docs'            => \&cmd_create_docs,
      'create-site-index'      => \&cmd_create_site_index,
      'delete'                 => \&cmd_delete,
      'download-index'         => \&cmd_download_orepan_index,
      'download-version-index' => \&cmd_download_version_index,
      'dump-template'          => sub {
        print {*STDOUT} shift->get_template;
        return 0;
      },
      'inject'           => \&cmd_inject,
      'invalidate-index' => \&cmd_invalidate_index,
      'list-packages'    => \&cmd_list_packages,
      'show'             => \&cmd_show_orepan_index,
      'upload'           => \&cmd_upload,
      'upload-index'     => \&cmd_upload_site_index,
      'upload-artifacts' => \&cmd_upload_artifacts,
    },
    alias         => { commands => { add => 'upload' } },
    abbreviations => $TRUE,
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

=encoding utf8

=head1 NAME

OrePAN2::S3 - Manage a DarkPAN CPAN mirror on Amazon S3

=head1 SYNOPSIS

  # Upload a distribution to DarkPAN without indexing
  orepan2-s3 upload My-Dist-1.0.tar.gz
  # or using the alias
  orepan2-s3 add My-Dist-1.0.tar.gz

  # Upload AND index a new distribution
  orepan2-s3 inject My-App-1.0.0.tar.gz

  # Regenerate the DarkPAN home page and upload it
  orepan2-s3 --upload create-site-index

  # ...or upload an already-generated index.html on its own
  orepan2-s3 upload-index

  # Upload custom artifacts specified in config
  orepan2-s3 upload-artifacts

=head1 DESCRIPTION

C<OrePAN2::S3> provides a command-line interface for creating and
maintaining an S3-backed DarkPAN repository, including distribution
publishing, incremental package-index maintenance, documentation and
site generation, deletion, and optional CloudFront integration.

=head1 FEATURES

=over 4

=item *

Upload and inject Perl distributions into an S3-backed DarkPAN.

=item *

Maintain C<02packages.details.txt.gz> incrementally when distributions
are added or removed.

=item *

Delete individual distribution versions, or multiple matching versions,
without rebuilding the entire repository index.

=item *

Generate and publish a customizable HTML index for the repository.

=item *

Extract POD, README, and changelog documentation from distributions and
publish generated documentation to S3.

=item *

Publish additional static assets used by the DarkPAN site.

=item *

Optionally use CloudFront and automatically invalidate cached repository
content after updates.

=item *

Support multiple repository profiles, AWS profiles, configurable author
paths, and custom index templates.

=item *

Inspect and download the current package index and list distributions
stored in the repository.

=item *

Protect uploads from dirty builds, with explicit override and dry-run
support for administrative operations.

=back

=head1 USAGE

  orepan2-s3 [options] command [args]

=head2 Options

Both commands and options may be abbreviated to any unique prefix.
Boolean options marked C<[negatable]> accept a C<--no-> form (for
example C<--no-invalidate-index>).

=over 4

=item -h, --help

Display this help message.

=item -b, --bucket-name I<name>

S3 bucket name. Overrides the C<AWS.bucket> config value.

=item -c, --config-file I<path>

Path to the configuration file. Default: F<~/.orepan2-s3.json>.

=item -d, --distribution I<path>

Path to the target distribution tarball when adding a new distribution.

Tarball name or tarball prefix when deleting distributions. Examples:

 orepan2-s3 --distribution workdir/Foo-Bar-1.2.3.tar.gz add

 orepan2-s3 --distribution Foo-Bar-1.2.3.tar.gz delete

 orepan2-s3 --distribution Foo-Bar delete

=item -n, --profile-name I<name>

Configuration profile section name inside the config file. Default: C<default>.

=item -p, --profile I<name>

AWS/IAM profile name. Default: C<$AWS_PROFILE>.

=item -t, --template I<path>

Path to a custom L<Template::Toolkit> template for F<index.html>.

=item -o, --output I<path>

Output path for commands that write a file locally.

=item -U, --url I<url>

Base URL of the DarkPAN, used by C<create-docs> when retrieving a
distribution remotely. May also be set as the C<url> key in the
configuration profile.

=item --format I<format>

Output format for informational commands (e.g. C<list-packages>).
Default: C<json>.

=item --dirty-check [negatable]

Check the distribution's C<$GIT_DIRTY> global before uploading and abort if
it is dirty. Enabled by default; use C<--no-dirty-check> (or C<--force>) to
override.

=item --force

Force upload of an uncommitted (dirty) distribution.

=item --invalidate-index [negatable]

Invalidate CloudFront paths after creating the site index. Enabled by
default; use C<--no-invalidate-index> to skip invalidation.

=item --update-site-index [negatable]

Update the site index after commands that modify the package index. Enabled by default.

=item --save-index

Save the F<02packages.details.txt.gz> file to the current directory.

=item --upload

Upload the index after creating it.

=item --delete-all

When a C<delete> matches multiple objects, remove all of them instead of
aborting.

=item --dryrun

Report what would be done without making any changes.

=item --cli-pager [negatable]

Page long output. Enabled by default; use C<--no-cli-pager> to disable.

=back

=head2 Commands

=over 4

=item * B<upload> (alias: B<add>)

Uploads the specified distribution tarball to S3 under the configured
author path (C<D/DU/DUMMY> by default).

  orepan2-s3 upload My-Package-1.0.0.tar.gz

If you want to upload B<and> index a distribution in a single step, use the
C<inject> command instead.

The C<upload> command will check the main module to see if there is a
C<$GIT_DIRTY> global variable defined that indicates whether the
distribution has been committed. If the distribution is uncommitted
the upload function will abort with an error message by default. Use
C<--no-dirty-check> or C<--force> to upload a dirty distribution.

I<Note:>

When using the C<CPAN::Maker::Bootstrapper> framework the
distribution status is automatically set in the C<Makefile> so your
module can include it as a global.

 GIT_DIRTY := $(shell $(GIT) describe --always --dirty --abbrev=40 2>/dev/null || echo 'unknown')

...then in your module:

 our $GIT_DIRTY = '51eb002566044d5af4c65ceff35848d3e462fbc8-dirty';

=item * B<inject>

Uploads the distribution tarball to S3 B<and> updates the package details index (C<02packages.details.txt.gz>).

  orepan2-s3 inject My-Package-1.0.0.tar.gz

=item * B<upload-index>

Uploads an HTML file as the DarkPAN's root index.html; defaults to the
local index.html.

=item * B<upload-artifacts>

Uploads additional non-package artifacts defined in the C<index: files:> section of your configuration file.

=item * B<delete>

 orepan2-s3 delete My-Package-1.0.0.tar.gz
 orepan2-s3 delete My-Package
 orepan2-s3 -d My-Package-1.0.0.tar.gz delete

Removes one or more distributions from the DarkPAN and updates the
indexes accordingly. The distribution may be given as a positional
argument or with C<--distribution>. In a single run this command:

=over 4

=item * deletes the distribution tarball(s) from C<< <prefix>/authors/id/<author_path>/ >>;

=item * deletes the associated documentation tree under C<docs/> (the C<create-docs> output), if present;

=item * regenerates C<02packages.details.txt.gz>, removing the packages that belonged to the deleted distribution(s), and uploads it;

=item * unless C<--no-update-site-index> is given, regenerates and uploads the HTML site index (F<index.html>); and

=item * unless C<--no-invalidate-index> is given, invalidates the relevant CloudFront paths.

=item * deletes records from a packages version index if one is defined in your configuraton

=back

If the argument ends in C<.tar.gz> it is treated as an exact
distribution filename. If the referenced object no longer exists in the
bucket a warning is issued and only the documentation is removed.

If the argument does B<not> end in C<.tar.gz> it is treated as a name
prefix and may match several objects (for example every version of a
distribution). When more than one object matches you must pass
C<--delete-all>, and you will be prompted to confirm before anything is
removed:

 orepan2-s3 delete --delete-all My-Package

Use C<--dryrun> to see exactly which objects, docs, and index entries
would be removed without modifying the bucket.

I<Note:> the package index, site index, and CloudFront invalidation are
all updated automatically by default. You do not normally need to run
C<create-site-index> after a delete; pass C<--no-update-site-index>
and/or C<--no-invalidate-index> if you want to suppress those steps.

=item * B<create-docs>

Extracts documentation (POD, C<README.md>, and changelog content) from a
distribution and creates a local C<docs.tar.gz> archive. When C<--upload>
is specified, the POD and README are converted to HTML and uploaded to S3.

=item * B<create-site-index>

Generates the DarkPAN site's F<index.html>. By default the generated HTML
is written to C<STDOUT> (or C<--output>). When C<--upload> is specified,
the index is uploaded to the S3 bucket. If CloudFront is configured and
invalidation is enabled, the configured paths are invalidated after upload.

=item * B<invalidate-index>

Invalidates CloudFront cache paths associated with package indices and
documentation.

=item * B<download-index>

Downloads the F<02packages.details.txt.gz> file.

=item * B<download-version-index>

Downloads the packages version index to the current directory if one
is defined in the configuration. This index is typically SQLite database that
is used with the L<DarkPAN::Resolver::SQLite> resolver.

=item * B<dump-template>

Prints the default L<Template::Toolkit> index template to C<STDOUT>. Use this
as a starting point for a custom template referenced by C<index: template:> in
your configuration file.

  orepan2-s3 dump-template > my-index.tt

=item * B<list-packages>

Lists the distributions currently stored in the DarkPAN, grouped by
distribution name and version.

=item * B<show>

Displays the contents of the current package index
(F<02packages.details.txt.gz>).

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
          "url" : "https://cpan.openbedrock.net/orepan2",
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
              "InvalidationPaths" : []
         }
      }
  }

Each profile can contain the keys described below. If you only have one
profile you don't need to place it in a 'default' section.

The value for the 'default' key can be the name of a profile or a hash
of the profile.

=over 5

=item author_path 

Overrides the default C<D/DU/DUMMY> author path. For a personal DarkPAN you should
all ldistributions in one path.

=item index

This section allows you to specify a custom template for the DarkPAN home page.

=over 10

=item template

The name of a template file that will be parsed and uploaded as
F</index.html>. If you do not provide a template file a default
template is used. The default template is a L<Template::Toolkit> style
template. To see the default template use the C<dump-template> command:

 orepan2-s3 dump-template

The templating process is provided with these variables:

=over 15

=item utils

A blessed reference to an object with one method (C<module_name>) that
returns a version of the module name suitable for use as unique CSS id.

=item repo

A hash where each key is a DarkPAN distribution name and each value is
an array of two-element arrays. Each inner array contains:

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

C<OrePAN2::S3> can optionally use CloudFront in front of the S3-backed
DarkPAN. Because CloudFront caches objects, changes made in S3 may not
be immediately visible to clients, depending on the caching behavior
of your CloudFront distribution.

When repository content changes, C<OrePAN2::S3> can automatically
invalidate the configured CloudFront paths so clients receive the
updated content.

C<InvalidationPaths> is an array of additional CloudFront paths to
include whenever an invalidation is performed.

I<Note: CloudFront invalidation pricing is controlled by AWS and may
change. See the current AWS CloudFront pricing documentation for
details.>

=back

=item custom_sections

This section contains key/value pairs where the key is the name of a
variable that will be exposed to your template and the values
are a two-element array that contains a regular expression and
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

=head1 ROLES CONSUMED

=over 4

=item * L<OrePAN2::S3::Role::Inject>

=item * L<OrePAN2::S3::Role::Delete>

=item * L<OrePAN2::S3::Role::Upload>

=item * L<OrePAN2::S3::Role::UploadArtifacts>

=back

=head1 VERSION

This documentation refers to version 2.1.1.

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO

L<OrePAN2>, L<Amazon::S3::Lite>, L<DarkPAN::Utils>, L<CLI::Simple>, L<Template>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
