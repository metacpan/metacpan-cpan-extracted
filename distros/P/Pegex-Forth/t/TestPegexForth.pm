use strict; use warnings;
package TestPegexForth;
use Test::More();
use Pegex::Forth;
use Capture::Tiny ':all';

strict->import;
warnings->import;

use base 'Exporter';
our @EXPORT = qw(test_top test_stack test_out test_err);

sub test_top {
    my ($forth, $want, $label) = @_;
    my $got = Pegex::Forth->new->run($forth);
    Test::More::is $got, $want, $label;
}

sub test_stack {
    my ($forth, $want, $label) = @_;
    my @got = Pegex::Forth->new->run($forth);
    my $got = '[' . join(',', @got) . ']';
    Test::More::is $got, $want, $label;
}

sub test_out {
    my ($forth, $want, $label) = @_;
    my $got = capture_stdout {
        Pegex::Forth->new->run($forth);
    };
    chomp $got;
    Test::More::is $got, $want, $label;
}

sub test_err {
    my ($forth, $want, $label) = @_;
    eval { Pegex::Forth->new->run($forth) };
    my $got = $@;
    chomp $got;
    Test::More::is $got, $want, $label;
}

END {
    Test::More::done_testing;
}

1;
