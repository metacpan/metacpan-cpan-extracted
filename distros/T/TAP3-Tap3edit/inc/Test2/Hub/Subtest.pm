#line 1
package Test2::Hub::Subtest;
use strict;
use warnings;

our $VERSION = '1.302175';

BEGIN { require Test2::Hub; our @ISA = qw(Test2::Hub) }
use Test2::Util::HashBase qw/nested exit_code manual_skip_all/;
use Test2::Util qw/get_tid/;

sub is_subtest { 1 }

sub inherit {
    my $self = shift;
    my ($from) = @_;

    $self->SUPER::inherit($from);

    $self->{+NESTED} = $from->nested + 1;
}

{
    # Legacy
    no warnings 'once';
    *ID = \&Test2::Hub::HID;
    *id = \&Test2::Hub::hid;
    *set_id = \&Test2::Hub::set_hid;
}

sub send {
    my $self = shift;
    my ($e) = @_;

    my $out = $self->SUPER::send($e);

    return $out if $self->{+MANUAL_SKIP_ALL};

    my $f = $e->facet_data;

    my $plan = $f->{plan} or return $out;
    return $out unless $plan->{skip};

    my $trace = $f->{trace} or die "Missing Trace!";
    return $out unless $trace->{pid} != $self->pid
                    || $trace->{tid} != $self->tid;

    no warnings 'exiting';
    last T2_SUBTEST_WRAPPER;
}

sub terminate {
    my $self = shift;
    my ($code, $e, $f) = @_;
    $self->set_exit_code($code);

    return if $self->{+MANUAL_SKIP_ALL};

    $f ||= $e->facet_data;

    if(my $plan = $f->{plan}) {
        my $trace = $f->{trace} or die "Missing Trace!";
        return if $plan->{skip}
               && ($trace->{pid} != $$ || $trace->{tid} != get_tid);
    }

    no warnings 'exiting';
    last T2_SUBTEST_WRAPPER;
}

1;

__END__

#line 136
