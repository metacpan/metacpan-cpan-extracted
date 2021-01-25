use 5.12.1;
use strict;
use warnings;

use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);

use Carp qw(croak confess);

my %opsview = (
    url                 => 'http://localhost',
    username            => 'admin',
    password            => 'initial',
    ssl_verify_hostname => 0,
);

for my $var (qw/ url username password /) {
    my $envvar = 'OPSVIEW_' . uc($var);
    if ( !$ENV{$envvar} ) {
        diag "Using default '$envvar' value of '$opsview{$var}' for testing.";
    }
    else {
        $opsview{$var} = $ENV{$envvar};
        note "Using provided '$envvar' for testing.";
    }
}

use_ok( "Opsview::RestAPI" );

my @test_urls = (
    {
        desc => 'api_version endpoint',
        url  => '/rest',
        args => { api => '' },
    },
    {
        desc => 'randomuparameters',

        url  => '/rest/endpoint?abc=def&ghi=lmn',
        args => {
            api    => 'endpoint',
            params => {
                abc => 'def',
                ghi => 'lmn',
            },
        },
    },
    {
        desc => 'login endpoint',
        url =>
          '/rest/login?password=assumed_password&username=assumed_username',
        args => {
            api    => 'login',
            params => {
                username => 'assumed_username',
                password => 'assumed_password',
            },
        }
    }
);

my $rest = trap {
    Opsview::RestAPI->new(%opsview);
};

for my $test (@test_urls) {

    my $url = trap { $rest->_generate_url( %{ $test->{args} } ) };

    $trap->did_return( "call returned for " . $test->{desc} );
    $trap->quiet( "no errors for " . $test->{desc} );

    is( $url, $test->{url}, "URL matches for " . $test->{desc} );
}

done_testing();
