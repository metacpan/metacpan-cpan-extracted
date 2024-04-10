#! /usr/bin/env perl
use 5.024;
use warnings;

use lib qw(lib);
use Neo4j::Driver;
use XXX -with => 'Data::Dump';

# use Carp::Always;
# use Devel::Confess;

#use Neo4j::Driver::

# use Neo4j::Driver::Net::HTTP::Tiny;
# use Neo4j::Driver::Net::HTTP::AnyEvent;
# use Neo4j::Driver::Net::HTTP::REST;
#say "Using ", AnyEvent::detect;
print "This is Neo4j::Driver ", ($Neo4j::Driver::VERSION // "DEV"), "\n";
my $d = Neo4j::Driver->new('http://[::1]:591')->basic_auth('neo4j', 'pass');
$d->config(cypher_params=>v2);
# $d->{die_on_error} = 0;
# $d->{net_module} = 'Neo4j::Driver::Net::HTTP::AnyEvent';
# $d->{jolt} = 'ndjson';  # 'ndjson' might be problematic for some reason ... whatever, it's unsupported anyway
#XXX $d->session(database=>'system')->run('SHOW DEFAULT DATABASE');
# eval {$d->session;};die 0+$!;
my $s = $d->session(database => undef);
my $protocol = (map {$_ ? "Bolt/$_" : defined ? "Bolt" : "HTTP/1.1"} $s->server->protocol_version)[0];
say $s->server->agent, " ", $protocol, " (T ", ($s->server->{time_diff} // "0"), ")";
my $r = $s->run('return "Server OK."');
say $r->fetch->get, $r->isa('Neo4j::Driver::Result::Jolt') ? " (Jolt)" : "";


# $d->{timeout} = undef;
# $s->execute_write('CREATE ()-[n] RETURN n');
say $r = $s->execute_write(sub {
	my $tx = shift;
	my $r = $tx->run('RETURN "function!"')->fetch->get;
});
# say join ',', $s->execute_write(sub {
# 	my $tx = shift;
# 	my $r = $tx->run('RETURN [3,4,5]')->fetch->get;
# 	@$r
# });
#my $tx = $s->begin_transaction;
#$tx->run('CREATE ()-[n] RETURN n');
$s->execute_write(sub {
	my $tx = shift;
	#my $r = $tx->run('XXXXXXCREATE (n:Test {answer:42}) RETURN n');
# 	my $r = $tx->run('CREATE ()-[n] RETURN n');
});



# use Devel::Cycle;
# find_cycle $d;
# find_cycle $s;



__END__

sub _looks_like_number {
	my $value = shift;
	no warnings 'numeric';
	# if the utf8 flag is on, it almost certainly started as a string
	return if utf8::is_utf8($value);
	# detect numbers
	# string & "" -> ""
	# number & "" -> 0 (with warning)
	# nan and inf can detect as numbers, so check with * 0
	return unless length((my $dummy = "") & $value);
	return unless 0 + $value eq $value;
	return 1 if $value * 0 == 0;
	return -1; # inf/nan
}

$r = $s->run(<<END);
MATCH p=(n)-[r]->()<-[]-()
RETURN
null as Null,
42 as Integer,
0.5 as Float,
"hello" as String,
n as Node,
r as Rel,
[0.1, 0.2] as List,
{a:0.1, b:0.2} as Map
LIMIT 1
END

use Data::Dump;
my @keys = $r->keys;
$r = $r->single;
for my $i ( 0 .. $#keys ) {
	my $v = $r->get($i);
	my $t = "";
	$t = "undef" if ! defined $v;
	$t = $v if defined $v && _looks_like_number $v;
	$t = "'$v'" if defined $v && ! _looks_like_number $v;
	$t = ref($v) if ref($v);
	$t .= " \\$v" if ref($v) eq 'JSON::PP::Boolean';
	$t .= " " . $v->id . " " . join ",", map {":$_"} $v->labels if ref($v) eq 'Neo4j::Driver::Type::Node';
	$t .= " " . $v->id . " :" . $v->type if ref($v) eq 'Neo4j::Driver::Type::Relationship';
	$t .= " (" . scalar(my @a = $v->relationships) . ")" if ref($v) eq 'Neo4j::Driver::Type::Path';
	$t .= " " . (keys %$v)[0] if ref($v) eq 'HASH' && 1 == keys %$v;
	$t .= " " . $v->{(keys %$v)[0]} if ref($v) eq 'HASH' && 1 == keys %$v;
	say sprintf "%2d %-13s %s", $i, $keys[$i], $t;
}




__END__

