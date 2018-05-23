use strict;
use Test::More;
use File::Temp;
use Pandoc::Release;

my $release = Pandoc::Release->get( '2.1.3' );
is $release->{name}, 'pandoc 2.1.3', 'get release';

my @releases = Pandoc::Release->list( since => '2.1' );
like $releases[0]->{name}, qr/^pandoc/i, 'list releases';
note $_ for map { $_->{tag_name} } @releases;

@releases = list( since => '9.0' );
is_deeply \@releases , [], 'no > 9.0 releases';

my @releases = list( range => '<=2.0.1, >1.19.2' );
is_deeply [ map {$_->{tag_name}} @releases ],
    [qw(2.0.1 2.0.0.1 2.0 1.19.2.1)], 'range releases';

like latest->{name}, qr{^pandoc}, 'latest';

done_testing;
