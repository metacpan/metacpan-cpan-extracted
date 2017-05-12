#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More 'no_plan';

use Smart::Comments;
use Smart::Comments::Log4perl;

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

### l4p_config: 't/complex.config'
### Testing 1...
#### Testing 2...
##### Testing 3...

# Build a regex to the filename, to maintain cross-platform compatability
#my $sc_subpath = File::Spec->catfile('t', '02-custom-logging.t');
my $sc_subpath = '02-custom-logging.t';

my $expected = qr{
                  \[\d+\] \s .*\Q$sc_subpath\E \s \d+ \s main \s \-                                 \s+
                  \[\d+\] \s .*\Q$sc_subpath\E \s \d+ \s main \s \- \s \#\#\# \s Testing \s 1\.\.\. \s+
                  \[\d+\] \s .*\Q$sc_subpath\E \s \d+ \s main \s \-                                 \s+
                  \[\d+\] \s .*\Q$sc_subpath\E \s \d+ \s main \s \- \s \#\#\# \s Testing \s 2\.\.\. \s+
                  \[\d+\] \s .*\Q$sc_subpath\E \s \d+ \s main \s \-                                 \s+
                  \[\d+\] \s .*\Q$sc_subpath\E \s \d+ \s main \s \- \s \#\#\# \s Testing \s 3\.\.\. \s+
                 }msx;

like $STDERR, $expected  => 'Custom configured logging messages work';

