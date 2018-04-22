package Report_HTML_DB::Models::Application::TRFSearch;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

This class will be used like a model responsible of results from tandem repeats annotation

=cut

has contig			=>	(is => 'ro', isa => 'Str');
has start			=>	(is => 'ro', isa => 'Str');
has end				=>	(is => 'ro', isa => 'Str');
has 'length'		=>	(is => 'ro', isa => 'Str');
has copy_number		=>	(is => 'ro', isa => 'Str');
has sequence		=>	(is => 'ro', isa => 'Str');
has feature_id		=> ( is => 'ro', isa => 'Str' );

sub setContig {
	my ($self, $contig) = @_;
	$self->{contig} = $contig;
	return $self->{contig};
}

sub getContig {
	my($self) = @_;
	return $self->{contig};
}

sub setStart {
	my ($self, $start) = @_;
	$self->{start} = $start;
	return $self->{start};
}

sub getStart {
	my($self) = @_;
	return $self->{start};
}

sub setEnd {
	my ($self, $end) = @_;
	$self->{end} = $end;
	return $self->{end};
}

sub getEnd {
	my($self) = @_;
	return $self->{end};
}

sub setLength {
	my ($self, $length) = @_;
	$self->{'length'} = $length;
	return $self->{'length'};
}

sub getLength {
	my($self) = @_;
	return $self->{'length'};
}

sub setCopyNumber {
	my($self, $copy_number) = @_;
	$self->{copy_number} = $copy_number;
	return $self->{copy_number};
}

sub getCopyNumber {
	my($self) = @_;
	return $self->{copy_number};
}

sub setSequence {
	my($self, $sequence) = @_;
	$self->{sequence} = $sequence;
	return $self->{sequence};
}

sub getSequence {
	my($self) = @_;
	return $self->{sequence};
}

sub setFeatureID {
	my ( $self, $feature_id) = @_;
	$self->{feature_id} = $feature_id;
	return $self->{feature_id};
}

sub getFeatureID {
	my ($self) = @_;
	return $self->{feature_id};
}

1;