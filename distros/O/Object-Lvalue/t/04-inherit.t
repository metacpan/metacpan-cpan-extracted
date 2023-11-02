########################################################################
# housekeeping
########################################################################
package Testify;
use v5.34;
use FindBin::libs;

use Test::More;

use List::Util  qw( zip );

my $madness = 'Object::Lvalue';
my $method  = 'new';
my @attrz   = qw( fee fie foe fum );
my @inherit
= qw
(
    new
    construct
    initialize

    shallow
    clone

    DESTROY
    cleanup

    class_attr
    attributes

    verbose
);


use_ok $madness => @attrz
or BAIL_OUT "$madness is useless";

can_ok $madness => $method
or BAIL_OUT "$madness has no $method";

$madness->verbose   = 1;

my $testy   = __PACKAGE__->new;

isa_ok $testy, $madness;
can_ok $testy, $_ for @inherit;
can_ok $testy, $_ for @attrz;

done_testing
__END__
