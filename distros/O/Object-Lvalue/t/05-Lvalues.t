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
my @attrz
= qw
(
    fee
    fie
    foe
    fum
);

my @valz
= map
{
    rand
}
@attrz;

my %expectz
= map
{
    @$_
}
zip \@attrz, \@valz;

use_ok $madness => @attrz
or BAIL_OUT "$madness is useless";

can_ok $madness => $method
or BAIL_OUT "$madness lacks any $method";

my $testy   = __PACKAGE__->$method;

while( my ( $attr, $expect ) = each %expectz )
{
    $testy->$attr   = $expect;
    my $found       = $testy->$attr;

    ok $found == $expect, "Stored $attr == $found ($expect)";
}

done_testing
__END__
