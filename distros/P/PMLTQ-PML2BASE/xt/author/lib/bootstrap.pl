use Test::Most;
use File::Spec;
use File::Slurp;
use Cwd 'abs_path';
use File::Basename qw/dirname/;
use lib abs_path( File::Spec->catdir( dirname(__FILE__), File::Spec->updir, File::Spec->updir, 'lib' ) );

use Treex::PML;
use Treex::PML::Factory;
use Getopt::Long;

use PMLTQ;
use YAML::Tiny;

binmode STDOUT, ':encoding(UTF-8)';

my (%filter_treebanks, %filter_query);
GetOptions('treebank|t=s' => sub { shift; $filter_treebanks{ shift() } = 1 });

my $base_dir = abs_path( File::Spec->catdir( dirname(__FILE__), File::Spec->updir ) );
my $treebanks_dir = File::Spec->catdir( $base_dir, 'treebanks' );

my ( @treebanks, %treebanks, %config_cache );


sub load_config {
    my $filename = abs_path(shift);
    return $config_cache{$filename} if exists $config_cache{$filename};
    my $config = YAML::Tiny->read($filename)->[0];

    return $config_cache{$filename} = $config;
}


sub treebanks {
  return @treebanks if (@treebanks);

  %treebanks = map {
    $_ => {
      name   => $_,
      dir    => File::Spec->catdir( $treebanks_dir, $_ ),
      config => load_config( File::Spec->catdir( $treebanks_dir, $_, 'pmltq.yml' ) ),
      dump   => File::Spec->catdir( $treebanks_dir, $_, 'database.dump' ),
      }
  } read_dir $treebanks_dir;

  @treebanks = values %treebanks;
  @treebanks = grep { $filter_treebanks{$_->{name}} } @treebanks if %filter_treebanks;
  @treebanks
}

my @resources = (
  File::Spec->catfile( PMLTQ->shared_dir, 'resources' ),    # resources for PML-TQ
  map { File::Spec->catdir( $_->{dir}, 'resources' ) } treebanks()    # Load required resources for all tested treebanks
);
Treex::PML::AddResourcePath(@resources);
Treex::PML::UseBackends(qw(Storable PMLBackend PMLTransformBackend));


sub treebank_files {
  my $treebank_name = shift;

  read_dir( File::Spec->catdir( $treebanks_dir, $treebank_name, 'data' ), prefix => 1 );
}

sub treebank_schemas {
  my $treebank_name = shift;

  return
    grep { defined $_->get_root_name }
    map { Treex::PML::Factory->createPMLSchema( { filename => $_ } ) }
    read_dir( File::Spec->catdir( $treebanks_dir, $treebank_name, 'resources' ), prefix => 1 );
}


1;
