use strict;
use warnings;

use Test::Most;
use Pod::Knit;

my $knit = Pod::Knit->new(
    config => {
        plugins => [
            'Methods'
        ]
    },
);

subtest 'no methods at all' => sub {

    my $doc = $knit->munge_document( content => <<'END' =~ s/^    //rmg );
        =synopsis

        blah

        =description quux
END

    my $pod = $doc->as_pod;

    unlike $pod => qr/METHODS/i, 'no methods, no section';

};

done_testing;
