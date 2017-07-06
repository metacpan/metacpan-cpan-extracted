#-*-perl-*-
#$Id: 002_agent.t 416 2014-05-05 04:13:30Z maj $
use Test::More;
use Module::Build;
use lib '../lib';
use REST::Neo4p::Exceptions;
use strict;
use warnings;

my @agent_modules = qw/LWP::UserAgent
		       Mojo::UserAgent
		       HTTP::Thin/;

my $build;
my ($user,$pass);
eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};

my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';

use_ok('REST::Neo4p::Agent');

foreach my $mod (@agent_modules) {
    my $ua;
    my $mod_available = 1;
    diag "$mod";
    eval {
	$ua = REST::Neo4p::Agent->new(agent_module=>$mod);
	$ua->ssl_opts(verify_hostname => 0) if $mod =~ /LWP/; # only for tests
    };
    if ( my $e = REST::Neo4p::LocalException->caught ) {
	$mod_available = 0 if ($e->message =~ /is not available/);
    }
    elsif ($e = Exception::Class->caught) {
	ref $e ? $e->rethrow : die $e;
    }
    SKIP : {
	skip "Module $mod not available, skipping...", 14 unless $mod_available;
	isa_ok($ua, $mod);
	isa_ok($ua, 'REST::Neo4p::Agent');
	
	is $TEST_SERVER, $ua->server_url($TEST_SERVER), 'server spec';

	my $not_connected;
	eval {
	    $ua->credentials($TEST_SERVER, 'Neo4j',$user,$pass) if defined $user;
	    $ua->connect;
	};
	if ( my $e = REST::Neo4p::CommException->caught() ) {
	    $not_connected = 1;
	    diag "Test server unavailable : tests skipped";
	}
	elsif ( $e = REST::Neo4p::AuthException->caught() ) {
	    $not_connected = 1;
	    diag "Authorization err (bad pass?)";
	}
	elsif ( $e = Exception::Class->caught() ) {
	    $not_connected = 1;
	    diag "Error (undetermined)";
	}
	SKIP : {
	    skip 'no local connection to neo4j',11 if $not_connected;
	    is $ua->node, join('/',$TEST_SERVER, qw(db data node)), 
	    'node url looks good';
	    my ($version) = $ua->neo4j_version =~ /(^[0-9]+\.[0-9]+)/;
	    cmp_ok $version, '>=', 1.8, 'Neo4j version >= 1.8 as required';
	    like $ua->relationship_types, qr/^http.*types/, 
	    'relationship types url';
	    ok $ua->post_node( [],{hyrax => 'rock badger' } ), 'create sample node';
	    isa_ok $ua->raw_response, 'HTTP::Response';
	    my $s = $ua->decoded_content->{self};
	    (my $id) = $s =~ /([0-9]+)$/;
	    like $ua->raw_response->header('Content-Type'), qr/stream=true/,
	      'server acknowledges streaming (expected default)';
	    $ua->get_node($id);
	    like $ua->raw_response->header('Content-Type'), qr/stream=true/,
	      'server acknowledges streaming (expected default)';
	    ok $ua->no_stream, 'set no streaming';
	    $ua->get_node($id);
	    isa_ok $ua->raw_response, 'HTTP::Response';
	    unlike $ua->raw_response->header('Content-Type'), qr/stream=true/,
	      'server acknowledges no streaming';
	    $ua->delete_node($id);
	}
    }
}
done_testing;

