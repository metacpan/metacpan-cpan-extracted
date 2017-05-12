#!/usr/bin/perl
use strict;
use lib 'blib/lib', 'blib/arch';
use feature 'say';
use Benchmark qw/timethis timethese/;
use Panda::URI qw/uri encode_uri_component encodeURIComponent decodeURIComponent :const/;
use Data::Dumper qw/Dumper/;
use Storable qw/freeze thaw dclone/;
use JSON::XS;
use URI;
say "START";

use Devel::Peek;

sub tst {
    my $s = shift;
    my $uri = Panda::URI->new($s);
    #$uri->query;
}

timethese(-1, {
    short  => sub { tst("http://ya.ru/") },
    medium => sub { tst("http://ya.ru/my/path?a=b&c=d#jjj") },
    long   => sub { tst("http://jopa.dev.crazypanda.ru/my/very/long/path?param1=val1&params2=val2&param3=val3&param4=val4#myverybigfuckinghash") },
});

exit;

my $u = Panda::URI->new("http://ya.ru/path?a=b&c=d#jjj");
my $uu = URI->new("http://ya.ru/path?a=b&c=d#jjj");
my $us = Panda::URI::http->new("http://jopa.ru");

my $qn = {};
my $qs = {a => "1", b => "2"};
my $qm = {a => "1", b => "2", c => "3", d => "4", abcd => 'dsfdsf'};
my $qb = {map {$_ => "$_"} 1..100};
my $qa = {a => [1,2,3,4]};

timethese(-1, {
    objret_common => sub { Panda::URI::ttt($u); },
    objret_strict => sub { Panda::URI::ttt($us); },
});
exit();

while (1) {
    my $uri = uri("http://ya.ru");
}

my $uri = uri("http://ya.ru/path?a=b&c=d#jjj");
my $f = freeze($uri);
my $c = thaw($f);


say "END";
