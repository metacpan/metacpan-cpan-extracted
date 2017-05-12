use 5.014;
use Test::Spec;
use Exception::Class qw/
    Err::AAA
    Err::BBB
/;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ test_syntax_error compile_ok /;

use syntax 'try';

our $wantarray;

sub test_wantarray(&) {
    my ($coderef) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $scalar = $coderef->();
    is($wantarray, '', "scalar context ok");

    my @array = $coderef->();
    is($wantarray, 1, "list context ok");

    $coderef->();
    is($wantarray, undef, "void context ok");
}

sub mock_code {}

describe "wantarray" => sub {
    before each => sub {
        $wantarray = undef;
    };

    it "returns expected values" => sub {
        test_wantarray {
            $wantarray = wantarray;
        }
    };

    it "returns correct context from try block" => sub {
        test_wantarray {
            mock_code;
            try {
                mock_code;
                try {
                    mock_code;
                    $wantarray = wantarray;
                    mock_code;
                }
                catch (Err::AAA $e) { }
                mock_code;
            }
            finally {
            }
            mock_code;
        };
    };

    it "returns correct context from catch block" => sub {
        test_wantarray {
            mock_code;
            try { Err::AAA->throw }
            catch (Err::AAA $e) {
                mock_code;
                try { Err::BBB->throw }
                catch(Err::BBB $e) {
                    mock_code;
                    $wantarray = wantarray;
                    mock_code;
                }
                mock_code;
            }
            mock_code;
        };
    };

    it "returns correct context from finally block" => sub {
        test_wantarray {
            mock_code;
            try { }
            finally {
                mock_code;
                try { }
                finally {
                    mock_code;
                    $wantarray = wantarray;
                    mock_code;
                }
                mock_code;
            }
            mock_code;
        };
    };

    it "returns correct context from included non-sub scope blocks" => sub {
        test_wantarray {
            mock_code;
            try {
                mock_code;
                for (my $i=0; $i<5; $i++) {
                    if ($i == 3) {
                        if ($i =~ /\d/) {
                            $wantarray = wantarray;
                        }
                    }
                }
                mock_code;
            }
            finally {
            }
            mock_code;
        };
    };

    it "returns correct context in subroutine defined inside try/catch/finally" => sub {
        test_wantarray {
            try {
                sub sub_try { $wantarray = wantarray }
                test_wantarray \&sub_try;
                Err::AAA->throw;
            }
            catch (Err::AAA $e) {
                sub sub_catch { $wantarray = wantarray }
                test_wantarray \&sub_catch;
                mock_code;
            }
            finally {
                sub sub_finally { $wantarray = wantarray }
                test_wantarray \&sub_finally;
                $wantarray = wantarray;
                mock_code;
            }
        };
    };

    it "returns correct context in eval inside try block" => sub {
        test_wantarray {
            try {
                my $scalar = eval { $wantarray = wantarray };
                die $@ if $@;
                is($wantarray, '', "scalar context ok");

                my @array = eval { $wantarray = wantarray };
                die $@ if $@;
                is($wantarray, 1, "list context ok");

                eval { $wantarray = wantarray };
                die $@ if $@;
                is($wantarray, undef, "void context ok");

                $wantarray = wantarray;
            }
            finally { }
        };
    };

    it "returns correct context inside function called after return" => sub {
        sub get_wantarray {
            return wantarray ? 'array' : 'scalar';
        }

        sub test_return_wantarray {
            try {
                return get_wantarray();
            }
            finally { }
            return 'other';
        }

        my $scalar = test_return_wantarray();
        is($scalar, 'scalar', "scalar context ok");

        my @array = test_return_wantarray();
        is_deeply(\@array, ['array'], "list context ok");
    };
};

runtests;
