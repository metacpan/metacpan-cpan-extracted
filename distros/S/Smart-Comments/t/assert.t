use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $x = 0;
### assert: $x < '1'

ok length $STDERR == 0           => 'True assertion is silent';

$ASSERTION = << 'END_ASSERT';

# $x < 0 was not true at FILE line 22.
#     $x was: 0
END_ASSERT

$ASSERTION =~ s/#/###/g;

eval {
### assert: $x < 0
};

ok $@                            => 'False assertion is deadly';
ok $@ eq "\n"                    => 'False assertion is deadly silent';

$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False assertion is loud';
is $STDERR, $ASSERTION           => 'False assertion is loudly correct';

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
### assert: $y < $x
};

ok $@                            => 'False two-part assertion is deadly';
ok $@ eq "\n"                    => 'False two-part assertion is deadly silent';

$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False two-part assertion is loud';
is $STDERR, $ASSERTION2          => 'False two-part assertion is loudly correct';


