package Report_HTML_DB::Models::Application::AlienHunterSearch;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

This is a class of a alien hunter result search

=cut

has id        	=> ( is => 'ro', isa => 'Str' );
has contig    	=> ( is => 'ro', isa => 'Str' );
has start     	=> ( is => 'ro', isa => 'Str' );
has end       	=> ( is => 'ro', isa => 'Str' );
has 'length'  	=> ( is => 'ro', isa => 'Str' );
has score     	=> ( is => 'ro', isa => 'Str' );
has threshold 	=> ( is => 'ro', isa => 'Str' );
has feature_id	=> ( is => 'ro', isa => 'Str' );

sub setID {
	my ( $self, $id ) = @_;
	$self->{id} = $id;
	return $self->{id};
}

sub getID {
	my ($self) = @_;
	return $self->{id};
}

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

sub setLength {
	my ( $self, $length ) = @_;
	$self->{length} = $length;
	return $self->{length};
}

sub getLength {
	my ($self) = @_;
	return $self->{length};
}

sub setScore {
	my ( $self, $score ) = @_;
	$self->{score} = $score;
	return $self->{score};
}

sub getScore {
	my ($self) = @_;
	return $self->{score};
}

sub setThreshold {
	my ( $self, $threshold ) = @_;
	$self->{threshold} = $threshold;
	return $self->{threshold};
}

sub getThreshold {
	my ($self) = @_;
	return $self->{threshold};
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
