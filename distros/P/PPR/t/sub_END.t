use warnings;
use strict;

use Test::More;
plan tests => 3;

use PPR;

my $src = q{
    my $ __END__ = '__END__';

    sub __END__ {
        print $ __END__
    }
    & __END__
};

ok $src =~ m{ \A (?&PerlEntireDocument) \Z $PPR::GRAMMAR }xms => 'Matched sub __END__';

$src =~ s/__END__/__DATA__/g;
ok $src =~ m{ \A (?&PerlEntireDocument) \Z $PPR::GRAMMAR }xms => 'Matched sub __DATA__';

$src =~ s/__DATA_/__OTHER__/g;
ok $src =~ m{ \A (?&PerlEntireDocument) \Z $PPR::GRAMMAR }xms => 'Matched sub __OTHER__';

done_testing();

