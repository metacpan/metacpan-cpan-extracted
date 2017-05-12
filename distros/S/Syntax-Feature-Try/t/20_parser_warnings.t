use Test::Spec;
require Test::NoWarnings;
use Test::Warn;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ compile_ok /;

describe "catch block" => sub {
    it "warns if class-name looks-like perl keyword" => sub {
        warning_like {
            compile_ok q[
                use syntax 'try';
                try {  }
                catch (my $e)
                    { }
            ];
        } qr/^catch: lower case class-name 'my' may lead to confusion with perl keywords at \(eval \d+\) line 4./;

        warning_like {
            compile_ok q[
                use syntax 'try';
                try {  }
                catch (return $e)
                    { }
            ];
        } qr/^catch: lower case class-name 'return' may lead to confusion with perl keywords at \(eval \d+\) line 4./;
    };

    it "does not warn on lower-case class name with own namespace" => sub {
        warning_is {
            compile_ok q[
                use syntax 'try';

                try { }
                catch (my::test $e) { }
            ];
        } "";
    };

    it "does not warn on class-name contains at least one upper character" => sub {
        warning_is {
            compile_ok q[
                use syntax 'try';

                try { }
                catch (Mytest $e) { }
                catch (My $e) { }
                catch (testA $e) { }
            ];
        } "";
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
