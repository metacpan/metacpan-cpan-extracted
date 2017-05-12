use Test::Most;
use File::Spec;
use File::Slurp;
use File::Basename qw/dirname basename/;
use lib dirname(__FILE__);
use lib File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), File::Spec->updir, File::Spec->updir, 'lib' ) );

use Capture::Tiny ':all';
use Test::MockModule;

use PMLTQ::Command;
use PMLTQ::Commands;

use DBI;

require 'bootstrap.pl';

sub database_connect {
  my $config = shift;
  my $dbh
    = DBI->connect(
    'DBI:Pg:dbname=' . $config->{name} . ';host=' . $config->{host} . ';port=' . $config->{port},
    $config->{user}, $config->{password}, { RaiseError => 1, PrintError => 0 } );
  return $dbh;
}

sub convert {
  my ( $config, $dump_dir ) = @_;

  lives_ok { PMLTQ::Commands->run( 'convert', "--output_dir=$dump_dir" ) } 'conversion ok';

  my %files = map { $_ => 1 } read_dir $dump_dir;
  for my $layer ( @{ $config->{layers} } ) {
    for my $n (qw/init.sql init.list schema.dump/) {
      my $filename = "$layer->{name}__$n";
      ok( exists $files{$filename} && -s File::Spec->catfile( $dump_dir, $filename ),
        "$filename exists and is not empty" );
    }
  }
## TODO absolute/relative paths
## checking conversion (basic)
}

sub initdb {
  my ($config) = @_;
  lives_ok { PMLTQ::Commands->run('initdb') } "Database $config->{db}->{name} initialized";
  my $dbh = database_connect( $config->{db} );
  ok( $dbh && $dbh->ping, 'Database exists' );
  $dbh->disconnect;
}

sub load {
  my ( $config, $dump_dir ) = @_;
  lives_ok { PMLTQ::Commands->run( 'load', "--output_dir=$dump_dir" ) } 'database load successful';
  my $dbh = database_connect( $config->{db} );

  for my $layer ( @{ $config->{layers} } ) {
    my $sth = $dbh->prepare(qq(SELECT "schema" FROM "#PML" WHERE "root" = '$layer->{name}'));
    $sth->execute();
    my $ref = $sth->fetchrow_hashref();
    ok( $ref && !$sth->fetchrow_hashref(), "Schema for $layer->{name} is in database" );
  }
}

sub del {
  my ($config) = @_;
  my $db_name = $config->{db}->{name};

  lives_ok { PMLTQ::Commands->run('delete') } 'delete ok';
  throws_ok { database_connect( $config->{db} ) } qr/database \"$db_name\" does not exist/, 'Database does not exist';
}

sub verify {
  my ( $config, $output_dir ) = @_;

  convert( $config, $output_dir );

  ## database does not exist
  my $h = capture_merged {
    throws_ok { PMLTQ::Commands->run('verify') } qr/Database .* does not exist/, 'verify database does not exist'
  };

  ## database is initialized
  initdb($config);
  $h = capture_merged {
    lives_ok { PMLTQ::Commands->run('verify') } 'verify database is initialized';
  };
  like( $h, qr/Database $config->{db}->{name} exists/, 'database exists' );
  like( $h, qr/Database contains 4 tables/,            'database contains 4 tables' );

  ## database exists and contains data:
  load( $config, $output_dir );

  $h = capture_merged {
    lives_ok { PMLTQ::Commands->run('verify') }, 'verify ok';
  };
  like( $h, qr/Database $config->{db}->{name} exists/, 'database exists' );
  like( $h, qr/Database contains [1-9][0-9]*/,         'database contains tables' );
  like( $h, qr/contains [1-9][0-9]* rows/,             'database contains nonempty tables' );
}

1;
