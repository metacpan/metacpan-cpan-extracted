package MyDB;
use strict;
use warnings;
use base qw( Rose::DBx::AutoReconnect );

use Carp;
use FindBin;
use Path::Class::File;
use IPC::Cmd qw( run );

my $db;
my $sql;
my $base_path;

# allow for running via test server as well as via tests
for my $path ( "$FindBin::Bin/../../..", "$FindBin::Bin" ) {
    if ( -s Path::Class::File->new( $path, "rdgc.sql" ) ) {
        $base_path = $path;
    }
}

if ( !$base_path ) {
    croak "can't locate base path using FindBin $FindBin::Bin";
}

$sql = Path::Class::File->new( $base_path, 'rdgc.sql' );
$db  = Path::Class::File->new( $base_path, 'rdgc.db' );

# create the db if it does not yet exist
if ( !-s $db ) {
    if (!scalar run( command => "sqlite3 $db < $sql", verbose => 1 ) ) {
        die "can't create db $db with sqlite3: $!";
    }
}

if ( !$db or !-s $db ) {
    croak "can't locate rdgc.db";
}

__PACKAGE__->register_db(
    domain          => 'default',
    type            => 'default',
    driver          => 'sqlite',
    database        => $db,
    auto_create     => 0,
    connect_options => {
        AutoCommit => 1,
        ( ( rand() < 0.5 ) ? ( FetchHashKeyName => 'NAME_lc' ) : () ),
    },
    post_connect_sql =>
        [ 'PRAGMA synchronous = OFF', 'PRAGMA temp_store = MEMORY', ],
);

1;
