#!/usr/bin/env perl
use 5.012;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Benchmark qw/timethis timethese/;
use MyTest;
use Protocol::HTTP::Request;

say $$;

die "usage: $0 <what> [--profile]" unless @ARGV;

my @cmds;
my $time = -1;
for (@ARGV) {
    $time = -10, next if m/--profile/;
    push @cmds, $_;
}

for (@cmds) {
    no strict 'refs';
    say "$_";
    
    if (my $sub = main->can($_)) {
        $sub->();
    } else {
        my $sub = MyTest->can("bench_$_") or die "unknown $_";
        timethis($time, $sub);
        #$sub->();
    }
}

say "DONE";

sub iequals_short {
    say "val: " . MyTest::bench_iequals("Cookie", "cookie");
    timethis($time, sub { MyTest::bench_iequals("Cookie", "Cookie") });
}

sub iequals_medium {
    say "val: " . MyTest::bench_iequals("Transfer-Encoding123", "transfer-encoding123");
    timethis($time, sub { MyTest::bench_iequals("Transfer-Encoding123", "Transfer-Encoding123") });
}

sub iequals_long {
    my $s1 = "Transfer-Encoding123" x 50;
    my $s2 = "Transfer-Encoding123" x 50;
    say "val: " . MyTest::bench_iequals($s1, $s2);
    timethis($time, sub { MyTest::bench_iequals($s1, $s2) });
}

sub serialize_req_mid2() {
    my @reqs = map {
        my $req = Protocol::HTTP::Request->new({
            method            => METHOD_GET,
            uri               => "http://alx3apps.appspot.com",
            #allow_compression => [ Protocol::HTTP::Compression::gzip ],
            headers           => {
                MyHeader          => "my value",
                'User-Agent'      => "Mozilla/5.0(Windows;U;WindowsNT6.1;en-GB;rv:1.9.2.13)Gecko/20101203Firefox/3.6.13",
                'Accept'          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n",
                'Accept-Language' => "my value",
            },
            body         => "my body",
        });
    } (1 .. 10_000);
    timethis($time, sub { $_->to_string for (@reqs) });
}
