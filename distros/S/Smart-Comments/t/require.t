use Smart::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $x = 0;
### require: $x < 1

ok length $STDERR == 0           => 'True require is silent';

$ASSERTION = << 'END_ASSERT';

# $x < 0 was not true at FILE line 22.
#     $x was: 0
END_ASSERT

$ASSERTION =~ s/#/###/g;

eval {
### require: $x < 0
};

ok $@                            => 'False require is deadly';
ok $@ eq "\n"                    => 'False require is deadly silent';

$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False require is loud';
is $STDERR, $ASSERTION           => 'False require is loudly correct';

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
### require: $y < $x
};

ok $@                            => 'False two-part require is deadly';
ok $@ eq "\n"                    => 'False two-part require is deadly silent';

$STDERR =~ s/ at \S+ line / at FILE line /;

ok length $STDERR != 0           => 'False two-part require is loud';
is $STDERR, $ASSERTION2          => 'False two-part require is loudly correct';
