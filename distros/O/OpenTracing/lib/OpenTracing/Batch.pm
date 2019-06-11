package OpenTracing::Batch;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use parent qw(OpenTracing::Common);

use Time::HiRes;
use Scalar::Util ();

sub process { shift->{process} //= OpenTracing::Process->new }

sub spans {
    shift->{spans}
}
sub span_list {
    (shift->{spans} //= [])->@*
}

sub add_span {
    my ($self, $span) = @_;
    push $self->{spans}->@*, $span;
    Scalar::Util::weaken($span->{batch});
    $span
}

sub new_span {
    my ($self, $name, %args) = @_;
    $args{operation_name} = $name;
    $args{start_time} //= Time::HiRes::time() * 1_000_000;
    $self->add_span(my $span = OpenTracing::Span->new(batch => $self, %args));
    OpenTracing::SpanProxy->new(span => $span)
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    my $on_destroy = delete $self->{on_destroy}
        or return;
    $self->$on_destroy;
    return;
}

1;
