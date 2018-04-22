package Report_HTML_DB::Models::Application::Subevidence;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

Class used to represent data of subevidence

=cut

has id                  => ( is => 'ro', isa => 'Str' );
has type                => ( is => 'ro', isa => 'Str' );
has number              => ( is => 'ro', isa => 'Str' );
has start               => ( is => 'ro', isa => 'Str' );
has end                 => ( is => 'ro', isa => 'Str' );
has strand              => ( is => 'ro', isa => 'Str' );
has is_obsolete         => ( is => 'ro', isa => 'Str' );
has program             => ( is => 'ro', isa => 'Str' );
has program_description => ( is => 'ro', isa => 'Str' );

sub setID {
	my ( $self, $id ) = @_;
	$self->{id} = $id;
	return $self->{id};
}

sub getID {
	my ($self) = @_;
	return $self->{id};
}

sub setType {
	my ( $self, $type ) = @_;
	$self->{type} = $type;
	return $self->{type};
}

sub getType {
	my ($self) = @_;
	return $self->{type};
}

sub setNumber {
	my ( $self, $number ) = @_;
	$self->{number} = $number;
	return $self->{number};
}

sub getNumber {
	my ($self) = @_;
	return $self->{number};
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

sub setStrand {
	my ( $self, $strand ) = @_;
	$self->{strand} = $strand;
	return $self->{strand};
}

sub getStrand {
	my ($self) = @_;
	return $self->{strand};
}

sub setIsObsolete {
	my ( $self, $is_obsolete ) = @_;
	$self->{is_obsolete} = $is_obsolete;
	return $self->{is_obsolete};
}

sub getIsObsolete {
	my ($self) = @_;
	return $self->{is_obsolete};
}

sub setProgram {
	my ( $self, $program ) = @_;
	$self->{program} = $program;
	return $self->{program};
}

sub getProgram {
	my ($self) = @_;
	return $self->{program};
}

sub setProgramDescription {
	my ( $self, $description ) = @_;
	$self->{program_description} = $description;
	return $self->{program_description};
}

sub getProgramDescription {
	my ($self) = @_;
	return $self->{program_description};
}

1;
