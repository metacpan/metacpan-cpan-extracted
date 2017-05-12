#
# Test for Devel::Cover issue #152
# https://github.com/pjcj/Devel--Cover/issues/152
#
use strict;
use warnings;

use Term::Chrome qw< Red Bold >;

print <<EOF;
1..1
# perl $^V
# Term::Chrome $Term::Chrome::VERSION $INC{'Term/Chrome.pm'}
EOF

my $c = undef || Red;   # <---- failure here
$c = undef || (Red+Bold);
my ($undef, %undef);
my $e = $undef || Red;
my $f = $undef || (Red+Bold);
my $g = $undef{'foo'} || Red;
my $h = $undef{'foo'} || (Red + Bold);

my $undef_hash = {};
my $i = $undef_hash->{'foo'} || (Red + Bold);

print "ok 1\n";
