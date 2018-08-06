use strict;
use warnings;

use Test::Most;

use Pod::Knit::Plugin::Legal;
use Pod::Knit::Document;

use Software::License::Artistic_2_0;

my $plugin = Pod::Knit::Plugin::Legal->new(
    license => Software::License::Artistic_2_0->new({ holder => 'yanick' }),
);

like $plugin->munge(
    Pod::Knit::Document->new( content => '' ) 
)->as_pod => qr/
    ^=head1 \s+ COPYRIGHT .* yanick
/xms;

done_testing;
