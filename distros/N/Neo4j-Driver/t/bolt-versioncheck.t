#!perl
use v5.12;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings 0.010 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


package Neo4j::Client {}
package Neo4j::Bolt {	
	sub connect { shift }
	sub connected { 'mocked' }
}

$INC{'Neo4j/Bolt.pm'} = $INC{'Neo4j/Client.pm'} = __FILE__;

require Neo4j::Driver::Net::Bolt;
require Neo4j::Driver;

sub new_connected {
	no warnings 'once';
	$Neo4j::Driver::Net::Bolt::verify_version = 1;
	my $net = Neo4j::Driver::Net::Bolt->new( Neo4j::Driver->new );
	return $net->{connection}->connected;
}

sub set_versions {
	$Neo4j::Bolt::VERSION = shift;
	$Neo4j::Client::VERSION = pop;
	sprintf "perlbolt %s + perlclient %s",
		$Neo4j::Bolt::VERSION // "undef", $Neo4j::Client::VERSION // "undef"
}

sub connection_ok ($$) {
	my $test_name = &set_versions;
	lives_and { is &new_connected, 'mocked' } $test_name;
}

sub connection_dies_ok ($$) {
	my $test_name = &set_versions;
	throws_ok { &new_connected } qr/\bNeo4j::Bolt not installed\b.*\bversion/si, "$test_name dies";
}


plan tests => 3 + $no_warnings;

subtest 'supported' => sub {
	plan tests => 6;
	connection_ok '0.5000', '0.54';
	connection_ok '1.0000', '1.00';
	connection_ok '0.4203', '0.54';
	connection_ok '0.4203', '0.46';
	connection_ok '0.4201', '0.54';
	connection_ok '0.4201', '0.46';
};

subtest 'outdated perlbolt' => sub {
	plan tests => 3;
	connection_dies_ok '0.4200', '0.54';
	connection_dies_ok '0.4200', '0.46';
	connection_dies_ok '0.20',   '0.46';
};

subtest 'broken client' => sub {
	plan tests => 4;
	connection_dies_ok '0.4203', '0.50';
	connection_dies_ok '0.4203', '0.51';
	connection_dies_ok '0.4203', '0.52';
	connection_ok      '0.4203', undef;
};

done_testing;
