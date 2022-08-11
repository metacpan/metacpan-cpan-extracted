#!perl

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use String::Wildcard::Bash qw(
                                 $RE_WILDCARD_BASH
                                 contains_wildcard
                                 contains_brace_wildcard
                                 contains_class_wildcard
                                 contains_joker_wildcard
                                 contains_qmark_wildcard
                                 contains_glob_wildcard
                                 contains_globstar_wildcard
                                 convert_wildcard_to_sql
                                 convert_wildcard_to_re
                         );

subtest contains_wildcard => sub {
    subtest "none" => sub {
        ok(!contains_wildcard(""));
        ok(!contains_wildcard("abc"));
    };

    subtest "*" => sub {
        ok( contains_wildcard("ab*"));
        ok(!contains_wildcard("ab\\*"));
        ok( contains_wildcard("ab\\\\*"));
    };

    subtest "?" => sub {
        ok( contains_wildcard("ab?"));
        ok(!contains_wildcard("ab\\?"));
        ok( contains_wildcard("ab\\\\?"));
    };

    subtest "character class" => sub {
        ok( contains_wildcard("ab[cd]"));
        ok(!contains_wildcard("ab[cd"));
        ok(!contains_wildcard("abcd]"));
        ok(!contains_wildcard("ab\\[cd]"));
        ok( contains_wildcard("ab\\\\[cd]"));
        ok(!contains_wildcard("ab[cd\\]"));
        ok( contains_wildcard("ab[cd\\\\]"));
    };

    subtest "brace expansion" => sub {
        ok(!contains_wildcard("{}"));    # need at least a comma
        ok(!contains_wildcard("{a}"));   # ditto
        ok(!contains_wildcard("{a*}"));  # ditto
        ok(!contains_wildcard("{a?}"));  # ditto
        ok(!contains_wildcard("{[a]}")); # ditto
        ok(!contains_wildcard("{a\\,b}")); # ditto
        ok( contains_wildcard("{,}"));
        ok( contains_wildcard("{a,}"));
        ok( contains_wildcard("{a*,}"));
        ok( contains_wildcard("{a?,}"));
        ok( contains_wildcard("{[a],}"));
        ok( contains_wildcard("{a*,b}"));
        ok( contains_wildcard("{a,b[a]}"));
        ok( contains_wildcard("{a\\,b,c}"));

        ok(!contains_wildcard("\\{a,b}"));
        ok( contains_wildcard("\\{a*,b}")); # because * is not inside brace
        ok( contains_wildcard("\\{a?,b}")); # ditto
        ok( contains_wildcard("\\{[a],}")); # ditto
        ok( contains_wildcard("\\\\{a,}"));
        ok(!contains_wildcard("{a,b\\}"));
        ok( contains_wildcard("{a*,b\\}"));  # because * is not inside brace
        ok( contains_wildcard("{a?,b\\}"));  # ditto
        ok( contains_wildcard("{[a],b\\}")); # ditto
        ok( contains_wildcard("{a,b\\\\}"));
    };

    subtest "other non-wildcard" => sub {
        ok(!contains_wildcard("~/a"));
        ok(!contains_wildcard("\$a"));
    };

    subtest "sql" => sub {
        ok(!contains_wildcard("a%"));
        ok(!contains_wildcard("a_"));
    };
};

subtest contains_brace_wildcard => sub {
    ok(!contains_brace_wildcard("abc"));
    ok(!contains_brace_wildcard("ab*"));
    ok(!contains_brace_wildcard("ab**"));
    ok(!contains_brace_wildcard("ab?"));
    ok(!contains_brace_wildcard("ab[cd]"));
    ok( contains_brace_wildcard("{a*,b}"));
};

subtest contains_class_wildcard => sub {
    ok(!contains_class_wildcard("abc"));
    ok(!contains_class_wildcard("ab*"));
    ok(!contains_class_wildcard("ab**"));
    ok(!contains_class_wildcard("ab?"));
    ok( contains_class_wildcard("ab[cd]"));
    ok(!contains_class_wildcard("{a*,b}"));
};

subtest contains_qmark_wildcard => sub {
    ok(!contains_qmark_wildcard("abc"));
    ok(!contains_qmark_wildcard("ab*"));
    ok(!contains_qmark_wildcard("ab**"));
    ok( contains_qmark_wildcard("ab?"));
    ok(!contains_qmark_wildcard("ab[cd]"));
    ok(!contains_qmark_wildcard("{a*,b}"));
};

subtest contains_glob_wildcard => sub {
    ok(!contains_glob_wildcard("abc"));
    ok( contains_glob_wildcard("ab*"));
    ok(!contains_glob_wildcard("ab**"));
    ok(!contains_glob_wildcard("ab?"));
    ok(!contains_glob_wildcard("ab[cd]"));
    ok(!contains_glob_wildcard("{a*,b}"));
};

subtest contains_globstar_wildcard => sub {
    ok(!contains_globstar_wildcard("abc"));
    ok(!contains_globstar_wildcard("ab*"));
    ok( contains_globstar_wildcard("ab**"));
    ok(!contains_globstar_wildcard("ab?"));
    ok(!contains_globstar_wildcard("ab[cd]"));
    ok(!contains_globstar_wildcard("{a*,b}"));
};

subtest convert_wildcard_to_sql => sub {
    is(convert_wildcard_to_sql('a*'), 'a%');
    is(convert_wildcard_to_sql('a**b'), 'a%b');
    is(convert_wildcard_to_sql('a*b*'), 'a%b%');
    is(convert_wildcard_to_sql('a\\*'), 'a\\*');
    is(convert_wildcard_to_sql('a?'), 'a_');
    is(convert_wildcard_to_sql('a??'), 'a__');
    is(convert_wildcard_to_sql('a\\?'), 'a\\?');
    is(convert_wildcard_to_sql('a%'), 'a\\%');
    is(convert_wildcard_to_sql('a\\%'), 'a\\%');
    is(convert_wildcard_to_sql('a_'), 'a\\_');
    is(convert_wildcard_to_sql('a\\_'), 'a\\_');
    is(convert_wildcard_to_sql('a\\{b,c}'), 'a\\{b,c}'); # brace literal

    # passed as-is
    dies_ok { convert_wildcard_to_sql('a[b]') }; # class
    dies_ok { convert_wildcard_to_sql('a{b}') }; # brace literal single element
    dies_ok { convert_wildcard_to_sql('a{b,c}') }; # brace
};

subtest convert_wildcard_to_re => sub {
    # brace
    is(convert_wildcard_to_re('{a}'), "\\{a\\}");
    is(convert_wildcard_to_re('f.{a.,b*}'), "f\\.(?:a\\.|b[^/]*)");

    # charclass
    is(convert_wildcard_to_re('[abc-j]'), "[abc-j]");

    # bash joker
    is(convert_wildcard_to_re('a?foo*'), "a.foo[^/]*");

    # sql joker
    is(convert_wildcard_to_re('a%'), "a\\%");

    subtest "opt:brace=0" => sub {
        is(convert_wildcard_to_re({brace=>0}, '{a,b}'), "\\{a\\,b\\}");
    };
    subtest "opt:dotglob=0" => sub {
        # we'll just test how the regex works
        #is(convert_wildcard_to_re({}, '*a*'), "[^/.][^/]*a[^/]*");
        #is(convert_wildcard_to_re({}, '.*'), "\\.[^/]*");

        my $re;

        subtest "matching with *" => sub {
            $re = convert_wildcard_to_re("*"); $re = qr/\A$re\z/;
            ok(""      !~ $re); # this is an implementaiton artefact, it should match?

            ok("a"     =~ $re);
            ok("aaa"   =~ $re);
            ok("a.aa"  =~ $re);
            ok(".a"    !~ $re);
            ok(".aaa"  !~ $re);

            ok("a/b"   !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with .*" => sub {
            $re = convert_wildcard_to_re(".*"); $re = qr/\A$re\z/;
            ok("a"     !~ $re);
            ok("aaa"   !~ $re);
            ok("a.aa"  !~ $re);
            ok(".a"    =~ $re);
            ok(".aaa"  =~ $re);

            ok("a/b"   !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with */*" => sub {
            $re = convert_wildcard_to_re("*/*"); $re = qr/\A$re\z/;
            ok("a"     !~ $re);
            ok("aaa"   !~ $re);
            ok("a.aa"  !~ $re);
            ok(".a"    !~ $re);
            ok(".aaa"  !~ $re);

            ok("a/b"   =~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with .*/*" => sub {
            $re = convert_wildcard_to_re(".*/*"); $re = qr/\A$re\z/;
            ok("a/b"   !~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  =~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with */.*" => sub {
            $re = convert_wildcard_to_re("*/.*"); $re = qr/\A$re\z/;
            ok("a/b"   !~ $re);
            ok("a/.b"  =~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with .*/.*" => sub {
            $re = convert_wildcard_to_re(".*/.*"); $re = qr/\A$re\z/;
            ok("a/b"   !~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" =~ $re);
        };
    };

    subtest "opt:dotglob=1" => sub {
        # we'll just test how the regex works
        #is(convert_wildcard_to_re({dotglob=>1}, '*a*'), "[^/]*a[^/]*");
        #is(convert_wildcard_to_re({dotglob=>1}, '.*'), "\\.[^/]*");

        my $re;

        subtest "matching with *" => sub {
            $re = convert_wildcard_to_re({dotglob=>1}, "*"); $re = qr/\A$re\z/;
            ok(""      =~ $re); # this is as per-spec

            ok("a"     =~ $re);
            ok("aaa"   =~ $re);
            ok("a.aa"  =~ $re);
            ok(".a"    =~ $re);
            ok(".aaa"  =~ $re);

            ok("a/b"   !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with .*" => sub {
            $re = convert_wildcard_to_re({dotglob=>1}, ".*"); $re = qr/\A$re\z/;
            ok("a"     !~ $re);
            ok("aaa"   !~ $re);
            ok("a.aa"  !~ $re);
            ok(".a"    =~ $re);
            ok(".aaa"  =~ $re);

            ok("a/b"   !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with */*" => sub {
            $re = convert_wildcard_to_re({dotglob=>1}, "*/*"); $re = qr/\A$re\z/;
            ok("a"     !~ $re);
            ok("aaa"   !~ $re);
            ok("a.aa"  !~ $re);
            ok(".a"    !~ $re);
            ok(".aaa"  !~ $re);

            ok("a/b"   =~ $re);
            ok("a/.b"  =~ $re);
            ok(".a/b"  =~ $re);
            ok(".a/.b" =~ $re);
        };

        subtest "matching with .*/*" => sub {
            $re = convert_wildcard_to_re({dotglob=>1}, ".*/*"); $re = qr/\A$re\z/;
            ok("a/b"   !~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  =~ $re);
            ok(".a/.b" =~ $re);
        };

        subtest "matching with */.*" => sub {
            $re = convert_wildcard_to_re({dotglob=>1}, "*/.*"); $re = qr/\A$re\z/;
            ok("a/b"   !~ $re);
            ok("a/.b"  =~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" =~ $re);
        };

        subtest "matching with .*/.*" => sub {
            $re = convert_wildcard_to_re({dotglob=>1}, ".*/.*"); $re = qr/\A$re\z/;
            ok("a/b"   !~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" =~ $re);
        };
    };

    subtest "opt:globstar=0" => sub {
        my $re;

        # without globstar set, ** should behave just like *
        subtest "matching with **" => sub {
            $re = convert_wildcard_to_re("**"); $re = qr/\A$re\z/;
            ok(""      !~ $re); # this is an implementaiton artefact, it should match?

            ok("a"     =~ $re);
            ok("aaa"   =~ $re);
            ok("a.aa"  =~ $re);
            ok(".a"    !~ $re);
            ok(".aaa"  !~ $re);

            ok("a/b"   !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with .**" => sub {
            $re = convert_wildcard_to_re(".**"); $re = qr/\A$re\z/;
            ok("a"     !~ $re);
            ok("aaa"   !~ $re);
            ok("a.aa"  !~ $re);
            ok(".a"    =~ $re);
            ok(".aaa"  =~ $re);

            ok("a/b"   !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };
    };

    subtest "opt:globstar=1" => sub {
        my $re;

        subtest "matching with **" => sub {
            $re = convert_wildcard_to_re({globstar=>1}, "**"); $re = qr/\A$re\z/;
            ok(""      !~ $re); # this is an implementaiton artefact, it should match?

            ok("a"     =~ $re);
            ok("aaa"   =~ $re);
            ok("a.aa"  =~ $re);
            ok(".a"    !~ $re);
            ok(".aaa"  !~ $re);

            ok("a/b"   =~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);
        };

        subtest "matching with ** and opt:dotglob" => sub {
            $re = convert_wildcard_to_re({globstar=>1, dotglob=>1}, "**"); $re = qr/\A$re\z/;
            ok(""      =~ $re); # as per-spe

            ok("a"     =~ $re);
            ok("aaa"   =~ $re);
            ok("a.aa"  =~ $re);
            ok(".a"    =~ $re);
            ok(".aaa"  =~ $re);

            ok("a/b"   =~ $re);
            ok("a/.b"  =~ $re);
            ok(".a/b"  =~ $re);
            ok(".a/.b" =~ $re);
        };

        subtest "matching with .** and opt:dotglob" => sub {
            $re = convert_wildcard_to_re({globstar=>1, dotglob=>1}, ".**"); note "re=$re"; $re = qr/\A$re\z/;
            ok("a"     !~ $re);
            ok("aaa"   !~ $re);
            ok("a.aa"  !~ $re);
            ok(".a"    =~ $re);
            ok(".aaa"  =~ $re);

            ok("a/b"   !~ $re);
            ok("a/.b"  !~ $re);
            ok(".a/b"  =~ $re);
            ok(".a/.b" =~ $re);
        };
    };

    subtest "opt:path_separator" => sub {
        my $re;

        subtest "matching with *" => sub {
            $re = convert_wildcard_to_re({path_separator=>":"}, "*"); $re = qr/\A$re\z/;
            ok("a/b"   =~ $re);
            ok("a/.b"  =~ $re);
            ok(".a/b"  !~ $re);
            ok(".a/.b" !~ $re);

            ok("a:b"   !~ $re);
            ok("a:.b"  !~ $re);
            ok(".a:b"  !~ $re);
            ok(".a:.b" !~ $re);
        };

        subtest "matching with *:*" => sub {
            $re = convert_wildcard_to_re({path_separator=>":"}, "*:*"); $re = qr/\A$re\z/;
            ok("a:b"   =~ $re);
            ok("a:.b"  !~ $re);
            ok(".a:b"  !~ $re);
            ok(".a:.b" !~ $re);
        };

        subtest "matching with **" => sub {
            $re = convert_wildcard_to_re({path_separator=>':', globstar=>1}, "**"); $re = qr/\A$re\z/;
            ok("a:b"   =~ $re);
            ok("a:.b"  !~ $re);
            ok(".a:b"  !~ $re);
            ok(".a:.b" !~ $re);
        };
    };
};

DONE_TESTING:
done_testing;
