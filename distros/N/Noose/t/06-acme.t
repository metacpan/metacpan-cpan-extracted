use strict;
use warnings;

package Thing;
use Acme::Noose;
sub exclaim {
    my $self = shift;
    die 'BLARGH' unless $self->a == 1;
    return "yepyepyep\n";
}

package main;
use Test::More tests => 4;

my $thing = new_ok Thing => [a => 1];
can_ok $thing, qw/ new exclaim a /;
is $thing->a => 1;
is $thing->exclaim => "yepyepyep\n";

