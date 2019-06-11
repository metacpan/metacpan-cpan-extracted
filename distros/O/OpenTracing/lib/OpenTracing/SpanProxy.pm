package OpenTracing::SpanProxy;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub span { shift->{span} }

sub log { shift->span->log(@_) }

sub new_span {
    my ($self, $name, %args) = @_;
    my $parent = $self->span;
    @args{qw(trace_id parent_id)} = (
        $parent->trace_id,
        $parent->id,
    );
    $parent->batch->new_span($name => %args);
}

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $self->span->finish;
    delete $self->{span};
}

1;

