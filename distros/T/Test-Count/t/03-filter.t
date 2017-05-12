#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use File::Spec;

use Test::Count::Filter;
use IO::Scalar;

my $mytest = "T". "E" . "S" . "T";
{
    open my $in, "<", File::Spec->catfile("t", "sample-data", "test-scripts", "01-parser.t");
    my $buffer = "";
    my $out = IO::Scalar->new(\$buffer);

    my $filter = Test::Count::Filter->new(
        {
            'input_fh' => $in,
            'output_fh' => $out,
        }
    );

    $filter->process();

    # TEST
    is ($buffer, <<"EOF", "Testing for expected");
#!/usr/bin/perl

use strict;
use warnings;

# An unrealistic number so the number of tests will be accurate.
use Test::More tests => 5;

use Test::Count::Parser;

{
    my \$parser = Test::Count::Parser->new();
    # $mytest
    ok (\$parser, "Checking for parser initialization.");
}

{
    my \$parser = Test::Count::Parser->new();
    # $mytest
    \$parser->update_assignments(
        {
            text => q{\$NUM_ITERS=5;\$TESTS_PER_ITER=7}
        },
    );
    \$parser->update_count(
        {
            text => q{\$NUM_ITERS*\$TESTS_PER_ITER}
        },
    );
    is (\$parser->get_count(), 35, "Checking for correct calculation");
}

{
    my \$parser = Test::Count::Parser->new();
    \$parser->update_assignments(
        {
            text => q{\$NUM_ITERS=5;\$TESTS_PER_ITER=7}
        },
    );
    \$parser->update_assignments(
        {
            text => q{\$myvar=\$NUM_ITERS-2}
        },
    );

    \$parser->update_count(
        {
            text => q{\$myvar+\$TESTS_PER_ITER}
        },
    );
    # $mytest
    is (\$parser->get_count(), 10, "2 update_assignments()'s");
}

{
    my \$parser = Test::Count::Parser->new();
    \$parser->update_assignments(
        {
            text => q{\$var1=100}
        },
    );

    \$parser->update_count(
        {
            text => q{\$var1-30}
        }
    );
    # Now count is 70

    \$parser->update_assignments(
        {
            text => q{\$shlomif=50}
        },
    );
    \$parser->update_count(
        {
            text => q{\$shlomif*4},
        }
    );
    # $mytest
    is (\$parser->get_count(), 270, "2 update_count()'s");
}

{
    my \$parser = Test::Count::Parser->new();
    \$parser->update_count(
        {
            text => q{7/2}
        }
    );
    # $mytest
    is (\$parser->get_count(), 3, "use integer");
}
EOF
}

{
    open my $in, "<", File::Spec->catfile("t", "sample-data", "test-scripts", "basic.arc");
    my $buffer = "";
    my $out = IO::Scalar->new(\$buffer);

    my $filter = Test::Count::Filter->new(
        {
            'input_fh' => $in,
            'output_fh' => $out,
            'assert_prefix_regex' => qr{; TEST},
            'plan_prefix_regex' => qr{\(plan\s+},
        }
    );

    $filter->process();

    # TEST
    is ($buffer, <<"EOF", "Testing for expected in Lisp Code with customisations");
;;; basic.arc.t - test some basic arc features.
;;;
;;; This is an example for a Lisp/Scheme/Arc file that should be processed
;;; using Test-Count.
;;;
;;; This file is licensed under the MIT X11 License:
;;; http://www.opensource.org/licenses/mit-license.php
;;;
;;; (C) Copyright by Shlomi Fish, 2008

(load "arctap.arc")

(plan 18)

; TEST*3
(ok 1 "1 is a true value")

(ok (is 3 3) "3 is equal to 3")

(ok (is (+ 20 4) 24) "20+4 is equal to 24")

(with (x 20)
    (= x (+ x 4))
    ; TEST
    (ok (is x 24) "Adding 4 to x == 20 yields x == 24")
    (= x (- x 15))
    ; TEST
    (ok (is x 9) "Subtracting 15 to get 9"))

; TEST
(ok (is (* 3 6) 18) "3*6 == 18")

; TEST
(ok (> 5 3) "5 > 3")

; TEST
(ok (>= 5 3) "5 >= 3")

; TEST
(ok (>= 5 5) "5 >= 5")

; TEST
(ok (< 3 5) "3 < 5")

; TEST
(ok (<= 3 5) "3 <= 5")

; TEST
(ok (<= 3 3) "3 <= 3")

; TEST
(ok (not nil) "nil is false")

; TEST
(ok (not (not 1)) "!!1 is true")

; TEST
(ok (not (> 3 5)) "3 is not > 5")

; TEST
(ok (not (is 3 5)) "3 is not 5")

;---------------------------

; TEST+2
(ok (not (< 10 0)) "10 is not less than 0")
(ok (not (<= 5 4)) "5 is not leq than 4")
EOF
}

{
    open my $in, "<", File::Spec->catfile("t", "sample-data", "test-scripts", "with-indented-plan.t");
    my $buffer = "";
    my $out = IO::Scalar->new(\$buffer);

    my $filter = Test::Count::Filter->new(
        {
            'input_fh' => $in,
            'output_fh' => $out,
        }
    );

    $filter->process();

    # TEST
    is ($buffer, <<"EOF", "Testing for expected");
#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

if (exists(\$ENV{TEST_ME}))
{
    plan tests => 2;
}
else
{
    plan skip_all => 'Skipping';
}

# $mytest
ok (1, 'One test');

# $mytest
ok (1, 'Second test');
EOF
}
