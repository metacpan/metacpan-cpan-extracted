use Test::More tests => 1;
use FindBin;
use Template;

ok( get_genre() eq 'Electronic', 'Fetch GENRE from MP3' );

sub get_genre {
    my $tt = Template->new();

    my $output = '';
    my $vars = {
        mp3_file => 't/test.mp3'
    };

    $tt->process( 't/template/genre.tt', $vars, \$output );

    return $output;
}