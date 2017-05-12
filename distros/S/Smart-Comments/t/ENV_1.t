BEGIN { $ENV{Smart_Comments} = 1; }

use Smart::Comments -ENV;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

### Testing 1...
### Testing 2...

### Testing 3...

my $expected = <<"END_MESSAGES";

#\## Testing 1...
#\## Testing 2...

#\## Testing 3...
END_MESSAGES

is $STDERR, $expected      => 'Messages work';
