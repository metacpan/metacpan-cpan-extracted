use v5.26;
use strict;
use warnings;

use Test::More;

my $ok_say = eval <<'PERL';
    package Local::Prelude::No::Say;

    use Modern::Perl::Prelude;
    no Modern::Perl::Prelude;

    say 'hello';
    1;
PERL

ok(!$ok_say, 'say unavailable after no Modern::Perl::Prelude');

my $ok_fc = eval <<'PERL';
    package Local::Prelude::No::Fc;

    use Modern::Perl::Prelude;
    no Modern::Perl::Prelude;

    my $x = fc("Straße");
    1;
PERL

ok(!$ok_fc, 'fc unavailable after no Modern::Perl::Prelude');

my $ok_state = eval <<'PERL';
    package Local::Prelude::No::State;

    use Modern::Perl::Prelude;
    no Modern::Perl::Prelude;

    {
        state $v = 1;
    }

    1;
PERL

ok(!$ok_state, 'state unavailable after no Modern::Perl::Prelude');

done_testing;
