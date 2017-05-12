use Test::More 'no_plan';
use Test::Deep;
use lib '../lib';
use NG;

my $s = new System;
isa $s, 'System';

System::local_run( 'w', sub {
    my ($out, $err) = @_;
    is $out->get(1), 'USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT';
});
