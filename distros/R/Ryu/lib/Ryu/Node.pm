package Ryu::Node;

use strict;
use warnings;

our $VERSION = '0.036'; # VERSION

=head1 NAME

Ryu::Node - generic node

=head1 DESCRIPTION

This is a common base class for all sources, sinks and other related things.
It does very little.

=cut

=head1 METHODS

Not really. There's a constructor, but that's not particularly exciting.

=cut

sub new {
    bless {
        pause_propagation => 1,
        @_[1..$#_]
    }, $_[0]
}

=head2 pause

Does nothing useful.

=cut

sub pause {
    use Scalar::Util qw(refaddr);
    my ($self, $src) = @_;
    my $k = (refaddr $src) // 0;

    my $was_paused = keys %{$self->{is_paused}};
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
    use Scalar::Util qw(refaddr);
    my ($self, $src) = @_;
    my $k = refaddr($src) // 0;
    delete $self->{is_paused}{$k} unless --$self->{is_paused}{$k} > 0;
    unless(keys %{$self->{is_paused} || {} }) {
        if(my $parent = $self->parent) {
            $parent->resume($self) if $self->{pause_propagation};
        }
        if(my $flow_control = $self->{flow_control}) {
            $flow_control->emit(1);
        }
    }
    $self
}

=head2 is_paused

Might return 1 or 0, but is generally meaningless.

=cut

sub is_paused {
    use Scalar::Util qw(refaddr);
    my ($self, $obj) = @_;
    return keys %{ $self->{is_paused} } ? 1 : 0 unless defined $obj;
    my $k = refaddr($obj);
    return exists $self->{is_paused}{$k}
    ? 0 + $self->{is_paused}{$k}
    : 0;
}

sub flow_control {
    my ($self) = @_;
    $self->{flow_control} //= Ryu::Source->new(
        new_future => $self->{new_future}
    )
}

sub label { shift->{label} }

sub parent { shift->{parent} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2019. Licensed under the same terms as Perl itself.

