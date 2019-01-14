use Test::Most;
use File::Spec;
use File::Slurp;
use Cwd 'abs_path';
use File::Which 'which';
use File::Path qw/make_path/;
use File::Basename qw/dirname basename/;
use lib abs_path( File::Spec->catdir( dirname(__FILE__), File::Spec->updir, File::Spec->updir, 'lib' ) );

use Test::PostgreSQL;
use Test::MockModule;

use Treex::PML;
use Treex::PML::Factory;
use IO::Socket::IP;
use List::Util 'pairfirst';
use Scalar::Util 'blessed';
use List::MoreUtils 'zip';
use Getopt::Long;

use PMLTQ;
use PMLTQ::SQLEvaluator;
use PMLTQ::Command;

binmode STDOUT, ':encoding(UTF-8)';

my (%filter_treebanks, %filter_query);
GetOptions('treebank|t=s' => sub { shift; $filter_treebanks{ shift() } = 1 },
           'query|q=s' => sub { shift; $filter_query{ shift() } = 1 });

my $base_dir = abs_path( File::Spec->catdir( dirname(__FILE__), File::Spec->updir ) );
my $treebanks_dir = File::Spec->catdir( $base_dir, 'treebanks' );

my ( $pg_restore, $pg_create_db, $pgsql, $pg_port, @treebanks, %treebanks, %config_cache );

my $results_base_dir = File::Spec->catdir( $base_dir, 'results' );
my $queries_base_dir = File::Spec->catdir( $base_dir, 'queries' );

sub generate_port {
  IO::Socket::IP->new( Listen => 5, LocalAddr => '127.0.0.1' )->sockport;
}

sub random_string {
  my @chars = ( 'A' .. 'Z', 'a' .. 'z' );
  my $string;
  $string .= $chars[ rand @chars ] for 1 .. 8;

  return $string;
}

$pg_port = $ENV{PG_PORT} || generate_port();

sub pg_port {$pg_port}

my %db = (
  port     => pg_port(),
  user     => 'postgres',
  password => '',
);

my $CommandsMock = Test::MockModule->new('PMLTQ::Commands');
$CommandsMock->mock(
  _load_config => sub {
    my $filename = abs_path(shift);
    return $config_cache{$filename} if exists $config_cache{$filename};
    my $config = $CommandsMock->original('_load_config')->($filename);

    # tamper db connection
    while ( my ( $key, $value ) = each %db ) {
      $config->{db}->{$key} = $value;
    }

    $config->{sys_db} = 'postgres';
    $config->{db}->{name} = random_string();    # Randomize database name to allow running concurrent tests
    return $config_cache{$filename} = $config;
  } );

sub treebanks {
  return @treebanks if (@treebanks);

  %treebanks = map {
    $_ => {
      name   => $_,
      dir    => File::Spec->catdir( $treebanks_dir, $_ ),
      config => PMLTQ::Commands::_load_config( File::Spec->catdir( $treebanks_dir, $_, 'pmltq.yml' ) ),
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

sub start_postgres {
  $pg_restore = $ENV{PG_RESTORE} || which('pg_restore');
  plan skip_all => 'Cannot find pg_restore in your path and is not provided in PG_RESTORE variable either'
    unless $pg_restore;
  $pg_create_db = $ENV{PG_CREATE_DB} || which('createdb');
  plan skip_all => 'Cannot find createdb in your path and is not provided in PG_CREATE_DB variable either'
    unless $pg_create_db;

  return if $ENV{TRAVIS};    # We use Travis Postgresql addon

  $pgsql = Test::PostgreSQL->new(
    port       => $pg_port,
    auto_start => 0,          # use dir for subsequent runs to simply skip initialization
  ) or plan skip_all => $Test::PostgreSQL::errstr;

  $pgsql->setup();
  $pgsql->start;

  $pg_port = $pgsql->port;
}

sub create_db {
  my $dbname = shift;

  my @createdb_cmd = ( $pg_create_db, '-h', 'localhost', '-p', $pg_port, '-U', 'postgres', $dbname );

  system( join( ' ', @createdb_cmd ) ) == 0 or die "Creating $dbname database failed: $?";
}

sub load_database {
  my ( $config, $dump_file ) = @_;

  my $dbname = $config->{db}->{name};

  create_db($dbname);

  # run with clean environment
  my @restore_cmd = (
    $pg_restore, '-d',       $dbname,      '-h', 'localhost', '-p', $pg_port, '-U',
    'postgres',  '--no-acl', '--no-owner', '-w', $dump_file
  );

  #say STDERR join(' ', @restore_cmd);
  system( join( ' ', @restore_cmd ) ) == 0 or die "Restoring $dbname database failed: $?";
}

sub init_database {
  for my $tb ( treebanks() ) {
    load_database( $tb->{config}, $tb->{dump} );
  }
}

sub init_sql_evaluator {
  my $name = shift;
  my $db   = $treebanks{$name}->{config}->{db};
  return PMLTQ::SQLEvaluator->new(
    undef,
    { connect => {
        database       => $db->{name},
        host           => $db->{host},
        port           => $db->{port},
        username       => $db->{user},
        layout_version => 2,
        password       => $db->{password},
      } } );
}

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

sub result_filename {
  my ( $treebank_name, $name ) = @_;

  return File::Spec->catfile( $results_base_dir, $treebank_name, "$name.res" );
}

# will save the result in case it doesn't exists
sub save_result {
  my ( $result_file, $result ) = @_;

  unless ( -d dirname($result_file) ) {
    make_path( dirname($result_file) );
  }
  diag("Result file $result_file doesn't exists, generating one right now...");
  my $res_string = join "\n", map { join "\t", @$_ } @$result;
  write_file( $result_file, { binmode => ':utf8' }, $res_string ) || die "Cannot write result file '$result_file'";
}

sub load_results {
  my $result_file = shift;

  my $res_string = read_file( $result_file, binmode => ':utf8' );
  return [ map { [ split /\t/, $_ ] } grep {$_} split /\n/, $res_string ];
}

# load queries from particular treebank
sub load_queries {
  my $treebank_name = shift;
  my $query_dir = File::Spec->catdir( $queries_base_dir, $treebank_name );

  return () unless -d $query_dir;
  my @queries = sort { $a->{name} cmp $b->{name} }
    map { { name => basename( $_, '.tq' ), text => scalar( read_file( $_, binmode => ':utf8' ) ) } }
    read_dir( $query_dir, prefix => 1 );
  @queries = grep { $filter_query{$_->{name}} } @queries if %filter_query;
  @queries
}

my %file_cache;

# open a data file and related files on lower layers
sub open_file {
  my $filename = shift;
  return $file_cache{$filename} if exists $file_cache{$filename};
  my $fsfile = Treex::PML::Factory->createDocumentFromFile($filename);
  if ($Treex::PML::FSError) {
    die "Error loading file $filename: $Treex::PML::FSError ($!)\n";
  }
  $file_cache{$filename} = $fsfile;
  my $requires = $fsfile->metaData('fs-require');
  if ($requires) {
    for my $req (@$requires) {
      my $req_filename = $req->[1]->abs( $fsfile->URL );
      my $secondary    = $fsfile->appData('ref');
      unless ($secondary) {
        $secondary = {};
        $fsfile->changeAppData( 'ref', $secondary );
      }
      my $sf = open_file($req_filename);
      $secondary->{ $req->[0] } = $sf;
    }
  }
  return $fsfile;
}

# iterate over several files (or maybe several scattered trees)
sub next_file {
  my ( $evaluator, $file ) = @_;
  return unless $file;
  my $fsfile = open_file($file);

  # reusing the evaluator for next file
  my $iter = $evaluator->get_first_iterator;
  $iter->set_file($fsfile);
  $evaluator->reset();    # prepare for next file
  return $fsfile;
}

sub sort_results {
  my ( $v1, $v2 ) = pairfirst { $a cmp $b } zip( @$a, @$b );
  return ( $v1 && $v2 ) ? $v1 cmp $v2 : 0;
}

sub sql_test_query {
  my ( $name, $treebank_name, $evaluator, $query ) = @_;

  my ( $result, $query_tree );
  lives_ok {
    $query_tree = $evaluator->prepare_query( $query, { node_IDs => 1, debug_sql => 1 } );
    $result = $evaluator->run( {} );
  }
  "evaluation of ($name) on $treebank_name";

  if ( defined $result ) {

    if ( !$result ) {
      fail("Result match for ($name) on $treebank_name is empty and that shouldn't happen.");
    }
    my $res = [
      blessed( $query_tree->{'output-filters'} )
      ? sort sort_results map { [ sort @$_ ] } @$result
      : sort sort_results map { [ sort $evaluator->idx_to_pos( $_, 1 ) ] } @$result
    ];
    my $result_file = result_filename( $treebank_name, $name );
    save_result( $result_file, $res ) unless -f $result_file;

    my $expected = load_results($result_file);
    unified_diff;
    eq_or_diff_data( $res, $expected, "result match for ($name) on $treebank_name" );
  }
  else {
    diag <<"MSG";
Evaluation of query has failed:
---
$query
---
Result: $@
MSG
  }
}

sub test_queries_for {
  my $treebank_name = shift;

  my $evaluator = init_sql_evaluator($treebank_name);
  lives_ok { $evaluator->connect() } 'Connection to database successful';
  next unless $evaluator->{dbi};

  for my $query ( load_queries($treebank_name) ) {
    my $name = $query->{name};
    my @args = ( $treebank_name, $evaluator, $query->{text} );

    if ( $name =~ s/^_// ) {
    TODO: {
        local $TODO = 'Failing query...';
        subtest "$treebank_name:$name" => sub {
          sql_test_query( $name, @args );
          fail('Fail');
        };
      }
    }
    else {
      subtest "$treebank_name:$name" => sub {
        sql_test_query( $name, @args );
      };
    }
  }

  undef $evaluator;    # destroy evaluator
}

1;
