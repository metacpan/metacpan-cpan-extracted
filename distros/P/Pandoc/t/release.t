use strict;
use Test::More;
use File::Temp;
use Pandoc::Release;

plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};

my @releases = Pandoc::Release->list( since => '2.1' );
like $releases[0]->{name}, qr/^pandoc/i, 'fetch releases';
note $_ for map { $_->{tag_name} } @releases;

@releases = Pandoc::Release->list( since => '9.0' );
is_deeply \@releases , [], 'no > 9.0 releases';

done_testing;
