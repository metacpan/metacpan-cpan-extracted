use v5.24;
use Test::More;

my $madness = 'Object::Trampoline';

use_ok $madness;

ok $madness->can( 'VERSION' ), "$madness can VERSION";

ok $a = $madness->VERSION, "$madness has a \$VERSION";

note "Module version is: '$a'";

done_testing;

__END__
