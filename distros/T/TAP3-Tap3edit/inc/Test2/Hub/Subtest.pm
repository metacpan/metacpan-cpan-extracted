#line 1
package Test2::Hub::Subtest;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Hub; our @ISA = qw(Test2::Hub) }
use Test2::Util::HashBase qw/nested bailed_out exit_code manual_skip_all id/;
use Test2::Util qw/get_tid/;

my $ID = 1;
sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{+ID} ||= join "-", $$, get_tid, $ID++;
}

sub is_subtest { 1 }

sub process {
    my $self = shift;
    my ($e) = @_;
    $e->set_nested($self->nested);
    $e->set_in_subtest($self->{+ID});
    $self->set_bailed_out($e) if $e->isa('Test2::Event::Bail');
    $self->SUPER::process($e);
}

sub send {
    my $self = shift;
    my ($e) = @_;

    my $out = $self->SUPER::send($e);

    return $out if $self->{+MANUAL_SKIP_ALL};
    return $out unless $e->isa('Test2::Event::Plan')
        && $e->directive eq 'SKIP'
        && ($e->trace->pid != $self->pid || $e->trace->tid != $self->tid);

    no warnings 'exiting';
    last T2_SUBTEST_WRAPPER;
}

sub terminate {
    my $self = shift;
    my ($code, $e) = @_;
    $self->set_exit_code($code);

    return if $self->{+MANUAL_SKIP_ALL};
    return if $e->isa('Test2::Event::Plan')
           && $e->directive eq 'SKIP'
           && ($e->trace->pid != $$ || $e->trace->tid != get_tid);

    no warnings 'exiting';
    last T2_SUBTEST_WRAPPER;
}

1;

__END__

#line 125
