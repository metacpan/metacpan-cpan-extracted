use strict;
use warnings;

use Return::Set qw(set_return);
use Test::Most;

note('Test without schema - scalar');
is(set_return('hello'), 'hello', 'Returns scalar without schema');

note('Test without schema - arrayref');
my $array = [1, 2, 3];
is_deeply(set_return($array), $array, 'Returns arrayref without schema');

note('Test with scalar schema - valid');
is(set_return(123, { type => 'integer'}), 123, 'Passes scalar validation');

note('Test with arrayref schema - valid');
my $list = [ 'a', 'b' ];
is_deeply(set_return($list, { type => 'arrayref', min => 2, max => 2 }), $list, 'Passes ARRAYREF validation');

note('Test with hashref schema - valid');
my $hash = { foo => 1 };
is_deeply(set_return($hash, { type => 'hashref', min => 1, max => 1 }), $hash, 'Passes HASHREF validation');

note('Test with scalar schema - invalid');
throws_ok {
	set_return([], { type => 'integer' });
} qr/Validation failed/, 'Fails validation with wrong type (expected SCALAR)';

note('Test with coderef schema - valid');
my $code = sub { return 1 };
is(set_return($code, { type => 'coderef' }), $code, 'Passes CODEREF validation');

note('Test with no arguments');
throws_ok {
    set_return();
} qr/Usage/, 'Dies with too few arguments';

done_testing();
