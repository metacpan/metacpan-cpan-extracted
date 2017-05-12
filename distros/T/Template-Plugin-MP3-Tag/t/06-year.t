use Test::More tests => 1;
use FindBin;
use Template;

ok( get_year() eq '2006.04.01', 'Fetch YEAR from MP3' );

sub get_year {
    my $tt = Template->new();

    my $output = '';
    my $vars = {
        mp3_file => 't/test.mp3'
    };

    $tt->process( 't/template/year.tt', $vars, \$output );

    return $output;
}