use Test::Spec;
require Test::NoWarnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ compile_ok /;

describe "parser" => sub {

    it "can be parsed without spaces" => sub {
        compile_ok q[
            use syntax 'try';

            ;try{ }catch($err){ }finally{ };
        ];
    };

    it "can be parsed also with spaces" => sub {
        compile_ok q[
            use syntax 'try';

            try
                {  }
            catch
                (   My::Test1   $aa     )
                {  }
            finally
                {  }
        ];
    };

    it "can be parsed also with comments" => sub {
        compile_ok q[
            use syntax 'try';

            try         # comment try
                {       # aaa
                }       # bbb
            catch       # comment catch
                (       # ccc
                 XX     # class-name
                 $a     # var-name
                )       # ddd
                {       # eee
                }       # fff
            finally     # comment 111
                {       # 222
                }       # 333
        ];
    };

    it "can be parsed also without optional args" => sub {
        compile_ok q[
            use syntax 'try';

            try {
            }
            catch ( My::Test1 ) {
            }
            catch {
            }
            finally {
            }
        ];
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
