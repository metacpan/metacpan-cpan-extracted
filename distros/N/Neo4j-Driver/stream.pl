#! /usr/bin/env perl
use 5.016;
use warnings;

use lib qw(lib);
use Neo4j::Driver;
use Scalar::Util qw(blessed);
use XXX -with => 'Data::Dump';

# use Carp::Always;
use Devel::Confess 'no_warnings';

#use Neo4j::Driver::

# use Neo4j::Driver::Net::HTTP::Tiny;
# use Neo4j::Driver::Net::HTTP::AnyEvent;
# use Neo4j::Driver::Net::HTTP::REST;
#say "Using ", AnyEvent::detect;
print "This is Neo4j::Driver ", ($Neo4j::Driver::VERSION // "DEV"), "\n";
my $d = Neo4j::Driver->new('http://127.0.0.1')->basic_auth('neo4j', 'pass');
$d->config(cypher_params=>v2);
# $d->{net_module} = 'Neo4j::Driver::Net::HTTP::AnyEvent';
# $d->{jolt} = '0';
#XXX $d->session(database=>'system')->run('SHOW DEFAULT DATABASE');
my $s = $d->session;
my $r;
my $protocol = (map {$_ ? "Bolt/$_" : defined $_ ? "Bolt" : "HTTP/1.1"} $s->server->protocol_version)[0];
say $s->server->agent, " ", $protocol, " (T ", ($s->server->{time_diff}//"undef"), ")";
$r = $s->run('return "Server OK."');
say $r->fetch->get, $r->isa('Neo4j::Driver::Result::Jolt') ? " (Jolt)" : "";

sub yyy {
	my ($tx) = @_;
	
	my $open = eval{ $tx->is_open };  # this MUST force the driver to read events until it gets the tx info
	# (it's correct to do it in is_open because is_open is used exactly when the tx status is required; in particular, it's used for most tx ops, but it's not used between 2 results from run_multiple)
	my $is_open_error = $@;
	
	my $net = $tx->{net};
	my $tx_out = {%$tx};
	$tx_out->{net} = '...';
	
	my $active_tx = { %{$net->{active_tx}} }; $active_tx->{$_} = "$active_tx->{$_}" for keys %$active_tx;
	
	my $out = {
		tx_last_result => !! $tx->{last_result},
		tx_endpoint => $tx->{transaction_endpoint},
		tx_endpoint_commit => $tx->{commit_endpoint},
		net_endpoints => $net->{endpoints},
		net_active_tx => $active_tx,
		tx_is_open => $open ? ($tx->{unused} ? '1 (unused)' : 1) : ($tx->{closed} ? '0 (closed)' : $is_open_error ? 'DIED' : defined $open ? 0 : '0 (undef)'),
	};
	YYY $out;
# 	YYY $out, $tx_out;
# 	YYY eval { $tx->{net}{http_agent}{buffer}; };
# 	YYY eval { $tx->{net}{http_agent}{response}{_content}; };  # NB: might be leftover from prior req
}



my $t;
$t = $s->begin_transaction;

my $entropy = [ 156949788, 54632, 153132456, 424697842 ];
my $q = <<END;
CREATE (n {entropy: {entropy}}) RETURN id(n) AS node_id
END

$r = $t->run( $q, entropy => $entropy )->single;

say $t->{unused};

$t->is_open;

say $t->{unused};

yyy $t;

$t->rollback;

__END__


say '________';

yyy $t;

say '________';

$t->commit;

yyy $t;

__END__
$r = $t->run('unwind [7,8,9] as x return x');

yyy $t;

say $r->fetch->get;

yyy $t;

say for map { $_->get } $r->list;

#$t->rollback;
eval { $t->run('syntax_error')->has_next };

say 'closed the tx';

yyy $t;


__END__

Jolt Streaming

PLAN 2024-03-01:

- tx muss letztes result kennen
- jedes result muss das vorherige kennen
- bei benutzung (is_open bzw. full_buffer etc) -> linked list durchlaufen und alles detachen; im fall der tx führt das dann automatisch zum info-event (bzw. direkt davor; der aufruf in is_open muss sich wahrscheinlich von den anderen der linked list unterscheiden, damit dann über fill_buffer etc hinaus noch die letzten events, also idR genau ein info, geladen werden)



tx_concurrent ----> is this even possible with gather_results = 0 ???
almost certainly will HAVE to set gather_results to 1 when concurrent tx is enabled, because streaming Jolt reads events slowly over the net http_agent, which is shared for all tx in a session and only has a single buffer!
--> possible alternative would be to detach all existing tx of a session when a new tx is started
