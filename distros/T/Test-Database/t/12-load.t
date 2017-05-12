use strict;
use warnings;
use Test::More;
use Test::Database::Util;
use File::Spec;

my @good = (
    {   dsn      => 'dbi:mysql:database=mydb;host=localhost;port=1234',
        username => 'user',
        password => 's3k r3t',
    },
    {   dsn      => 'dbi:mysql:database=mydb;host=remotehost;port=5678',
        username => 'otheruser',
    },
    { dsn => 'dbi:SQLite:db.sqlite' },
    {   driver_dsn => 'dbi:mysql:host=remotehost;port=5678',
        username   => 'otheruser',
    },
);

my @bad = (
    [   File::Spec->catfile(qw< t database.bad >),
        qr/^Can't parse line at .*, line \d+:\n  <bad format> at /
    ],
    [   File::Spec->catfile(qw< t database.bad2 >),
        qr/^Record doesn't start with dsn or driver_dsn .*, line \d+:\n  <drh      = dbi:mysql:> at /
    ],
    [ 'missing', qr/^Can't open missing for reading: / ],
);

plan tests => 1 + @good + 2 * @bad + 1;

# load a correct file
my $file   = File::Spec->catfile(qw< t database.good >);
my @config = _read_file($file);

is( scalar @config, scalar @good,
    "Got @{[scalar @good]} handles from $file" );

for my $test (@good) {
    my $args = shift @config;
    is_deeply( $args, $test,
        "Read args for handle " . ( $test->{dsn} || $test->{driver_dsn} ) );
}

# try to load a bad file
for my $t (@bad) {
    my ( $file, $regex ) = @$t;
    ok( !eval { _read_file($file); 1 }, "_read_file( $file ) failed" );
    like( $@, $regex, 'Expected error message' );
}

# load an empty file
$file = File::Spec->catfile(qw< t database.empty >);
is( scalar _read_file($file), 0, 'Empty file' );

