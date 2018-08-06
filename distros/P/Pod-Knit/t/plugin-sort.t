
use strict;
use warnings;

use Test::Most;

use Pod::Knit;

my $knit = Pod::Knit->new(
    config => {
        plugins => [
            { Sort => { order => [
                qw/ NAME SYNOPSIS DESCRIPTION *  AUTHOR /
            ] } },
        ],
    },
);

my $doc = $knit->munge_document( content => <<'END' =~ s/^    //rmg );
    =head1 AUTHOR

    yanick

    =head1 WHATEVER

    foo

    =head1 DESCRIPTION

    yadah

    =head1 SYNOPSIS

    blah

    =head1  NAME

    Heh
END

like $doc->as_pod => qr/NAME.*SYNOPSIS.*DESCRIPTION.*WHATEVER.*AUTHOR/s;

done_testing;

