package OpenTracing::Span;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use parent qw(OpenTracing::Common);

use Time::HiRes ();
use Math::Random::Secure ();

sub trace_id { shift->{trace_id} //= Math::Random::Secure::irand(2**62) }
sub id { shift->{id} //= Math::Random::Secure::irand(2**62) }
sub parent_id { shift->{parent_id} // 0 }
sub flags { shift->{flags} // 0 }
sub start_time { shift->{start_time} //= (Time::HiRes::time() * 1_000_000) }
sub duration { shift->{duration} }
sub operation_name { shift->{operation_name} }
sub tags { shift->{tags} }
sub batch { shift->{batch} }
sub tag_list {
    # OpenTracing::Tag->new(key => 'example_process_tag', value => 'process_value')
    my $tags = shift->{tags} //= [];
    map { OpenTracing::Tag->new(key => $_, value => $tags->{$_}) } sort keys %$tags;
}

sub logs { shift->{logs} }
sub log_list {
    (shift->{logs} //= [])->@*
}

sub log : method {
    my ($self, $message, %args) = @_;
    $args{message} = $message;
    my $timestamp = delete($args{timestamp}) // Time::HiRes::time() * 1_000_000;
    push +($self->{logs} //= [])->@*, my $log = OpenTracing::Log->new(
        tags => {
            message => $message,
        },
        timestamp => $timestamp
    );
    $log;
}

sub finish {
    my ($self) = @_;
    $self->{duration} = (Time::HiRes::time * 1_000_000) - $self->start_time;
    $self
}

1;

