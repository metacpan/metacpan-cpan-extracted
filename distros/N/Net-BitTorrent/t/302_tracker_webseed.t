use v5.42;
use lib 'lib';
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent::Tracker::WebSeed;
use HTTP::Tiny;
use Path::Tiny;
subtest 'WebSeed Fetch (Segments)' => sub {
    my $ws = Net::BitTorrent::Tracker::WebSeed->new( url => 'http://example.com/data/' );

    # Mock file object
    my $file = bless { p => path('/tmp/test.bin') }, 'MockFile';
    {

        package MockFile;
        sub path { shift->{p} }
    }
    my $mock = mock 'HTTP::Tiny' => (
        override => [
            get => sub {
                my ( $self, $url, $args ) = @_;
                is $url,                    'http://example.com/data/test.bin', 'Appended relative path to directory URL';
                is $args->{headers}{Range}, 'bytes=100-199',                    'Correct Range header sent';
                return { success => 1, content => 'W' x 100 };
            },
        ],
    );
    my $data = $ws->fetch_piece( [ { file => $file, offset => 100, length => 100, rel_path => 'test.bin' } ] );
    is length($data), 100,       'Fetched correct length';
    is $data,         'W' x 100, 'Fetched correct data';
};
subtest 'WebSeed Legacy Support' => sub {
    my $ws   = Net::BitTorrent::Tracker::WebSeed->new( url => 'http://example.com/file.iso' );
    my $mock = mock 'HTTP::Tiny' => (
        override => [
            get => sub {
                my ( $self, $url, $args ) = @_;
                is $url,                    'http://example.com/file.iso', 'URL preserved for non-directory';
                is $args->{headers}{Range}, 'bytes=0-16383',               'Correct Range header sent';
                return { success => 1, content => 'L' x 16384 };
            },
        ],
    );
    my $data = $ws->fetch_piece_legacy( 0, 16384, 1024 * 1024 );
    is length($data), 16384, 'Fetched correct length';
};
done_testing;
