use Test::Spec;
require Test::NoWarnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ compile_ok dump_code /;

sub get_line_number {
    my ($code, $pattern) = @_;
    my ($before_pattern) = split $pattern, $code, 2;
    return scalar(split "\n", $before_pattern);
}

sub test_code_warnings {
    my ($code, @expected_warnings) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, shift };
    compile_ok $code;

    foreach my $expected (@expected_warnings) {
        my $linenr = get_line_number($code, $expected);
        like(
            shift @warnings,
            qr/^$expected at \(eval \d+\) line $linenr.\n$/,
            "Expected warning $expected at line number $linenr"
        ) or dump_code($code);
    }
    if (@warnings) {
        fail("There are aditional warnings:\n   "
                . join "\n   ", @warnings);
        dump_code($code);
    }
}

describe "parser" => sub {
    it "generates correctly source-code warning line-numbers" => sub {
        test_code_warnings q[
            use syntax 'try';

            try { warn "AAA"; die 123; } catch ($e) { warn "BBB" } finally { warn "CCC" }
            warn "DDD";
        ], qw/ AAA BBB CCC DDD /;

        test_code_warnings q[
            use syntax 'try';

            try {
                warn "AAA";
                die 123;
            } catch ($e) {
                warn "BBB";
            }
            finally {
                warn "CCC";
            }
            warn "DDD";
        ], qw/ AAA BBB CCC DDD /;

        test_code_warnings q[
            use syntax 'try';

            try {
                warn "AAA";
                die 123;
            }

            catch
                ( AAA $e ) {
                }
            catch (
                $others
            )
            {
                warn "BBB";
            }

            finally
                {
                    warn "CCC";
                }

            warn "DDD";

        ], qw/ AAA BBB CCC DDD /;
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
