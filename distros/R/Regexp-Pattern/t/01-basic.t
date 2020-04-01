#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Regexp::Pattern 're', 'Example::re1';

subtest "sub interface" => sub {
    dies_ok { re("Example::foo") } "get unknown -> dies";

    subtest "static" => sub {
        my $re1 = re("Example::re1");
        ok $re1;
        ok('123-456' =~ $re1);
        ok(' 123-456' =~ $re1);
        ok(!('foo' =~ $re1));
    };

    subtest "dynamic" => sub {
        my $re3a = re("Example::re3", variant => 'A');
        ok $re3a;
        ok('123-456' =~ $re3a);
        ok(!('foo' =~ $re3a));
        my $re3b = re("Example::re3", variant => 'B');
        ok $re3b;
        ok('123-45-67890' =~ $re3b);
        ok(!('123-456' =~ $re3b));
    };

    subtest "-anchor option" => sub {
        my $re1_anchor = re("Example::re1", -anchor=>1);
        ok $re1_anchor;
        ok(  '123-456'  =~ $re1_anchor);
        ok(!(' 123-456' =~ $re1_anchor));
        ok(!('123-456z' =~ $re1_anchor));

        my $re1_left = re("Example::re1", -anchor=>'left');
        ok $re1_left;
        ok(  '123-456'  =~ $re1_left);
        ok(!(' 123-456' =~ $re1_left));
        ok(  '123-456z' =~ $re1_left);

        my $re1_right = re("Example::re1", -anchor=>'right');
        ok $re1_right;
        ok(  '123-456'  =~ $re1_right);
        ok(  ' 123-456' =~ $re1_right);
        ok(!('123-456z' =~ $re1_right));
    };
};

subtest "hash interface" => sub {
    dies_ok { Regexp::Pattern->import("foo") } "invalid import 1";

    subtest "basic" => sub {
        %RE = ();
        Regexp::Pattern->import('Example::re1');
        is_deeply([sort keys %RE], [qw/re1/]);

        dies_ok { Regexp::Pattern->import('Example::foo bar') }
            "invalid import 2";

        # subsequent imports do not remove prior regexps
        Regexp::Pattern->import('Example::re2');
        is_deeply([sort keys %RE], [qw/re1 re2/]);

        Regexp::Pattern->import('Example::re3');
        ok('123-456' =~ $RE{re3});
        ok(!('foo' =~ $RE{re3}));

        Regexp::Pattern->import('Example::re3' => (variant=>"B"));
        is_deeply([sort keys %RE], [qw/re1 re2 re3/]);
        ok('123-45-67890' =~ $RE{re3});
        ok(!('123-456' =~ $RE{re3}));
    };

    subtest "wildcard" => sub {
        %RE = ();
        Regexp::Pattern->import('Example::*');
        is_deeply([sort keys %RE], [qw/re1 re2 re3 re4 re5/]);
    };

    subtest "-as" => sub {
        %RE = ();
        Regexp::Pattern->import('Example::re1' => (-as=>"foo"));
        is_deeply([sort keys %RE], [qw/foo/]);
        dies_ok { Regexp::Pattern->import('Example::*' => (-as=>"foo")) }
            "-as cannot be used on a wildcard import";
        dies_ok { Regexp::Pattern->import('Example::re1' => (-as=>"re one")) }
            "-as has to be simple identifier";
    };

    subtest "-prefix and -suffix" => sub {
        %RE = ();
        Regexp::Pattern->import('Example::*' => (-prefix=>"p_"));
        is_deeply([sort keys %RE], [qw/p_re1 p_re2 p_re3 p_re4 p_re5/]);

        # can also be applied to a single pattern
        %RE = ();
        Regexp::Pattern->import('Example::re2' => (-prefix=>"q_"));
        is_deeply([sort keys %RE], [qw/q_re2/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-suffix=>"_b"));
        is_deeply([sort keys %RE], [qw/re1_b re2_b re3_b re4_b re5_b/]);

        # combo of prefix & suffix
        %RE = ();
        Regexp::Pattern->import('Example::*' => (-prefix=>"a_", -suffix=>"_b"));
        is_deeply([sort keys %RE], [qw/a_re1_b a_re2_b a_re3_b a_re4_b a_re5_b/]);
    };

    subtest "-has_tag, -lacks_tag, -has_tag_matching, -lacks_tag_matching" => sub {
        %RE = ();
        Regexp::Pattern->import('Example::*' => (-has_tag=>"A"));
        is_deeply([sort keys %RE], [qw/re2/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-has_tag=>"B"));
        is_deeply([sort keys %RE], [qw/re2 re3/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-has_tag=>"D"));
        is_deeply([sort keys %RE], [qw//]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-lacks_tag=>"A"));
        is_deeply([sort keys %RE], [qw/re1 re3 re4 re5/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-has_tag=>"B", -lacks_tag=>"A"));
        is_deeply([sort keys %RE], [qw/re3/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-has_tag_matching=>qr/[AB]/));
        is_deeply([sort keys %RE], [qw/re2 re3/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-lacks_tag_matching=>qr/[AB]/));
        is_deeply([sort keys %RE], [qw/re1 re4 re5/]);

        %RE = ();
        Regexp::Pattern->import('Example::*' => (-has_tag_matching=>'A|B', -lacks_tag_matching=>'[XA]'));
        is_deeply([sort keys %RE], [qw/re3/]);
   };

    dies_ok { Regexp::Pattern->import("Example::re1" => (-foo=>1)) }
        "unknown options";
};

done_testing;
