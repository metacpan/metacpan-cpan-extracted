use Test::More tests => 1;
use FindBin;
use Template;

ok( get_artist() eq 'artist_name', 'Fetch AIRTSR from MP3' );

sub get_artist {
    my $tt = Template->new();

    my $output = '';
    my $vars = {
        mp3_file => 't/test.mp3'
    };

    $tt->process( 't/template/artist.tt', $vars, \$output );

    return $output;
}