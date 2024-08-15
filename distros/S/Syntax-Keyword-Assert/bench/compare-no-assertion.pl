=head1 DESCRIPTION

The B<assert> keyword is ignored at runtime when STRICT mode is disabled,
so it should not impact the performance of the code.

This benchmark demonstrates that the performance of code using the B<assert> keyword is nearly identical to code without it.

=head1 SYNOPSIS

    % perl bench/compare-no-assertion.pl

=head1 RESULT

                         Rate   no assertion with assertion
    no assertion   14492754/s             --            -1%
    with assertion 14705882/s             1%             --

=cut

use v5.40;
use Benchmark qw(cmpthese);

BEGIN {
    # Disable STRICT mode. SEE ALSO: Devel::StrictMode
    $ENV{EXTENDED_TESTING} = 0;
    $ENV{AUTHOR_TESTING}   = 0;
    $ENV{RELEASE_TESTING}  = 0;
    $ENV{PERL_STRICT}      = 0;
}

use Syntax::Keyword::Assert;

# Function with assertion block but it is ignored at runtime
sub with_assertion($message) {
    assert { defined $message };
    return $message;
}

# Function without assertion block
sub no_assertion($message) {
    return $message;
}

cmpthese(10000000, {
    'with assertion' => sub { with_assertion('world') },
    'no assertion'   => sub { no_assertion('world') },
});
