#! perl

use strict;
use warnings;
use Test::More;
use Statistics::R;

my $R;

my $file = "file.ps";

ok $R = Statistics::R->new();

ok $R->startR();

ok $R->restartR();

ok $R->send(qq`postscript("$file" , horizontal=FALSE , width=500 , height=500 , pointsize=1)`);

ok $R->send( q`plot(c(1, 5, 10), type = "l")` );

ok $R->send( qq`x = 123 \n print(x)` );

my $ret = $R->read();
ok $ret =~ /^\[\d+\]\s+123\s*$/;

ok $R->send( qq`x = 456 \n print(x)` );

$ret = $R->read();
ok $ret =~ /^\[\d+\]\s+456\s*$/;

ok $R->lock;

ok $R->unlock;

is $R->is_blocked, 0;

is $R->is_locked, 0;

ok $R->clean_up();

ok $R->Rbin() =~ /\S+/;

ok $R->stopR();

is $R->error(), '';

ok $R->start_shared();

ok $R->start_sharedR();

ok $R->stop();

unlink $file;

done_testing;
