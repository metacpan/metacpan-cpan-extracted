use v5.12.0;
use warnings;

use Test::More tests => 3;
use SVN::Rami qw/ convert_branches_to_filesystem_paths /;

# Test in scalar context.
like( SVN::Rami::convert_branches_to_filesystem_paths('foo'), qr/.work.foo$/, 'Failed to convert branch foo' );

# Test in list context.
my @result = SVN::Rami::convert_branches_to_filesystem_paths('abc', 'xyz');
like( $result[0], qr/.work.abc$/, 'Failed to convert branch abc' );
like( $result[1], qr/.work.xyz$/, 'Failed to convert branch xyz' );

done_testing();