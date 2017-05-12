use Smart::Comments;
use Test::More 'no_plan';




close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $x = 0;
### verify: $x < 1

ok length $STDERR == 0           => 'True verify is silent';

$ASSERTION = << 'END_ASSERT';

# $x < 0 was not true at FILE line 26.
#     $x was: 0

END_ASSERT

$ASSERTION =~ s/#/###/g;

eval {
### verify: $x < 0
};

ok !$@                           => 'False verify not deadly';


$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False verify is loud';
is $STDERR, $ASSERTION           => 'False verify is loudly correct';

close *STDERR;
$STDERR = q{};
open *STDERR, '>', \$STDERR;

my $y = [];
   $x = 10;

my $ASSERTION2 = << 'END_ASSERTION2';

# $y < $x was not true at FILE line 55.
#     $y was: []
#     $x was: 10

END_ASSERTION2

$ASSERTION2 =~ s/#/###/g;

eval {
### verify: $y < $x
};

ok !$@                           => 'False two-part verify not deadly';


$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False two-part verify is loud';
is $STDERR, $ASSERTION2          => 'False two-part verify is loudly correct';
