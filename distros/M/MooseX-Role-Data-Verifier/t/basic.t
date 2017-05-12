use Test::More;
use lib 't/lib';

use DVTest;

my $test = DVTest->new(name => 'Foo');

my $prof = $test->get_verifier_profile;

is_deeply($prof, { name => { required => 1, type => 'Str' }, mysterious => { required => 0 } }, 'simple required string');

done_testing;