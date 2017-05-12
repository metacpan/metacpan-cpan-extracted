use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use Obj;

my %attrs = (a => 1, b => 2, c => 3);
my $thing = Obj->new( %attrs );
isa_ok $thing, 'Obj';
can_ok $thing, keys %attrs;

foreach my $attr (keys %attrs) {
    is $thing->$attr, $attrs{$attr}, qq/\$thing->$attr is $attrs{$attr}/;
}

is $thing->a('a') => 'a', 'mutation works';
is $thing->a => 'a', 'access works';

done_testing;
