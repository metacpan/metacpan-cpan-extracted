use Test::More tests => 1;
use FindBin;
use Template;

ok( get_comment() eq 'comment', 'Fetch COMMENT from MP3' );

sub get_comment {
    my $tt = Template->new();

    my $output = '';
    my $vars = {
        mp3_file => 't/test.mp3'
    };

    $tt->process( 't/template/comment.tt', $vars, \$output );

    return $output;
}