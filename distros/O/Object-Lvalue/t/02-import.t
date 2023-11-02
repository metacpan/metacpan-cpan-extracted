########################################################################
# housekeeping
########################################################################
package Testify;
use v5.34;
use FindBin::libs;

use Test::More;

use List::Util  qw( zip );

my $madness = 'Object::Lvalue';
my $method  = 'import';
my @attrz   = qw( fee fie foe fum );

require_ok $madness
or BAIL_OUT "$madness is useless";

$madness->verbose   = 1;
$madness->$method( @attrz );

isa_ok __PACKAGE__, $madness;
can_ok __PACKAGE__, $_ for @attrz;

is_deeply scalar __PACKAGE__->$_, \@attrz, "Found $_"
for qw( class_attr attributes);

done_testing
__END__
