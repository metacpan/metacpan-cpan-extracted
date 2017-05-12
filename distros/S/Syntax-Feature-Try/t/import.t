use Test::Spec;
require Test::NoWarnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ compile_ok test_syntax_error /;

describe "import syntax" => sub {
    it "is enabled after 'use syntax try'" => sub {
        compile_ok q[
            use syntax 'try';

            try {  }
            finally { }
        ];
    };

    it "is disabled after 'use syntax try'" => sub {
        test_syntax_error q[
            use syntax 'try';

            try { } finally { }

            no syntax 'try';

            try { } finally { }

            sub foo { }
        ], qr/^syntax error .*at \(eval \d+\) line 10/;
    };

    it "is disabled in different scope" => sub {
        test_syntax_error q[
            {
                package Test::AA;
                use syntax 'try';

                try { } finally { }

                sub foo { }
            }
            {
                package Test::BB;

                try { } finally { }

                sub foo { }
            }
        ], qr/^syntax error .*at \(eval \d+\) line 15/;
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
