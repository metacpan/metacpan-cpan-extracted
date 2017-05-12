BEGIN { delete $ENV{Smart_Comments}; }

use Smart::Comments -ENV;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

### Testing 1...
### Testing 2...
### Testing 3...

my $expected = q{};

is $STDERR, $expected      => 'Silenced messages work';
