#!/usr/bin/perl

use strict;
use Template;

my $t = Template->new;
$t->process(\*DATA) or die $t->error;

__DATA__
[%
    ntests = 6;
    file = "test.mp3";

    "1..$ntests\n";
    MACRO ok(one, two, num, desc) BLOCK;
        EQ = "==";
        IF (one != two);
            "not ";
            EQ = "!=";
        END;
        "ok $num # $desc ('$one' $EQ '$two')\n";
    END;

    TRY;
        USE mp3 = MP3(file);

        ok("USE MP3"     "USE MP3",                       1, "Load module");
        ok(mp3.title,    "Template Plugin MP3 Test Song", 2, "Title");
        ok(mp3.album,    "Template Plugin MP3",           3, "Album");
        ok(mp3.artist,   "DARREN@cpan.org",               4, "Artist");
        ok(mp3.comment,  "I like cake",                   5, "Comment");
        ok(mp3.year,     "2002",                          6, "Year");
    CATCH;
        FOREACH n = [ 1 .. ntests ];
            "skip $n # Error loading '$file' and/or Template::Plugin::MP3\n";
        END;
    END;

%]
