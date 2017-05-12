use Test::More tests => 1;
use FindBin;
use Template;

ok( get_album() eq 'album_name', 'Fetch ALBUM from MP3' );

sub get_album {
    my $tt = Template->new();

    my $output = '';
    my $vars = {
        mp3_file => 't/test.mp3'
    };

    $tt->process( 't/template/album.tt', $vars, \$output );

    return $output;
}