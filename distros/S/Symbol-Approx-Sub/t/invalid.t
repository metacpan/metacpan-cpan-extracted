use strict;
use warnings;

use Test::More;
use Test::Exception;

require Symbol::Approx::Sub;

note('Invalid option');
throws_ok {
  Symbol::Approx::Sub->import(foo => 1);
} qr/^Invalid parameter/, 'Got the right exception';

note('Hashref transformer');
throws_ok {
  Symbol::Approx::Sub->import(xform => {});
} qr/^Invalid transformer/, 'Got the right exception';

note('Hashref transformer in an arrayref');
throws_ok {
  Symbol::Approx::Sub->import(xform => [{}]);
} qr/^Invalid transformer/, 'Got the right exception';

note('Hashref matcher');
throws_ok {
  Symbol::Approx::Sub->import(match => {});
} qr/^Invalid matcher/, 'Got the right exception';

note('Arrayref matcher');
throws_ok {
  Symbol::Approx::Sub->import(match => []);
} qr/^Invalid matcher/, 'Got the right exception';

note('Hashref chooser');
throws_ok {
  Symbol::Approx::Sub->import(choose => {});
} qr/^Invalid chooser/, 'Got the right exception';

note('Arrayref chooser');
throws_ok {
  Symbol::Approx::Sub->import(choose => []);
} qr/^Invalid chooser/, 'Got the right exception';

done_testing;
