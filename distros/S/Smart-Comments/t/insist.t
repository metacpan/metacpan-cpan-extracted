use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $x = 0;
### insist: $x < 1

ok length $STDERR == 0           => 'True insist is silent';

$ASSERTION = << 'END_ASSERT';

# $x < 0 was not true at FILE line 22.
#     $x was: 0
END_ASSERT

$ASSERTION =~ s/#/###/g;

eval {
### insist: $x < 0
};

ok $@                            => 'False insist is deadly';
ok $@ eq "\n"                    => 'False insist is deadly silent';

$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False insist is loud';
is $STDERR, $ASSERTION           => 'False insist is loudly correct';

close *STDERR;
$STDERR = q{};
open *STDERR, '>', \$STDERR;

my $y = [];
   $x = 10;

my $ASSERTION2 = << 'END_ASSERTION2';

# $y < $x was not true at FILE line 50.
#     $y was: []
#     $x was: 10
END_ASSERTION2

$ASSERTION2 =~ s/#/###/g;

eval {
### insist: $y < $x
};

ok $@                            => 'False two-part insist is deadly';
ok $@ eq "\n"                    => 'False two-part insist is deadly silent';

$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False two-part insist is loud';
is $STDERR, $ASSERTION2          => 'False two-part insist is loudly correct';
