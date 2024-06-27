use v5.22;
use warnings;


use Test::More;
use lib qw< t/tlib tlib >;

plan tests => 4;

use Multi::Dispatch;

multi func ('L')  { return 'local' }
multi func :from(Func);
multi func ('O')  { return 'local override' }
multi func :from(&Func::other);

is func('L'), 'local'           => 'local';
is func('I'), 'import'          => 'import';
is func('O'), 'import override' => 'import override';
is func('N'), 'rename'          => 'rename';

done_testing();

