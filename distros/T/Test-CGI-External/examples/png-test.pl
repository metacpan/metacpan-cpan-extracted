#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use Test::CGI::External;
use Image::PNG::Libpng ':all';
my $binary = "/home/ben/projects/kanjivg/www/memory.cgi";
my $tester = Test::CGI::External->new ();
$tester->set_cgi_executable ($binary);
my %apple;
$apple{REQUEST_METHOD} = 'GET';
$apple{QUERY_STRING} = 'o=apple-touch-icon-57x57.png';
$apple{REMOTE_ADDR} = '127.0.0.1';
$apple{png} = 1;
$tester->expect_mime_type ('image/png');
$tester->run (\%apple);
my $pngdata = $apple{pngdata};
SKIP: {
    if (! $pngdata) {
	skip 2, "no png data";
    }
    my $ihdr = get_IHDR ($pngdata);
    ok ($ihdr->{width} == 57, "width 57 as expected");
    ok ($ihdr->{height} == 57, "height 57 as expected");
}
done_testing ();
