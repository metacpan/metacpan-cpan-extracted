use Test::Spec;
require Test::NoWarnings;
use Syntax::Feature::Try;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ compile_ok /;

describe "code without finally block" => sub {
    my (@parsed, @catch);

    it "can be compiled" => sub {
        Syntax::Feature::Try->expects('_statement')->returns(sub {
                @parsed = @_;
                undef;
            });

        compile_ok q[
            use syntax 'try';

            try {  }
            catch (My::Exception::Class_AAA $my_VAR) {  }
            catch (Class_BBB $e) {  }
            catch ($others) {  }
        ];
    };

    describe "generated output" => sub {
        it "has expected format" => sub {
            is(scalar @parsed, 2, "It returns two arguments");
            is(ref $parsed[0], 'CODE', 'first is reference to code for try-block');
            is(ref $parsed[1], 'ARRAY', 'second is reference to list of catch parts');
        };

        it "contains 3 catch blocks" => sub {
            @catch = @{ $parsed[1] };
            is(scalar @catch, 3);
        };

        it "contains correct data for first catch" => sub {
            my ($code_ref, @args) = @{ $catch[0] };
            is(ref $code_ref, 'CODE');
            is_deeply(\@args, ['My::Exception::Class_AAA']);
        };

        it "contains correct data for second catch" => sub {
            my ($code_ref, @args) = @{ $catch[1] };
            is(ref $code_ref, 'CODE');
            is_deeply(\@args, ['Class_BBB']);
        };

        it "contains correct data for third catch" => sub {
            my ($code_ref, @args) = @{ $catch[2] };
            is(ref $code_ref, 'CODE');
            is_deeply(\@args, []);
        };
    };
};

describe "code try/finally" => sub {
    my (@parsed, @catch);

    it "can be compiled" => sub {
        Syntax::Feature::Try->expects('_statement')->returns(sub {
                @parsed = @_;
                undef;
            });

        compile_ok q[
            use syntax 'try';

            try {  }
            finally { }
        ];
    };

    describe "generated output" => sub {
        it "has expected format" => sub {
            is(scalar @parsed, 3, "It returns three arguments");
            is(ref $parsed[0], 'CODE', 'first is reference to code for try-block');
            is($parsed[1], undef, 'second is undef (none catch block)');
            is(ref $parsed[2], 'CODE', 'third is reference to code for finally-block');
        };
    };
};

describe "code try/catch/finally" => sub {
    my (@parsed, @catch);

    it "can be compiled" => sub {
        Syntax::Feature::Try->expects('_statement')->returns(sub {
                @parsed = @_;
                undef;
            });

        compile_ok q[
            use syntax 'try';

            try {  }
            catch ($e) { } 
            finally { }
        ];
    };

    describe "generated output" => sub {
        it "has expected format" => sub {
            is(scalar @parsed, 3, "It returns three arguments");
            is(ref $parsed[0], 'CODE', 'first is reference to code for try-block');
            is(ref $parsed[1], 'ARRAY', 'second is reference to list of catch parts');
            is(ref $parsed[2], 'CODE', 'third is reference to code for finally-block');
        };

        it "contains one catch blocks" => sub {
            is( scalar @{ $parsed[1] }, 1 );
        };
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
