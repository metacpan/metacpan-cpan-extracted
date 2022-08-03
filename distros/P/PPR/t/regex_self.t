use strict;
use warnings;
use utf8;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 1;

use PPR;

if (open my $src_fh, '<', $INC{'PPR.pm'}) {
    my $src_code = do { local $/; readline $src_fh; };

    ok $src_code
        =~ m{ (?&PerlEntireDocument)  $PPR::GRAMMAR }xms
            => 'Matched own source';
}
else {
    fail "Can't open PPR source file: $!";
}

done_testing();

