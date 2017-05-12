use strict;
use Test::More 'no_plan';

unlike('foo', qr/f o o/);

use Regexp::DefaultFlags;
like('foo', qr/f o o/);
unlike('foo', qr/F O O/);

use Regexp::DefaultFlags '/ix';
like('foo', qr/f o o/);

eval { Regexp::DefaultFlags->import('/yow') };
like($@, qr/Unknown\ regular\ expression\ flag:\ yow/);

1;
