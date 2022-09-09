use strict;
use warnings;
use Test::More;

use PPR::X;
use re 'eval';
use warnings FATAL => 'regexp';

sub lives_ok(&;$) {
    if ($] >= 5.018 && $] <= 5.030) {
        pass "SKIP: $_[1]  (known regex bug in Perl $])";
        return;
    }

    eval { $_[0]->() };
    if (!$@) {
        pass $_[1];
    }
    else {
        fail "$_[1]: $@";
    }
}

my $define_block = q{
        (?(DEFINE)
            (?<MyRandomRule>
                random (?{ 1 })
            )
        )
};
my $g = $PPR::X::GRAMMAR;

lives_ok {
    qr/
        (?(DEFINE)
            (?<MyRandomRule>
                random (?{ 1 })
            )
        )

        $g
    /x;
} 'inline DEFINE + interpolated grammar inside of qr//';

lives_ok {
    qr/
        ${define_block}
        ${g}
    /x;
} 'interpolate DEFINE + interpolate grammar inside of qr';

lives_ok {
    my $whole = qq{
        ${define_block}
        ${g}
    };
    qr/ ${whole} /x;
} 'concatenate regex in string then interpolate inside of qr//';

done_testing;
