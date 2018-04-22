package Report_HTML_DB::Models::Application::RBSSearch;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

This class will be used to represent ribosomal binding site results

=cut

has contig         => ( is => 'ro', isa => 'Str' );
has start          => ( is => 'ro', isa => 'Str' );
has end            => ( is => 'ro', isa => 'Str' );
has site_pattern   => ( is => 'ro', isa => 'Str' );
has old_start      => ( is => 'ro', isa => 'Str' );
has old_position   => ( is => 'ro', isa => 'Str' ); 
has position_shift => ( is => 'ro', isa => 'Str' );
has new_start      => ( is => 'ro', isa => 'Str' );
has feature_id	=> ( is => 'ro', isa => 'Str' );

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

sub setSitePattern {
	my ( $self, $site_pattern ) = @_;
	$self->{site_pattern} = $site_pattern;
	return $self->{site_pattern};
}

sub getSitePattern {
	my ($self) = @_;
	return $self->{site_pattern};
}

sub setOldStart {
	my ( $self, $old_start ) = @_;
	$self->{old_start} = $old_start;
	return $self->{old_start};
}

sub getOldStart {
	my ($self) = @_;
	return $self->{old_start};
}

sub setOldPosition {
	my ( $self, $old_position ) = @_;
	$self->{old_position} = $old_position;
	return $self->{old_position};
}

sub getOldPosition {
	my ($self) = @_;
	return $self->{old_position};
}

sub setPositionShift {
	my ( $self, $position_shift ) = @_;
	$self->{position_shift} = $position_shift;
	return $self->{position_shift};
}

sub getPositionShift {
	my ($self) = @_;
	return $self->{position_shift};
}

sub setNewStart {
	my ( $self, $new_start ) = @_;
	$self->{new_start} = $new_start;
	return $self->{new_start};
}

sub getNewStart {
	my ($self) = @_;
	return $self->{new_start};
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
