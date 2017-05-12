# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Perlwikipedia.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN{push @INC, "./lib"}

use Test::More tests => 6;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use Perlwikipedia;

$wikipedia=Perlwikipedia->new ("");

$number++;
$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Information
|Description=A mosque in Haifa
|Source=I created this work entirely by myself.
|Date=
|Author=[[User:Fipplet|Fipplet]] ([[User talk:Fipplet|talk]])
|other_versions=
}}");
is($res, 1, "Parser test #$number - free image without a tag");

$number++;
$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Information
|Description=A mosque in Haifa
|Source=I created this work entirely by myself.
|Date=
|Author=[[User:Fipplet|Fipplet]] ([[User talk:Fipplet|talk]])
|other_versions=
}}

{{GFDL}}");
is($res, -1, "Parser test #$number - free image with a tag");

$number++;
$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
Logo for [[Metro Transit (Halifax)]]'s MetroLink service.
== Licensing ==
{{Non-free logo}}

{{svg|fairuse}}");
is($res, 2, "Parser test #$number - nonfree svg no rationale");

$number++;
$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "== Summary ==
Logo for [[Metro Transit (Halifax)]]'s MetroLink service.
== Licensing ==
{{Non-free logo}}
{{Non-free use rationale
| Description       = Halifax Regional Municipality's Metro Transit's MetroLink Logo.
| Source            = Wikipedia Image MetroLink-Halifax.png
| Article           = Metro Transit (Halifax)
| Portion           = Whole
| Low_resolution    = Yes
| Purpose           = As an icon on the Metro Transit (Halifax) Article
| Replaceability    = This is the only logo available any replicas or edits would be inaccurate.
| other_information = 
}}", undef, "Metro Transit (Halifax)");
is($res, 0, "Parser test #$number - nonfree svg with valid rationale");

$number++;
$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Information
|Description=Oakland Mormon Temple at Christmas
|Source=fizbin's crappy camera.
|Date=12-27-08
|Author=[[User:Fizbin|Fizbin]] ([[User talk:Fizbin|talk]])
|other_versions=
}}");
is($res, 1, "Parser test #$number");

$number++;
$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "{{Information
|Description=Oakland Mormon Temple at Christmas
|Source=fizbin's crappy camera.
|Date=12-26-08
|Author=[[User:Fizbin|Fizbin]] ([[User talk:Fizbin|talk]])
|other_versions=
}}

== Licensing ==
{{PD-self}}");
is($res, -1, "Parser test #$number");

#$number++;
#$res=$wikipedia->checkimage("File:Sample.jpg", "User:Test", undef, "");
#is($res, 2, "Parser test #$number");
