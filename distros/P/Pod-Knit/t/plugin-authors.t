use strict;
use warnings;

use Test::Most;

use Pod::Knit::Plugin::Authors;
use Pod::Knit::Document;

my $plugin = Pod::Knit::Plugin::Authors->new(
    authors => [ 'yanick' ],
);

my $doc = $plugin->munge( Pod::Knit::Document->new( content => '', ) );

like $doc->as_pod => qr/
    ^=head1 \s+ AUTHOR
    \s*
    yanick
    \s*
/xm;

done_testing;


