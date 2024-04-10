#! /usr/bin/env perl
use 5.016;
use warnings;

use lib qw(lib);
use Neo4j::Driver;
use Scalar::Util qw(blessed);
use XXX -with => 'Data::Dump';

# use Carp::Always;
# use Devel::Confess;

#use Neo4j::Driver::

# use Neo4j::Driver::Net::HTTP::Tiny;
# use Neo4j::Driver::Net::HTTP::AnyEvent;
# use Neo4j::Driver::Net::HTTP::REST;
#say "Using ", AnyEvent::detect;
print "This is Neo4j::Driver ", ($Neo4j::Driver::VERSION // "DEV"), "\n";
my $d = Neo4j::Driver->new('bolt://127.0.0.1')->basic_auth('neo4j', 'pass');
$d->config(cypher_params=>v2);
# $d->{net_module} = 'Neo4j::Driver::Net::HTTP::AnyEvent';
# $d->{jolt} = '0';
#XXX $d->session(database=>'system')->run('SHOW DEFAULT DATABASE');
my $s = $d->session;
my $protocol = (map {$_ ? "Bolt/$_" : defined $_ ? "Bolt" : "HTTP/1.1"} $s->server->protocol_version)[0];
say $s->server->agent, " ", $protocol, " (T ", ($s->server->{time_diff}//"undef"), ")";
my $r = $s->run('return "Server OK."');
say $r->fetch->get, $r->isa('Neo4j::Driver::Result::Jolt') ? " (Jolt)" : "";

# {
# #   local $Neo4j::Driver::Result::Jolt::gather_results = 0;
#   say $s->run('return "autocommit 1"')->fetch->get;
#   my $t;
#   $s->execute_read( sub {
#     $t = shift;
#     $r = $t->run('UNWIND [7,8,9] AS x RETURN x');
#     say $r->keys;  # keys() right after run() might be worth adding to the test suite if not already in there
#     say join '/', map { $_->get } $r->list;
#     my @statements = (
#       [ 'RETURN 11' ],
#       [ 'RETURN 22' ],
#       [ 'RETURN 33' ],
#     );
#     my @results = $t->_run_multiple(@statements);
#     foreach my $result ( @results ) {
#       say $result->single->get;
#     }
#     say 'tx closed unexpectedly' if ! $t->is_open;
#     YYY keys $s->{net}{active_tx}->%* if ref $s->{net}{active_tx};
#   });
#   say $t && $t->is_open ? 'tx open after commit - error!' : 'tx closed after commit ok - Success!';
#   ############ problem: tx is marked as closed, but bot actually removed from active_tx list for some reason
#   YYY keys $s->{net}{active_tx}->%* if ref $s->{net}{active_tx};
#   say $s->run('return "autocommit 2"')->fetch->get;
# }
# 
# __END__

sub _looks_like_number {
	my $value = shift;
	no warnings 'numeric';
	return -1 if ref($value);
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

no warnings 'experimental::builtin';
$r = $s->run(<<END, t => builtin::true, f => builtin::false);
MATCH p=(n)-[r]->()<-[]-()
RETURN
null as Null,
{t} as BooleanTrue,
{f} as BooleanFalse,
42 as Integer,
0.5 as Float,
log(-1) as FloatNaN,
//9.9^999 as FloatPosInf,
//-9.9^999 as FloatNegInf,
-0.00 as FloatNegZero,
"hello" as String,
date('1984-10-11') as Date,
time('125035.556+0100') as Time,
localtime('12:50:35.556') as LocalTime,
datetime('2015-06-24T12:50:35.556+0000') as DateTime,
//datetime({year: 1987, month: 12, day: 18, hour: 12, timezone: 'America/Los Angeles'}) as DateTimeZoneId,
localdatetime('2015185T19:32:24') as LocalDateTime,
duration('P29WT31M0.001S') as Duration,
//duration.between(date('2015-06-24'), date('1984-10-11')) as DurationBetween,
//duration('P0D') as Duration0,
//duration('P-0.5D') as Duration1,
//duration('PT-0.2S') as Duration2,
//duration('P-0.77Y') as Duration3,
point({ latitude:-72, longitude:2.5 }) as PointGeod2D,
point({ x:3, y:0, z:1 }) as PointCart3D,
//n.test as Bytes,
apoc.util.compress("fooö",{compression:"NONE"}) as Bytes,
[0.1, 0.2] as List,
{a:0.1, b:0.2} as Map,
n as Node,
r as Relationship,
p as Path
LIMIT 1
END

# YYY $r;
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
	$t .= " (core bool)" if builtin::is_bool($v);
	$t .= " \\$v" if ref($v) eq 'JSON::PP::Boolean';
	$t .= " " . $v->type if blessed $v && $v->isa('Neo4j::Types::DateTime');
	$t .= sprintf " %sM %sD %sS", $v->months, $v->days, $v->seconds + $v->nanoseconds / 1e9 if blessed $v && $v->isa('Neo4j::Types::Duration');
	$t .= ' ' . join ' ', $v->srid < 6000 ? 'geod' : 'cart', $v->coordinates if blessed $v && $v->isa('Neo4j::Types::Point');
# YYY $v if blessed $v && $v->isa('Neo4j::Types::DateTime');
# say $v->{T} if blessed $v && $v->isa('Neo4j::Types::Duration');
# YYY $v if blessed $v && $v->isa('Neo4j::Types::Point');
	{
	no warnings 'deprecated';
	$t .= " " . $v->id . " " . join ",", map {":$_"} $v->labels if ref($v) eq 'Neo4j::Driver::Type::Node';
	$t .= " " . $v->id . " :" . $v->type if ref($v) eq 'Neo4j::Driver::Type::Relationship';
	}
	$t .= " (" . scalar(my @a = $v->relationships) . ")" if ref($v) eq 'Neo4j::Driver::Type::Path';
	$t .= " " . $v->as_string if blessed $v && $v->isa('Neo4j::Types::ByteArray');
	$t .= " " . (keys %$v)[0] if ref($v) eq 'HASH' && 1 == keys %$v;
	$t .= " " . $v->{(keys %$v)[0]} if ref($v) eq 'HASH' && 1 == keys %$v;
	say sprintf "%2d %-14s %s", $i, $keys[$i], $t;
}
# $r = YYY $r->get(17);
# use Devel::Peek;
# Dump $r;
# die $r;

# my $t = $s->begin_transaction;
# $t->run('RETURN 1');
# $t->rollback;
# 
# print "Default database: ";
# say $d->session(database=>'system')->run('SHOW DEFAULT DATABASE')->single->get('name');
# say $d->session->run('return "All done."')->single->get;


#YYY $s->run('MATCH (n) WHERE id(n) = 528 RETURN n.test')->single->get;
# Byte array in JSON:
# { meta => [undef], rest => [[70, 111, 111]], row => [[70, 111, 111]] }
#   at lib/Neo4j/Driver/Result/JSON.pm line 139
# Byte array in Jolt:
# { "#" => "466F6F" }

# Sparse format seems to affect:
# Boolean, Integer, String, Array

#$s->run([['UNWIND [7,8,9] AS x RETURN x'],['RETURN [4,5],6']]);

#YYY $r=$s->run('EXPLAIN MATCH (n), (m) RETURN n, m');




__END__


# ##### TESTING fetch_event
# 
# use AnyEvent::Strict;  # AE_STRICT=1
# 

my $e = 200;
my $x = $s->run('UNWIND range({e}, 2, -1) AS x RETURN x', e=> $e);
# print "starting fetch "; system "date";
while (my $y = $x->fetch) {
	$y->get == $e-- or die "$y $e";
}
# __END__




# $d->config(tls=>1,tls_ca=>'../Neo4j-dist/neo4j-community-4.2.1/certificates/https/neo4j.cert');  # 4
my $m = Neo4j::Driver::Net::HTTP::AnyEvent->new($d);

my $type;
$type = 'application/json';
#$type = 'text/html';
$m->request('GET', 'http://localhost:7474/', undef, $type);
YYY $m->http_header;
XXX $m->fetch_all;







# use AnyEvent;
#  
# $| = 1; print "enter your name> ";
#  
# my $name;
#  
# my $name_ready = AnyEvent->condvar;
#  
# my $wait_for_input = AnyEvent->io (
#    fh   => \*STDIN,
#    poll => "r",
#    cb   => sub {
#       $name = <STDIN>;
#       $name_ready->send;
#    }
# );
#  
# # do something else here
#  
# # now wait until the name is available:
# $name_ready->recv;
#  
# undef $wait_for_input; # watcher no longer needed
#  
# print "your name is $name\n";
# 
# 
# 
# 
# __END__



use AnyEvent::HTTP;
use Data::Dump;

#STDOUT->autoflush;

my $exit_wait = AnyEvent->condvar;

my $handle = http_request
  GET => 'http://localhost:7474/',
  sub {
    my ($body, $headers) = @_;
    dd $headers;
    dd $body;
    $exit_wait->send;
  };

# Do stuff here

$exit_wait->recv;





__END__





use AnyEvent::HTTP;
 
sub download($$$) {
   my ($url, $file, $cb) = @_;
 
   open my $fh, "+<", $file
      or die "$file: $!";
 
   my %hdr;
   my $ofs = 0;
 
   if (stat $fh and -s _) {
      $ofs = -s _;
      warn "-s is ", $ofs;
      $hdr{"if-unmodified-since"} = AnyEvent::HTTP::format_date +(stat _)[9];
      $hdr{"range"} = "bytes=$ofs-";
   }
 
   http_get $url,
      headers   => \%hdr,
      on_header => sub {
         my ($hdr) = @_;
 
         if ($hdr->{Status} == 200 && $ofs) {
            # resume failed
            truncate $fh, $ofs = 0;
         }
 
         sysseek $fh, $ofs, 0;
 
         1
      },
      on_body   => sub {
         my ($data, $hdr) = @_;
 
         if ($hdr->{Status} =~ /^2/) {
            length $data == syswrite $fh, $data
               or return; # abort on write errors
         }
 
         1
      },
      sub {
         my (undef, $hdr) = @_;
 
         my $status = $hdr->{Status};
 
         if (my $time = AnyEvent::HTTP::parse_date $hdr->{"last-modified"}) {
            utime $time, $time, $fh;
         }
 
         if ($status == 200 || $status == 206 || $status == 416) {
            # download ok || resume ok || file already fully downloaded
            $cb->(1, $hdr);
 
         } elsif ($status == 412) {
            # file has changed while resuming, delete and retry
            unlink $file;
            $cb->(0, $hdr);
 
         } elsif ($status == 500 or $status == 503 or $status =~ /^59/) {
            # retry later
            $cb->(0, $hdr);
 
         } else {
            $cb->(undef, $hdr);
         }
      }
   ;
}
 
download "http://localhost:7474", "/Users/aj/Sites/Neo4j/driver-perl/ae.txt", sub {
   if ($_[0]) {
      print "OK!\n";
   } elsif (defined $_[0]) {
      print "please retry later\n";
   } else {
      print "ERROR\n";
   }
};

AnyEvent->condvar->recv;







__END__






#$d->{die_on_error} = 0;
#$d->{jolt} = 1;
my $s = $d->session;
say $s->server->version, " ", $s->server->protocol, " (", $s->server->{time_diff}, ")";
my $r = $s->run('return "Server OK."');
say $r->fetch->get, $r->isa('Neo4j::Driver::Result::Jolt') ? " (Jolt)" : "";
#XXX $s->{net}->{http_adapter};
# # my $x = $d->session->run('match (n) return n limit 1');
# # say $x->single->get;
# # say $x->single->get->id;
# my $x = $d->session->run([['return {`ab.`}','ab.' => 17],['match (n) return n limit 1']]);
# #XXX $x->[0]->list;
# say $x->[0]->single->get;
# say $x->[1]->single->get->id;
#YYY $s->run('return 0.5, 111, '.(2**31).', {}, []')->fetch;

# my $t = $s->begin_transaction;
# $t->run('RETURN 42');
# $t->rollback;

# my $geo   = $s->run('RETURN point({longitude:2, latitude:49})');
# my $geo_z = $s->run('RETURN point({longitude:2, latitude:49, z:80})');
# my $plane = $s->run('RETURN point({x:2, y:49})');
# my $space = $s->run('RETURN point({x:2, y:49, z:80})');
# YYY $_->single->get for ($geo, $geo_z, $plane, $space);

sub active_tx { ref $s->{net}->{active_tx} ? scalar keys %{$s->{net}->{active_tx}} : "$s->{net}->{active_tx}" }

say "commit/rollback: edge cases";
my $t = $s->begin_transaction;
say $t->is_open, ' beginning open';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
$t->rollback;  # } 'immediate rollback';
say ! $t->is_open, ' immediate rollback closes';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
# $t->run;  # throws } qr/\bclosed\b/, 'run after rollback';
# $t->rollback;  # throws } qr/\bclosed\b/, 'rollback after rollback';
# $t->commit;  # throws } qr/\bclosed\b/, 'commit after rollback';
$t = $s->begin_transaction;
$t->commit;  # } 'immediate commit';
say ! $t->is_open, ' immediate commit closes';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
# $t->run;  # throws } qr/\bclosed\b/, 'run after commit';
# $t->commit;  # throws } qr/\bclosed\b/, 'commit after commit';
# $t->rollback;  # throws } qr/\bclosed\b/, 'rollback after commit';

say "commit/rollback: modify database";
my $entropy = [ 156949788, 54632, 153132456, 424697842 ];  # some constant numbers
$entropy = [ time, $$, srand, int 2**31 * rand ];
$t = $s->begin_transaction;
my $q = <<END;
CREATE (n {entropy: {entropy}}) RETURN id(n) AS node_id
END
$r = $t->run( $q, entropy => $entropy )->single;
say $t->is_open, ' create still open';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
my $node_id = $r->get('node_id');
$q = <<END;
MATCH (n) WHERE id(n) = {node_id} RETURN n.entropy, 0
END
$r = $t->run( $q, node_id => 0 + $node_id );
say $t->is_open, ' match still open';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
die "commit: deemed unsafe; something went seriously wrong" unless defined($node_id) && $r->size;
$t->commit;
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
$t = $s->begin_transaction;
$q = <<END;
MATCH (n) WHERE id(n) = {node_id} RETURN n.entropy, 1
END
$r = $t->run( $q, node_id => 0 + $node_id );
my $commit_error = @$entropy;
foreach my $i (0..3) {  # (keys @$entropy)
	$commit_error-- if $r->single->get(0)->[$i] == $entropy->[$i];
}  # 'verify committed data';
say ! $commit_error, ' commit successful';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
$q = <<END;
MATCH (n) WHERE id(n) = {node_id} DELETE n
END
$t->run( $q, node_id => 0 + $node_id );  # 'try deleting node';
$t->rollback;  # } 'rollback';
$t = $s->begin_transaction;
$q = <<END;
MATCH (n) WHERE id(n) = {node_id} RETURN n.entropy, 2
END
$r = $t->run( $q, node_id => 0 + $node_id );  # } 'get data after rollback';
my $rollback_error = @$entropy;
foreach my $i (0..3) {  # (keys @$entropy)
	$rollback_error-- if $r->single->get(0)->[$i] == $entropy->[$i];
}  # 'verify data after rollback';
say ! $rollback_error, ' rollback successful';
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];
$t->rollback;
YYY [active_tx($t), $t->{transaction_endpoint}, $t->{commit_endpoint}];


say '';
say '';

my $ttt = $s->begin_transaction;

say "begin_transaction";
say " is_open: ", $ttt->is_open, "  active_tx: ", active_tx($s);

$ttt->run;

say "run";
say " is_open: ", $ttt->is_open, "  active_tx: ", active_tx($s);

$ttt->rollback;

say "rollback";
say " is_open: ", $ttt->is_open, "  active_tx: ", active_tx($s);

$r = $s->begin_transaction;

say "begin_transaction";
say " is_open: ", $r->is_open, "  active_tx: ", active_tx($s);
say "";

$r->run;

say "run";
say " is_open: ", $r->is_open, "  active_tx: ", active_tx($s);

say "eval:";
eval{$r->run('gg');};print $@;
say "";

say "run('gg')";
say " is_open: ", $r->is_open, "  active_tx: ", active_tx($s);
# $ttt = $s->begin_transaction;
# $ttt->run;
# sleep 62;
# eval{$r->run;};
# YYY $ttt->is_open;

# $q = <<END;
# RETURN {a} AS a, {b} AS b
# END
# my ($a, $b) = (17, 19);
$r = $s->run->size;
$r = $s->run->size;
$r = $s->begin_transaction;
$r->run;

say "begin_transaction+run";
say " is_open: ", $r->is_open, "  active_tx: ", active_tx($s);
# sleep 65;
say 'ok1';

$r = $s->begin_transaction;
$r->run;

say "begin_transaction+run";
say " is_open: ", $r->is_open, "  active_tx: ", active_tx($s);

#XXX $s;

YYY $s->run('return 9.9^999, sqrt(-3)')->single->data;

sub aa {
	$_[0]->is_open;
	my %a = ( %{shift->{net}->{active_tx}} );
	$a{$_} = "$a{$_}" for keys %a;
	YYY \%a;
}
say "0";
for my $i (1..15) {
	sleep 6;
	aa($r);
	print $r->run('RETURN $i', i => $i)->single->get;
	say ": " . Time::Piece->new;
}


__END__

# Jolt

use HTTP::Tiny;
use JSON::MaybeXS;

my $http = HTTP::Tiny->new(
	agent => "Test/0.0.0 ",
	default_headers => {
		Accept => "application/json; q=0.5, application/vnd.neo4j.jolt+json-seq; q=0.8, application/vnd.neo4j.jolt+json-seq; strict=true; q=1",
#		Accept => "application/json; q=0.999, application/vnd.neo4j.jolt+json-seq; q=1, text/html; q=0",
	},
);
my $json = {
  statements => [
    {
      includeStats => \1,
      statement => 'unwind [3,5,7] as x return x, 42, "hi"',
      resultDataContents => ["row","rest","graph"],
    },
    {
      includeStats => \1,
      statement => 'unwind [0,2,4] as x return x, 42, "hi"',
      resultDataContents => ["row","rest","graph"],
    },
  ],
};
my $opts = {
	content => encode_json($json),
	headers => {
		'Content-Type' => 'application/json',
	},
};
my $authority = 'neo4j:pass@localhost:7474';
#my $path = '/db/data/transaction';  # 2/3
my $path = '/db/neo4j/tx';  # 4
my $res = $http->post("http://$authority$path", $opts);
#my $res = $http->get("http://$authority/");
YYY $res->{headers};
print $res->{content};

# json-seq:
# https://tools.ietf.org/html/rfc7464


__END__







# my $xxxx = $s->run("RETURN date('+2015-W13-4') as theDate");
# "theDate"
# "struct<0x44>(16520)"
# Date::Structure(
#     days::Integer,
# )
# The days are days since the Unix epoch.
# pentland:driver-perl aj$ ./jolt.pl 
# This is Neo4j::Driver DEV
# Neo4j/4.2.1 HTTP/1.1
# Server OK.
# bless({ data => "2015-03-26", type => "date" }, "Neo4j::Driver::Type::Temporal")
#   at ./jolt.pl line 37
# pentland:driver-perl aj$ ./jolt.pl 
# This is Neo4j::Driver DEV
# Neo4j/4.2.1 HTTP/1.1
# Server OK. (Jolt)
# { T => "2015-03-26" }
#   at ./jolt.pl line 37





perl -MJSON::XS -E 'say encode_json {statements=>[{statement=>"return log(-1) as FloatNaN, 9.9^999 as FloatPosInf, -9.9^999 as FloatNegInf, -0.00 as FloatNegZero, 0.00 as FloatPosZero"}]}'

{"statements":[{"statement":"return log(-1) as FloatNaN, 9.9^999 as FloatPosInf, -9.9^999 as FloatNegInf, -0.00 as FloatNegZero, 0.00 as FloatPosZero"}]}

curl -u neo4j:pass -fid '{"statements":[{"statement":"return log(-1) as FloatNaN, 9.9^999 as FloatPosInf, -9.9^999 as FloatNegInf, -0.00 as FloatNegZero, 0.00 as FloatPosZero"}]}' -H "Content-Type:application/json" http://localhost:7474/db/neo4j/tx/commit ; echo

HTTP/1.1 200 OK
Date: Tue, 22 Jun 2021 16:23:10 GMT
Access-Control-Allow-Origin: *
Content-Type: application/json
Content-Length: 150

{"results":[{"columns":["FloatNaN","FloatPosInf","FloatNegInf","FloatNegZero","FloatPosZero"],"data":[{"row":["NaN","Infinity","-Infinity",-0.0,0.0],"meta":[null,null,null,null,null]}]}],"errors":[]}

curl -u neo4j:pass -fid '{"statements":[{"statement":"return log(-1) as FloatNaN, 9.9^999 as FloatPosInf, -9.9^999 as FloatNegInf, -0.00 as FloatNegZero, 0.00 as FloatPosZero"}]}' -H "Content-Type:application/json" -H "Accept:application/vnd.neo4j.jolt" http://localhost:7474/db/neo4j/tx/commit ; echo

HTTP/1.1 200 OK
Date: Tue, 22 Jun 2021 16:23:46 GMT
Access-Control-Allow-Origin: *
Content-Type: application/vnd.neo4j.jolt
Content-Length: 148

{"header":{"fields":["FloatNaN","FloatPosInf","FloatNegInf","FloatNegZero","FloatPosZero"]}}
{"data":[{"R":"NaN"},{"R":"Infinity"},{"R":"-Infinity"},{"R":"-0.0"},{"R":"0.0"}]}
{"summary":{}}
{"info":{}}

perl -MJSON::XS -E 'say encode_json {statements=>[{statement=>"UNWIND [0.00, -0.00, 9.9^999, -9.9^999, log(-1)] as x RETURN x"}]}'

{"statements":[{"statement":"UNWIND [0.00, -0.00, 9.9^999, -9.9^999, log(-1)] as x RETURN x"}]}

curl -u neo4j:pass -fid '{"statements":[{"statement":"UNWIND [0.00, -0.00, 9.9^999, -9.9^999, log(-1)] as x RETURN x"}]}' -H "Content-Type:application/json" -H "Accept:application/vnd.neo4j.jolt" http://localhost:7474/db/neo4j/tx/commit ; echo

HTTP/1.1 200 OK
Date: Tue, 22 Jun 2021 17:39:26 GMT
Access-Control-Allow-Origin: *
Content-Type: application/vnd.neo4j.jolt
Content-Length: 182

{"header":{"fields":["x"]}}
{"data":[{"R":"0.0"}]}
{"data":[{"R":"-0.0"}]}
{"data":[{"R":"Infinity"}]}
{"data":[{"R":"-Infinity"}]}
{"data":[{"R":"NaN"}]}
{"summary":{}}
{"info":{}}
