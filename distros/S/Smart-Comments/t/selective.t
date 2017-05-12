use Smart::Comments '###', '####', '######';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

### ok 1 - Accepts 3 #'s...
#### ok 2 - Accepts 4 #'s...
##### not ok 3 - Shouldn't accept 5 #'s...
###### ok 3 - Accepts 6 #'s...

$STDERR =~ s/^###\s*//gm;
$STDERR =~ s/^\s*\n//gxms;

print "1..3\n", $STDERR;
