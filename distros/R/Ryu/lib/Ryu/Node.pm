package Ryu::Node;

use strict;
use warnings;

our $VERSION = '4.000'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Ryu::Node - generic node

=head1 DESCRIPTION

This is a common base class for all sources, sinks and other related things.
It does very little.

=cut

use Future;
use Scalar::Util qw(refaddr);

=head1 METHODS

Not really. There's a constructor, but that's not particularly exciting.

=cut

sub new {
    bless {
        pause_propagation => 1,
        @_[1..$#_]
    }, $_[0]
}

=head2 describe

Returns a string describing this node and any parents - typically this will result in a chain
like C<< from->combine_latest->count >>.

=cut

# It'd be nice if L<Future> already provided a method for this, maybe I should suggest it
sub describe {
    my ($self) = @_;
    my $completed = $self->completed;
    ($self->parent ? $self->parent->describe . '=>' : '') . '[' . ($self->label // 'unknown') . '](' . ($completed ? $completed->state : 'inactive') . ')';
}

=head2 completed

Returns a L<Future> indicating completion (or failure) of this stream.

=cut

sub completed {
    my ($self) = @_;
    my $completion = $self->_completed
        or return undef;
    return $completion->without_cancel->on_ready(sub {
        my $f = shift;
        my ($expected) = $f->state =~ /^(\S+)/;
        my ($actual) = $completion->state =~ /^(\S+)/;
        if($expected ne $actual) {
            warn "Completed state $actual does not match internal state $expected - if you are calling ->completed->$expected, this will not work: use ->finish or ->fail instead";
        }
    });
}

# Internal use only, since it's cancellable
sub _completed {
    my ($self) = @_;
    return $self->{completed} if $self->{completed};
    $self->{completed} = my $f = $self->new_future(
        'completion'
    );
    $f->on_ready(
        $self->curry::weak::cleanup
    ) if $self->can('cleanup');
    $f
}

=head2 pause

Does nothing useful.

=cut

sub pause {
    my ($self, $src) = @_;
    my $k = refaddr($src) // 0;

    my $was_paused = $self->{is_paused} && keys %{$self->{is_paused}};
    unless($was_paused) {
        delete @{$self}{qw(unblocked unblocked_without_cancel)} if $self->{unblocked} and $self->{unblocked}->is_ready;
    }
    ++$self->{is_paused}{$k};
    if(my $parent = $self->parent) {
        $parent->pause($self) if $self->{pause_propagation};
    }
    if(my $flow_control = $self->{flow_control}) {
        $flow_control->emit(0) unless $was_paused;
    }
    $self
}

=head2 resume

Is about as much use as L</pause>.

=cut

sub resume {
    my ($self, $src) = @_;
    my $k = refaddr($src) // 0;
    delete $self->{is_paused}{$k} unless --$self->{is_paused}{$k} > 0;
    unless($self->{is_paused} and keys %{$self->{is_paused}}) {
        my $f = $self->_unblocked;
        $f->done unless $f->is_ready;
        if(my $parent = $self->parent) {
            $parent->resume($self) if $self->{pause_propagation};
        }
        if(my $flow_control = $self->{flow_control}) {
            $flow_control->emit(1);
        }
    }
    $self
}

=head2 unblocked

Returns a L<Future> representing the current flow control state of this node.

It will be L<pending|Future/is_pending> if this node is currently paused,
otherwise L<ready|Future/is_ready>.

=cut

sub unblocked {
    # Since we don't want stray callers to affect our internal state, we always return
    # a non-cancellable version of our internal Future.
    my $self = shift;
    return $self->{unblocked_without_cancel} //= $self->_unblocked->without_cancel
}

sub _unblocked {
    my ($self) = @_;
    # Since we don't want stray callers to affect our internal state, we always return
    # a non-cancellable version of our internal Future.
    $self->{unblocked} //= do {
        $self->is_paused
        ? $self->new_future
        : Future->done
    };
}

=head2 is_paused

Might return 1 or 0, but is generally meaningless.

=cut

sub is_paused {
    my ($self, $obj) = @_;
    return keys %{ $self->{is_paused} } ? 1 : 0 unless defined $obj;
    my $k = refaddr($obj);
    return exists $self->{is_paused}{$k}
    ? 0 + $self->{is_paused}{$k}
    : 0;
}

sub flow_control {
    my ($self) = @_;
    return $self->{flow_control} if $self->{flow_control};
    $self->{flow_control} = my $fc = Ryu::Source->new(
        new_future => $self->{new_future}
    );
    $self->_completed->on_ready(sub {
        my $fc = delete $self->{flow_control}
            or return;
        $fc->finish;
    });
    $fc
}

sub label { shift->{label} }

sub parent { shift->{parent} }

=head2 new_future

Used internally to get a L<Future>.

=cut

sub new_future {
    my $self = shift;
    (
        $self->{new_future} //= $Ryu::Source::FUTURE_FACTORY
    )->($self, @_)
}


1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2024. Licensed under the same terms as Perl itself.

