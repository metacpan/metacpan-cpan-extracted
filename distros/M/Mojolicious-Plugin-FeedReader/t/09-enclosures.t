use Mojo::Base -strict;

use Test::More;
use Mojo::File 'path';
use Mojolicious::Plugin::FeedReader;

use FindBin;

my %test_results = (
    'rss20-multi-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        },
        {
            'length' => '8888',
            'type'   => 'video/mpeg',
            'url'    => 'http://example.com/sample_movie.mpg'
        }
    ],
    'atom-multi-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        },
        {
            'length' => '8888',
            'type'   => 'video/mpeg',
            'url'    => 'http://example.com/sample_movie.mpg'
        }
    ],
    'atom-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        }
    ],
    'rss20-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        }
    ],
);

my $samples = path($FindBin::Bin)->child('samples');

my $reader = Mojolicious::Plugin::FeedReader->new;

while ( my ( $file, $result ) = each %test_results ) {
    my $feed = $reader->parse_rss( $samples->child($file) );
    is_deeply( $feed->{items}->[0]->{enclosures}, $result );
}

done_testing();
