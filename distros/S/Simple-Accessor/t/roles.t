use warnings;

use Test::More tests => 4;
use FindBin;

use lib $FindBin::Bin. '/lib';

use_ok 'TestRole';

my $o = TestRole->new();
is $o->name, 'default-name';
is $o->age, 42, 'default age';
is $o->date, '20210102', 'default date';

1;
