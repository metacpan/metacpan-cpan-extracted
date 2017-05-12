#!/usr/bin/env perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

BEGIN {
    use_ok('Nagios::Scrape');
}

my $nagios;

throws_ok {
    $nagios = Nagios::Scrape->new(
        password => 'foobar',
        url      => 'http://localhost/cgi-bin/status.cgi',
    );
}
'Error::Simple', 'Error when username not specified';

throws_ok {
    $nagios = Nagios::Scrape->new(
        username => 'nagiosadmin',
        url      => 'http://localhost/cgi-bin/status.cgi',
    );
}
'Error::Simple', 'Error when password not specified';

throws_ok {
    $nagios = Nagios::Scrape->new(
        username => 'nagiosadmin',
        password => 'foobar',
    );
}
'Error::Simple', 'Error when URL not specified';

throws_ok {
    $nagios = Nagios::Scrape->new(
        username => 'nagiosadmin',
        password => 'foobar',
        url      => 'localhost/cgi-bin/status.cgi',
    );
}
'Error::Simple', 'Error when URL is not prefixed with http';

throws_ok {
    $nagios = Nagios::Scrape->new(
        username => 'nagiosadmin',
        password => 'foobar',
        url      => 'http://localhost/cgi-bin/status',
    );
}
'Error::Simple', 'Error when URL is not postfixed with status.cgi';

# Correct initialization
ok(
    $nagios = Nagios::Scrape->new(
        username => 'nagiosadmin',
        password => 'foobar',
        url      => 'http://localhost/cgi-bin/status.cgi',
    ),
    'Successful initialization of Nagios::Scrape object'
);

# Correct get/set for host_status
is($nagios->host_state, 12, 'Default host_state is correct');
$nagios->host_state(14);
is($nagios->host_state, 14, 'Able to set host_state');
is($nagios->service_state, 28, 'Default service_state is correct');
$nagios->service_state(30);
is($nagios->service_state, 30, 'Able to set service_state');

can_ok( $nagios, 'host_state' );
can_ok( $nagios, 'service_state' );
can_ok( $nagios, 'get_service_status' );
can_ok( $nagios, 'parse_service_content' );
can_ok( $nagios, 'decode_html' );

# Test connectivity-based functionality
# Requires a file called 'nagios.cfg' with the following 3 lines:
# username
# password
# url

SKIP: {

    eval { 
        open(my $file, 't/nagios.cfg') or die('File not found');
        my @data = <$file>;
        close($file);
        chomp( my $username = $data[0] );
        chomp( my $password = $data[1] );
        chomp( my $url      = $data[2] );
        $nagios = Nagios::Scrape->new(
            username => $username,
            password => $password,
            url      => $url
        );
    };

    skip( 'Missing nagios.cfg file with authentication data', 1 ) if $@;
    ok( my @service_alerts = $nagios->get_service_status(), 'Retrieving Service alerts works' );
    ok( my @host_alerts    = $nagios->get_host_status(), 'Retrieving Host alerts works' );

}
