########################################################################
# housekeeping
########################################################################
package Testify;
use v5.34;
use FindBin::libs;

use Test::More;

use List::Util  qw( zip );

my $madness = 'Object::Lvalue';
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
zip \@attrz, [ map { 2 * $_ } @valz ];

sub initialize
{
$DB::single = 1;

    my $testy   = shift;
    
    $testy->$_  = 2 * shift 
    for @attrz;
}

use_ok $madness => @attrz
or BAIL_OUT "$madness is useless";

my $testy   = __PACKAGE__->new( @valz );

while( my( $attr, $expect ) = each %expectz )
{
    my $found   = $testy->$attr;

    ok $found == $expect, "Found $attr = $found ($expect)";
}

done_testing
__END__
