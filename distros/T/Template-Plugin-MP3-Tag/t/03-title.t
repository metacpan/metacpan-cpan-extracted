use Test::More tests => 1;
use FindBin;
use Template;

ok( get_title() eq 'title_name', 'Fetch TITLE from MP3' );

sub get_title {
    my $tt = Template->new();

    my $output = '';
    my $vars = {
        mp3_file => 't/test.mp3'
    };

    $tt->process( 't/template/title.tt', $vars, \$output );

    return $output;
}