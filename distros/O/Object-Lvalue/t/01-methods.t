########################################################################
# housekeeping
########################################################################
package Testify;
use v5.34;
use FindBin::libs;

use Test::More;

my $madness = 'Object::Lvalue';
my @methodz
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

require_ok $madness
or BAIL_OUT "$madness is useless";

for my $method ( @methodz )
{
    can_ok $madness => $method   
    or BAIL_OUT "$madness lacks any $method";
}

done_testing
__END__
