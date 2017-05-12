use strict;
use warnings;

use Test::More;

use Symbol::Alias 'is' => 'is2', '&ok' => 'ok2';

is2('a', 'a', "aliased is");
ok2(1, "aliased ok");

is('a', 'a', "kept is");
ok(1, "kept ok");

my $file = __FILE__;
my $line = __LINE__ + 1;
ok(!eval { Symbol::Alias->import('ok' => 'ok2') }, "Exception");
like($@, qr/Symbol &main::ok2 already exists at \Q$file\E line $line/, "got useful exception");

done_testing;
