use Test::Most;

use Pod::Knit;

my $knit = Pod::Knit->new(
    config => { plugins => [
        'Abstract', 'Authors', 'Legal', 'NamedSections', 'Version',
        'Attributes', 'Methods', 'Sort',
    ] },
);

my $doc = $knit->munge_document( content => join '', <DATA> );

pass;

done_testing;


__DATA__

package Foo;
# ABSTRACT: stuff

=method stuff

