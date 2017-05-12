use Test::More tests => 4;
use FindBin;
use Template;

use_ok('Template');
use_ok('MP3::Tag');
ok( -e 't/test.mp3', 'MP3 file exist' );
ok( -e 't/template/artist.tt', 'Template File exist' );
