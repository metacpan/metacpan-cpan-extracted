#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;

use File::Spec;
use File::Temp ();
use FindBin;
use vars qw/@INC %INC/;

$ENV{PAR_TMPDIR} = File::Temp::tempdir(TMPDIR => 1, CLEANUP => 1);

unshift @INC, ($FindBin::Bin);
use_ok('PAR');

my $par = File::Spec->catfile($FindBin::Bin, 'hello.par');

ok(-f $par, 'PAR file for testing exists.');

eval "use PAR { file => '$par'};";
warn $@ if $@;
ok(!$@, "use PAR {file =>...} threw error");

require Hello;
my $res = Hello::hello();
ok($res, "Hello from PAR returned true");
delete $INC{'Hello.pm'};

%PAR::PAR_INC = %PAR::PAR_INC = ();
@PAR::PAR_INC = @PAR::PAR_INC = ();
@PAR::PAR_INC_LATE = @PAR::PAR_INC_LATE = ();

eval "use PAR { file => '$par', fallback => 1 };";
warn $@ if $@;
ok(!$@, "use PAR {file=>...,fallback=>1} threw error");

undef *Hello::hello;
require Hello;

$res = Hello::hello();
ok(!$res, "Hello from filesys returned false");

ok(eval("require Data; 1;"), 'fallback works');

print PAR->import({run => 'hello', file => $par});

ok(0, 'should not be reached if hello from par file is executed!');
