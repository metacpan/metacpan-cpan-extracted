use Test::More tests => 22;

use FindBin;
my $dat_file = "$FindBin::Bin/query.dat";
ok(-f $dat_file, "data file present");
open(FH, '<', $dat_file);
sysread(FH, my $pkt, -s FH);
close(FH);

use Net::WDNS;
use Net::WDNS::Msg;

my $msg = new_ok('Net::WDNS::Msg', [$pkt]);

my $msg2 = Net::WDNS::parse_message($pkt);
ok(UNIVERSAL::isa($msg2, 'Net::WDNS::Msg'), "parse_message()");

cmp_ok($msg->id,     '==',     18873,     'id');
cmp_ok($msg->rcode,  'eq', 'NOERROR',  'rcode');
cmp_ok($msg->opcode, 'eq',   'QUERY', 'opcode');
my $flags = $msg->flags;
foreach my $flag (qw( tc cd ad aa )) {
  cmp_ok($flags->{$flag}, '==', 0, "$flag flag not set");
}
foreach my $flag (qw( ra qr rd )) {
  cmp_ok($flags->{$flag}, '==', 1, "$flag flag set");
}

my $query      = $msg->question;
my $answer     = $msg->answer;
my $authority  = $msg->authority;
my $additional = $msg->additional;

my $query_total = @$query;
my $answer_total = 0;
for my $rr (@$answer) {
  my @rd = $rr->rdata;
  $answer_total += @rd;
}
my $authority_total = 0;
for my $rr (@$authority) {
  my @rd = $rr->rdata;
  $authority_total += @rd;
}
my $additional_total = 0;
for my $rr (@$additional) {
  my @rd = $rr->rdata;
  $additional_total += @rd;
}

cmp_ok($query_total,      '==',  1,      '1 query');
cmp_ok($answer_total,     '==', 11,    '11 answer');
cmp_ok($authority_total,  '==',  4,  '4 authority');
cmp_ok($additional_total, '==',  4, '4 additional');

my @query_strs = (
  "google.com. IN A",
);
is_deeply([map { $_->as_str } @$query], \@query_strs, "question strings");

my @answer_strs = (
  "google.com. 20 IN A 74.125.228.7\n"  .
  "google.com. 20 IN A 74.125.228.8\n"  .
  "google.com. 20 IN A 74.125.228.2\n"  .
  "google.com. 20 IN A 74.125.228.3\n"  .
  "google.com. 20 IN A 74.125.228.6\n"  .
  "google.com. 20 IN A 74.125.228.9\n"  .
  "google.com. 20 IN A 74.125.228.1\n"  .
  "google.com. 20 IN A 74.125.228.5\n"  .
  "google.com. 20 IN A 74.125.228.0\n"  .
  "google.com. 20 IN A 74.125.228.14\n" .
  "google.com. 20 IN A 74.125.228.4",
);
is_deeply([map { $_->as_str } @$answer], \@answer_strs, "answer strings");

my @authority_strs = (
  "google.com. 49980 IN NS ns2.google.com.\n" .
  "google.com. 49980 IN NS ns4.google.com.\n" .
  "google.com. 49980 IN NS ns3.google.com.\n" .
  "google.com. 49980 IN NS ns1.google.com.",
);
is_deeply([map { $_->as_str } @$authority],
          \@authority_strs, "authority strings");

my @additional_strs = (
  "ns3.google.com. 120622 IN A 216.239.36.10",
  "ns1.google.com. 120622 IN A 216.239.32.10",
  "ns4.google.com. 120622 IN A 216.239.38.10",
  "ns2.google.com. 120622 IN A 216.239.34.10",
);
is_deeply([map { $_->as_str } @$additional],
          \@additional_strs, "additional strings");

my $msg_str = <<__MSG;
;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 18873
;; flags: qr rd ra; QUERY: 1, ANSWER: 11, AUTHORITY: 4, ADDITIONAL: 4

;; QUESTION SECTION:
;google.com. IN A

;; ANSWER SECTION:
google.com. 20 IN A 74.125.228.7
google.com. 20 IN A 74.125.228.8
google.com. 20 IN A 74.125.228.2
google.com. 20 IN A 74.125.228.3
google.com. 20 IN A 74.125.228.6
google.com. 20 IN A 74.125.228.9
google.com. 20 IN A 74.125.228.1
google.com. 20 IN A 74.125.228.5
google.com. 20 IN A 74.125.228.0
google.com. 20 IN A 74.125.228.14
google.com. 20 IN A 74.125.228.4

;; AUTHORITY SECTION:
google.com. 49980 IN NS ns2.google.com.
google.com. 49980 IN NS ns4.google.com.
google.com. 49980 IN NS ns3.google.com.
google.com. 49980 IN NS ns1.google.com.

;; ADDITIONAL SECTION:
ns3.google.com. 120622 IN A 216.239.36.10
ns1.google.com. 120622 IN A 216.239.32.10
ns4.google.com. 120622 IN A 216.239.38.10
ns2.google.com. 120622 IN A 216.239.34.10
__MSG

cmp_ok($msg->as_str, "eq", $msg_str, "message string");
