package Ryu::Sink;

use strict;
use warnings;

use parent qw(Ryu::Node);

our $VERSION = '0.015'; # VERSION

=head1 NAME

Ryu::Sink - base representation for a thing that receives events

=head1 DESCRIPTION

This is currently of limited utility.

=cut

use Future;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	$class->SUPER::new(
		is_paused => 0,
		pending => [ ],
		@_
	)
}
=head2 from

Given a source, will attach it as the input for this sink.

=cut

sub from {
	my ($self, $src, %args) = @_;

	$self = $self->new unless ref $self;

	if($src->isa('Ryu::Source')) {
		$src->add_sink($self);
	} else {
		die 'expected a subclass of Ryu::Source, received ' . $src . ' instead';
	}
	return $self
}

sub deliver {
	push @{$_[0]{pending}}, $_[1];
	$_[0]->dispatch if $_[0]->output;
	$_[0]
}

sub output { shift->{output} }

sub dispatch {
	my $out = $_[0]->{output};
	$out->($_) for splice @{$_[0]->{pending}}, 0;
	$_[0]
}

sub drain {
	my ($self, $out) = @_;
	$self->{output} = $out;
	return $self unless $self->have_pending;
	$self->dispatch
}

sub finish {
	my $self = shift;
	$self->completion->done;
	$self
}

sub new_future {
	my $self = shift;
	(
		$self->{new_future} //= sub {
			Future->new->set_label(shift)
		}
	)->(@_)
}

sub completion {
	$_[0]->{completion} //= $_[0]->new_future($_[0] . ' completion')
}

=head2 pending_count

Returns the number of pending items that have not been processed by all
active sinks.

=cut

sub pending_count { 0 + @{ $_[0]{pending} } }

sub have_pending { @{ $_[0]{pending} } ? 1 : 0 }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2017. Licensed under the same terms as Perl itself.

