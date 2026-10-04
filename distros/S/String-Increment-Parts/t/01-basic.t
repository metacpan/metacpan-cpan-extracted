#!perl

use 5.010001;
use strict;
use warnings;

use Test::More 0.98;

use String::Increment::Parts qw(increment_string_parts);

subtest increment_string_parts => sub {
    subtest basic => sub {
        is(increment_string_parts(string=>"foo01bar2bBAZ009"), "foo01bar2bBAZ010");
        is(increment_string_parts(string=>"2z"), "2aa");
    };

    subtest "indexes argument" => sub {
        is(increment_string_parts(string=>"foo01bar2bBAZ009", indexes=>[0]), "fop01bar2bBAZ009");
    };

    subtest "all_indexes argument" => sub {
        is(increment_string_parts(string=>"foo-01bar.2bBAZ009", all_indexes=>1), "fop-02bas.3cBBA010");
    };

    subtest "inc argument" => sub {
        is(increment_string_parts(string=>"foo01bar2bBAZ009", inc=>2), "foo01bar2bBAZ011");
        is(increment_string_parts(string=>"foo01bar2bBAZ009", inc=>-3), "foo01bar2bBAZ006");
    };

    subtest "filename argument" => sub {
        is(increment_string_parts(string=>"foo1.mp3"),             "foo1.mp4");
        is(increment_string_parts(string=>"foo1.mp3",filename=>1), "foo2.mp3");
    };
};

DONE_TESTING:
done_testing;
