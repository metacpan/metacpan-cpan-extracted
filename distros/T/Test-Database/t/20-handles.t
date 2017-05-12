use strict;
use warnings;
use Test::More;
use File::Spec;
use Test::Database;

my %handle = (
    mysql1 => Test::Database::Handle->new(
        dsn      => 'dbi:mysql:database=mydb;host=localhost;port=1234',
        username => 'user',
        password => 's3k r3t',
    ),
    mysql2 => Test::Database::Handle->new(
        dsn      => 'dbi:mysql:database=mydb;host=remotehost;port=5678',
        username => 'otheruser',
    ),
    sqlite => Test::Database::Handle->new( dsn => 'dbi:SQLite:db.sqlite', ),
);
delete $_->{driver} for values %handle;

# test description:
# 1st char is variable to look at: array (@) or scalar ($)
# 2nd char is expected result: list (@), single item ($) or number (1)
my @code;
my %tests = map {
    my ( $fmt, $code ) = split / /, $_, 2;
    push @code, $code;
    ( $code => $fmt )
} split /\n/, << 'CODE';
@@ @handles = Test::Database->handles(@requests);
$1 $handle  = Test::Database->handles(@requests);
$$ $handle  = ( Test::Database->handles(@requests) )[0];
$$ ($handle) = Test::Database->handles(@requests);
$$ $handle  = Test::Database->handle(@requests);
@$ @handles = Test::Database->handle(@requests);
CODE

my @tests = (

    # request, expected response
    [ [],        [ @handle{qw( mysql1 mysql2 sqlite )} ], '' ],
    [ ['mysql'], [ @handle{qw( mysql1 mysql2 )} ],        q{'mysql'} ],
    [ ['sqlite'], [], q{'sqlite'} ],
    [ ['SQLite'], [ $handle{sqlite} ], q{'SQLite'} ],
    [ ['Oracle'], [], q{'Oracle'} ],
    [   [ 'SQLite', 'mysql' ],
        [ @handle{qw( mysql1 mysql2 sqlite )} ],
        q{'SQLite', 'mysql'}
    ],
    [   [ 'mysql', 'SQLite', 'mysql' ],
        [ @handle{qw( mysql1 mysql2 sqlite )} ],
        q{'mysql', 'SQLite', 'mysql'}
    ],
    [   [ 'mysql', 'Oracle', 'SQLite' ],
        [ @handle{qw( mysql1 mysql2 sqlite )} ],
        q{'Oracle', 'mysql', 'SQLite'}
    ],
    [ [ { dbd => 'mysql' } ], [ @handle{qw( mysql1 mysql2 )} ], q{'mysql'} ],
    [   [ { driver => 'mysql' } ],
        [ @handle{qw( mysql1 mysql2 )} ],
        q{'mysql'}
    ],

);

# reset the internal structures and force loading our test config
Test::Database->clean_config();
my $config = File::Spec->catfile( 't', 'database.rc' );
Test::Database->load_config( $config );

plan tests => @tests * keys %tests;

for my $test (@tests) {
    my ( $requests, $responses, $desc ) = @$test;
    my %expected = (
        '1' => [ scalar @$responses ],
        '$' => [ $responses->[0] ],
        '@' => $responses,
        '0' => [],
    );

    # try out each piece of code
    my @requests = @$requests;
    for my $code (@code) {
        my ( $handle, @handles );
        my ( $got, $expected ) = split //, $tests{$code};

        # special case
        $expected = '0' if $tests{$code} eq '@$' && !@$responses;

        # run the code
        eval "$code; 1;" or do {
            ok( 0, $code );
            diag $@;
            next;
        };
        ( my $mesg = $code ) =~ s/\@requests/$desc/;
        $got
            = $got eq '$' ? [$handle]
            : $got eq '@' ? \@handles
            :               die "Unknown variable symbol $got";
        ref && delete $_->{driver} for @$got;
        is_deeply( $got, $expected{$expected}, $mesg );
    }
}

