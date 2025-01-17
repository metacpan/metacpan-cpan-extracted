use strict;
use warnings;

#use MySQL::Hi;

use Config::Simple;

use Test::More;
use Test::Deep;
use Test::Warn;

use Data::Dumper;

my $class = 'MySQL::Hi';

my $defaults = {
    host     => 'localhost',
    port     => 3306,
    password => '',
};

my @tests = (
    {
        name => 'All params in file',
        config => [
            {
                db       => 'test_db',
                mode     => 'rw',
                host     => 'test_host',
                password => 'hunter2',
                port     => 8080,
            },
            {
                db       => 'test_db',
                host     => 'test_host',
                password => 'hunter2',
                port     => 8080,
            },
        ],
    },
    {
        name => 'Host missing',
        config => [
            {
                db       => 'test_db',
                mode     => 'rw',
                password => 'hunter2',
                port     => 8080,
            },
            {
                db       => 'test_db',
                password => 'hunter2',
                port     => 8080,
            },
        ],
    },
    {
        name => 'Password missing',
        config => [
            {
                db       => 'test_db',
                mode     => 'rw',
                host     => 'test_host',
                port     => 8080,
            },
            {
                db       => 'test_db',
                host     => 'test_host',
                port     => 8080,
            },
        ],
    },
    {
        name => 'Port missing',
        config => [
            {
                db       => 'test_db',
                mode     => 'rw',
                host     => 'test_host',
                password => 'hunter2',
            },
            {
                db       => 'test_db',
                host     => 'test_host',
                password => 'hunter2',
            },
        ],
    },
    {
        name => 'All missing',
        unknown_param => 'foo',
        config => [
            {
                db       => 'test_db',
                foo      => 'bar', # needed to create a file
            },
        ],
    },
);

my $test_count     = 0;
my $unknown_params = 0;

for my $t ( @tests ) {
    $test_count     += scalar( @{ $t->{config} } );
    $unknown_params += scalar( @{ $t->{config} } )
        if $t->{unknown_param};
}

plan tests => 0
    + 1                   # use_ok
    + scalar( @tests )    # new_ok
    + $unknown_params     # Unknown params warnings
    + $test_count         # Test credentials
    + 2 * $test_count     # Unknown DB
    + 2 * $test_count     # Unknown mode
;

use_ok( $class );

for my $test ( @tests ) {
    # Create config file
    my $filename = &create_config( $test );

    # Create MySQL::Hi object
    my $hi;
    if ( $test->{unknown_param} ) {
        warning_is
            {
                $hi = new_ok( $class => [ config => $filename ], $test->{name} );
            }
            {
                carped => "Unknown parameter '$test->{unknown_param}' in [$test->{config}[0]{db}]\n"
            },
            $test->{name} . ": unknown param";

    }
    else {
        $hi = new_ok( $class => [ config => $filename ], $test->{name} );
    }

    # Run tests
    for my $c ( @{ $test->{config} } ) {

        # Test get_credentials
        my %config = %$c;
        my $db   = $config{db};
        my $mode = exists $config{mode} ? $config{mode} : '';
        my $credentials = $hi->get_credentials( $db, $mode );
        my $expected = {
            host     => exists $config{host} ? $config{host} : $hi->default_value('host'),
            port     => exists $config{port} ? $config{port} : $hi->default_value('port'),
            password => exists $config{password} ? $config{password} : $hi->default_value('password'),
        };
        cmp_deeply( $credentials, $expected, $test->{name} );

        # Unknown DB
        my $colon_mode = $mode ? ":$mode" : "";
        warning_is
            {
                $credentials = $hi->get_credentials( '[unknown DB]', $mode );
            }
            {
                carped => "No credentials for the '[unknown DB]$colon_mode' in config $filename\n"
            },
            $test->{name} . ": unknown DB - warning";
        cmp_deeply( $credentials, $defaults, $test->{name} . ": unknown DB" );

        # Unknown mode
        warning_is
            {
                $credentials = $hi->get_credentials( $db, 'unknown mode' );
            }
            {
                carped => "No credentials for the '$db:unknown mode' in config $filename\n"
            },
            $test->{name} . ": unknown mode - warning";
        cmp_deeply( $credentials, $defaults, $test->{name} . ": unknown mode" );

        # The methods get_options and get_dsn return strings that are
        # built of whatever get_credentials returns. It does not make
        # sense to test these two methods.
    }

    # Unlink config file
    unlink $filename;
}


# Create config file
#
sub create_config {
    my ( $test ) = @_;

    my $filename = lc $test->{name};
    $filename =~ s/[^a-z0-9]/_/ig;
    $filename = "/tmp/$filename.cfg";

    my $cfg = Config::Simple->new( syntax => 'ini' );

    for my $c ( @{ $test->{config} } ) {
        my $block = $c->{db}
            . ( exists $c->{mode} ? ":" . $c->{mode} : '' );

        for my $param ( keys %$c ) {
            next
                if $param eq 'db' || $param eq 'mode';
            $cfg->param( "$block.$param", $c->{ $param } );
        }
    }
    $cfg->write( $filename );

    return $filename;
}


1;
