use strict;
use warnings;

package Thing;
use Noose;
sub exclaim {
    my $self = shift;
    die 'BLARGH' unless $self->a == 1;
    print "yepyepyep\n";
}

package main;
use Test::More tests => 8;

my $thing = Thing->new( a => 0 );
can_ok $thing, qw/new exclaim a/;
is $thing->a => 0, 'thing->a is 0';

my $new   = $thing->new( a => 2, b => $thing->a );
can_ok $new, qw/new exclaim a b/;
is $new->a => 2, 'new overrode thing->a';
is $new->b => 0, 'new added ->b from thing->a';

my $clone = $new->new();
can_ok $clone, qw/new exclaim a b/;
is $clone->a => $new->a, 'clone got value for ->a from new';
is $clone->b => $new->b, 'clone got value for ->b from new';
