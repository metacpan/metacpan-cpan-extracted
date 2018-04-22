package Report_HTML_DB::Models::Application::TranscriptionalTerminator;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

This class will be used to represent transcriptional terminator results

=cut

has contig         	=> ( is => 'ro', isa => 'Str' );
has start          	=> ( is => 'ro', isa => 'Str' );
has end            	=> ( is => 'ro', isa => 'Str' );
has confidence     	=> ( is => 'ro', isa => 'Str' );
has hairpin_score 	=> ( is => 'ro', isa => 'Str' );
has tail_score     	=> ( is => 'ro', isa => 'Str' );
has feature_id		=> ( is => 'ro', isa => 'Str' );

sub setContig {
	my ( $self, $contig ) = @_;
	$self->{contig} = $contig;
	return $self->{contig};
}

sub getContig {
	my ($self) = @_;
	return $self->{contig};
}

sub setStart {
	my ( $self, $start ) = @_;
	$self->{start} = $start;
	return $self->{start};
}

sub getStart {
	my ($self) = @_;
	return $self->{start};
}

sub setEnd {
	my ( $self, $end ) = @_;
	$self->{end} = $end;
	return $self->{end};
}

sub getEnd {
	my ($self) = @_;
	return $self->{end};
}

sub setConfidence {
	my ( $self, $confidence ) = @_;
	$self->{confidence} = $confidence;
	return $self->{confidence};
}

sub getConfidence {
	my ($self) = @_;
	return $self->{confidence};
}

sub setHairpinScore {
	my ( $self, $hairpin_score ) = @_;
	$self->{hairpin_score} = $hairpin_score;
	return $self->{hairpin_score};
}

sub getHairpinScore {
	my ($self) = @_;
	return $self->{hairpin_score};
}

sub setTailScore {
	my ( $self, $tail_score ) = @_;
	$self->{tail_score} = $tail_score;
	return $self->{tail_score};
}

sub getTailScore {
	my ($self) = @_;
	return $self->{tail_score};
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