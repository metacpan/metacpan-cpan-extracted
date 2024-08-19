package Ryu::Sink;

use strict;
use warnings;

use parent qw(Ryu::Node);

our $VERSION = '4.000'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Ryu::Sink - base representation for a thing that receives events

=head1 DESCRIPTION

This is currently of limited utility.

 my $src = Ryu::Source->new;
 my $sink = Ryu::Sink->new;
 $sink->from($src);
 $sink->source->say;

=cut

use Future;
use Log::Any qw($log);

=head1 METHODS

=cut

sub new {
    my $class = shift;
    $class->SUPER::new(
        sources => [],
        @_
    )
}

=head2 from

Given a source, will attach it as the input for this sink.

The key difference between L</from> and L</drain_from> is that this method will mark the sink as completed
when the source is finished. L</drain_from> allows sequencing of multiple sources, keeping the sink active
as each of those completes.

=cut

sub from {
    my ($self, $src, %args) = @_;

    die 'expected a subclass of Ryu::Source, received ' . $src . ' instead' unless $src->isa('Ryu::Source');

    $self = $self->new unless ref $self;
    $self->drain_from($src);
    $src->completed->on_ready(sub {
        my $f = $self->source->completed;
        shift->on_ready($f) unless $f->is_ready;
    });
    return $self
}

sub drain_from {
    my ($self, $src) = @_;
    if(ref $src eq 'ARRAY') {
        my $data = $src;
        $src = Ryu::Source->new(
            new_future => $self->{new_future},
            label      => 'array',
        )->from($data);
    }
    die 'expected a subclass of Ryu::Source, received ' . $src . ' instead' unless $src->isa('Ryu::Source');

    $log->tracef('Will drain from %s, with %d sources in queue already', $src->describe, 0 + $self->{sources}->@*);
    push $self->{sources}->@*, (my $buffered = $src->buffer)->pause;
    return $self->start_drain;
}

sub start_drain {
    my ($self) = @_;
    if($self->is_draining) {
        $log->tracef('Still draining from %s, no need to start new source yet', $self->{active_source}->describe);
        return $self;
    }
    unless($self->{sources}->@*) {
        $log->tracef('No need to start draining, we have no pending sources in queue');
        return $self;
    }

    my $src = shift $self->{sources}->@*
        or do {
            $log->warnf('Invalid pending source');
            return $self;
        };

    $log->tracef('Draining from source %s', $src->describe);
    $self->{active_source} = $src;
    $src->completed->on_ready(sub {
        undef $self->{active_source};
        $self->start_drain;
    });
    $src->each_while_source(sub {
        $self->emit($_)
    }, $self->source, finish_source => 0);
    $src->resume if $src->is_paused;
    $src->prepare_await;
    return $self;
}

sub is_draining { !!shift->{active_source} }

sub emit {
    my ($self, $data) = @_;
    $self->source->emit($data);
    $self
}

sub finish {
    my ($self) = @_;
    return $self if $self->{is_finished};
    $self->{is_finished} = 1;
    delete $self->{new_source};
    my @src = splice $self->{sources}->@*;
    push @src, delete $self->{active_source} if $self->{active_source};
    for my $src (@src) {
        $src->resume if $src->is_paused;
    }
    return $self unless my $src = $self->{source};
    $src->finish;
    return $self;
}

sub source {
    my ($self) = @_;
    return $self->{source} if $self->{source};
    $log->tracef('Creating source for sink %s', "$self");
    my $src = ($self->{new_source} //= sub { Ryu::Source->new(label => 'sink source') })->();

    $self->{source} = $src;
    Scalar::Util::weaken($src->{parent} = $self);
    $src->finish if $self->{is_finished};
    return $src;
}

sub _completed {
    my ($self) = @_;
    return $self->source->_completed;
}

sub notify_child_completion { }

sub DESTROY {
    my ($self) = @_;
    return unless my $src = delete $self->{source};
    $src->finish;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2024. Licensed under the same terms as Perl itself.

