#line 1
package Test::Builder::Formatter;
use strict;
use warnings;

our $VERSION = '1.302175';

BEGIN { require Test2::Formatter::TAP; our @ISA = qw(Test2::Formatter::TAP) }

use Test2::Util::HashBase qw/no_header no_diag/;

BEGIN {
    *OUT_STD = Test2::Formatter::TAP->can('OUT_STD');
    *OUT_ERR = Test2::Formatter::TAP->can('OUT_ERR');

    my $todo = OUT_ERR() + 1;
    *OUT_TODO = sub() { $todo };
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{+HANDLES}->[OUT_TODO] = $self->{+HANDLES}->[OUT_STD];
}

sub plan_tap {
    my ($self, $f) = @_;

    return if $self->{+NO_HEADER};
    return $self->SUPER::plan_tap($f);
}

sub debug_tap {
    my ($self, $f, $num) = @_;
    return if $self->{+NO_DIAG};
    my @out = $self->SUPER::debug_tap($f, $num);
    $self->redirect(\@out) if @out && ref $f->{about} && defined $f->{about}->{package}
        && $f->{about}->{package} eq 'Test::Builder::TodoDiag';
    return @out;
}

sub info_tap {
    my ($self, $f) = @_;
    return if $self->{+NO_DIAG};
    my @out = $self->SUPER::info_tap($f);
    $self->redirect(\@out) if @out && ref $f->{about} && defined $f->{about}->{package}
        && $f->{about}->{package} eq 'Test::Builder::TodoDiag';
    return @out;
}

sub redirect {
    my ($self, $out) = @_;
    $_->[0] = OUT_TODO for @$out;
}

sub no_subtest_space { 1 }

1;

__END__

#line 107
