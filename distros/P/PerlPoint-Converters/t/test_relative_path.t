
# Test of relative_path function

use strict;

use lib "./t";
use PerlPoint::Converters qw(relative_path);

use Test::Simple tests => 10;


#UNIX like filenames:
ok(relative_path( "/this/is/my/test/foo", "/this/is/my/test/foo") 
    eq ".", "UNIX same dir");
ok(relative_path( "C:/this/is/my/test/foo", "C:/this/is/my/foo/google/xy") 
    eq "../../foo/google/xy", "UNIX relative1");
ok(relative_path( "/this/is/my/test/foo//bar/bonny", "/this/is/my/foo/google/xy") 
    eq "../../../../foo/google/xy", "UNIX relative2");
ok(relative_path( "/this/is/my/test/foo//bar/bonny", "/this/is/my/test/foo/bar/") 
    eq "..", "UNIX one above");
ok(relative_path( "./../my/test/foo//bar/bonny", "./../my/test/foo/bar/google/tee") 
    eq "../google/tee", "UNIX rel rel");

#DOS like filenames:
ok(relative_path( "T:/this/is/my\\\\test/foo", "T:\\this/is/my/test/foo") 
    eq ".", "DOS same dir");
ok(relative_path( "C:/this/is/my/test/foo", "C:/this/is/my/foo/google/xy") 
    eq "../../foo/google/xy", "DOS relative1");
ok(relative_path( "D:\\this\\is\\my/test/foo//bar/bonny", "D:/this/is/my/foo/google/xy") 
    eq "../../../../foo/google/xy", "DOS relative2");
ok(relative_path( "X:/this/is/my/test/foo//bar/bonny", "X:/this/is/my/test/foo/bar") 
    eq "..", "DOS one above");
ok(relative_path( ".\\..\\my\\test\\\\foo//bar/bonny", "./..\\\\my/test\\foo\\bar\\google\\tee") 
    eq "../google/tee", "DOS rel rel");


