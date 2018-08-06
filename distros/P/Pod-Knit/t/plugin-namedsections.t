use strict;
use warnings;

use Test::Most;

use Pod::Knit;

my $knit = Pod::Knit->new(
    config => {
        plugins => [
            { NamedSections => { sections => [qw/
                synopsis description
            /] } },
        ],
    },
);

my $doc = $knit->munge_document( content => <<'END' =~ s/^    //rmg );
    =synopsis

    blah

    =description quux
END

my $pod = $doc->as_pod;

like $pod => qr/^=head1 SYNOPSIS/m;
like $pod => qr/^=head1 quux/m;

done_testing;

