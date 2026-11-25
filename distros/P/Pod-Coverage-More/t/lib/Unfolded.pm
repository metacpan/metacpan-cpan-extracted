package Unfolded;

# Named arguments read without the multideref op.  Perl compiles that op for
# these reads unless autovivification is loaded, so this fixture loads it, and
# t/Pod-Coverage-More-Analyzer.t requires it after every other fixture.

use 5.036;
use warnings FATAL => q{all};
no autovivification;

sub named {
    my ( $self, %opts ) = @_;
    delete $opts{gone};
    return $opts{size} if exists $opts{verbose};
    return;
}

sub hashref_arg {
    my ( $self, $args ) = @_;
    return $args->{alpha}[0];
}

1;
