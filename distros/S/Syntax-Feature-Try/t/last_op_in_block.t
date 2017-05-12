use Test::Spec;
require Test::NoWarnings;
use Exception::Class qw/ MockErr /;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ test_syntax_error compile_ok /;

use syntax 'try';

our $wantarray;

sub save_local_context {
    $wantarray = wantarray;
}

sub test_void_context(&) {
    my ($coderef) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $scalar = $coderef->();
    is($wantarray, undef, "for scalar context it is undef");

    my @array = $coderef->();
    is($wantarray, undef, "for list context it is undef");

    $coderef->();
    is($wantarray, undef, "for void context it is undef");
}

describe "last op" => sub {
    before each => sub {
        $wantarray = undef;
    };

    it "is called in void context in try block" => sub {
        test_void_context {
            try {
                save_local_context()
            }
            finally { }
        };
    };

    it "is called in void context in catch block" => sub {
        test_void_context {
            try { MockErr->throw }
            catch (MockErr $e) {
                save_local_context()
            }
        };
    };

    it "is called in void context in finally block" => sub {
        test_void_context {
            try {
            }
            finally {
                save_local_context()
            }
        };
    };

};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
