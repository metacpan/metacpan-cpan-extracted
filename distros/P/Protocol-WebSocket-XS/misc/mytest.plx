#!/usr/local/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Benchmark qw/timethis timethese/;
use JSON::XS qw/encode_json/;
use Data::Dumper qw/Dumper/;
use Time::HiRes;
use Panda::WebSocket;
use WSTest;

say "START $$";

my $p = WSTest::get_established_client();

my $s = WSTest::gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => ("1" x 100000)});
my $f1 = substr($s, 0, 6);
my $f2 = substr($s, 6);

timethis(-100, sub { $p->test_parse_frame($s) });

my $pl = ("1" x 100000);
timethis(-1, sub { $p->test_send_frame($pl) });

1;
