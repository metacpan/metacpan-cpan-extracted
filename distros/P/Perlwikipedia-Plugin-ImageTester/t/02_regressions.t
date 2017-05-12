# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Perlwikipedia.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN{push @INC, "./lib"}

use Test::More tests => 1;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use Perlwikipedia;

$wikipedia=Perlwikipedia->new ("");

$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
Ang Tanging Ina N'yong Lahat Movie Poster

==Licensing==
{{Non-free promotional|image_has_rationale=yes}}

===Fair use rationale===
*No free or public domain images have been located for this film.
*Image is a promotional photograph, intended for wide distribution as publicity for the film.
*Image is of considerably lower resolution than the original, and is used for informational purposes only.  Its use does not detract from either the original photograph, or from the film itself.
*It does not limit the copyright owner's rights to market or sell the work in any way.
*This image is used on various websites, so its use on Wikipedia does not make it significantly more accessible or visible than it already is.

== Licensing: ==
{{Non-free poster}}
", undef, "Ang Tanging Ina N'yong Lahat");
is($res, 0, "Regression test #1");

#$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "");
#is($res, 2, "Parser test #");
