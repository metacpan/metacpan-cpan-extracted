#!/usr/bin/perl

use Test::More tests => 4;
use Pod::From::GoogleWiki;

my $wiki = 'Plain URLs such as http://www.google.com/ or ftp://ftp.kernel.org/ are automatically made into links.';

my $pod = 'Plain URLs such as L<http://www.google.com/> or L<ftp://ftp.kernel.org/> are automatically made into links.';

my $pfg = Pod::From::GoogleWiki->new();
my $ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'automatically link OK');

$wiki = 'You can also provide some descriptive text. For example, the following link points to the [http://www.google.com Google home page].';
$pod = 'You can also provide some descriptive text. For example, the following link points to the L<http://www.google.com|Google home page>.';
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'descriptive text link OK');

$wiki = <<'WIKI';
If your link points to an image, it will get inserted as an image tag into the page:

http://code.google.com/images/code_sm.png
WIKI
$pod = <<'POD';
If your link points to an image, it will get inserted as an image tag into the page:

=begin html

<img src='http://code.google.com/images/code_sm.png' />

=end html
POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'img link OK');

$wiki = <<'WIKI';
You can also make the image into a link, by setting the image URL as the description of the URL you want to link:

[http://code.google.com/ http://code.google.com/images/code_sm.png]
WIKI
$pod = <<'POD';
You can also make the image into a link, by setting the image URL as the description of the URL you want to link:

=begin html

<a href='http://code.google.com/'><img src='http://code.google.com/images/code_sm.png' /></a>

=end html
POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'img link with text OK');