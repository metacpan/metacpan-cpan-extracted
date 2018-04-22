package Report_HTML_DB::Models::Application::NcRNASearch;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

Class used to represent non coding RNA search result

=cut

has id           => ( is => 'ro', isa => 'Str' );
has contig       => ( is => 'ro', isa => 'Str' );
has start        => ( is => 'ro', isa => 'Str' );
has end          => ( is => 'ro', isa => 'Str' );
has description  => ( is => 'ro', isa => 'Str' );
has target_ID    => ( is => 'ro', isa => 'Str' );
has evalue       => ( is => 'ro', isa => 'Str' );
has target_name  => ( is => 'ro', isa => 'Str' );
has target_class => ( is => 'ro', isa => 'Str' );
has target_type  => ( is => 'ro', isa => 'Str' );

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

sub setDescription {
	my ( $self, $description ) = @_;
	$self->{description} = $description;
	return $self->{description};
}

sub getDescription {
	my ($self) = @_;
	return $self->{description};
}

sub setTargetID {
	my ( $self, $target_ID ) = @_;
	$self->{target_ID} = $target_ID;
	return $self->{target_ID};
}

sub getTargetID {
	my ($self) = @_;
	return $self->{target_ID};
}

sub setEvalue {
	my ( $self, $evalue ) = @_;
	$self->{evalue} = $evalue;
	return $self->{evalue};
}

sub getEvalue {
	my ($self) = @_;
	return $self->{evalue};
}

sub setTargetName {
	my ( $self, $target_name ) = @_;
	$self->{target_name} = $target_name;
	return $self->{target_name};
}

sub getTargetName {
	my ($self) = @_;
	return $self->{target_name};
}

sub setTargetClass {
	my ( $self, $target_class ) = @_;
	$self->{target_class} = $target_class;
	return $self->{target_class};
}

sub getTargetClass {
	my ($self) = @_;
	return $self->{target_class};
}

sub setTargetType {
	my ( $self, $target_type ) = @_;
	$self->{target_type} = $target_type;
	return $self->{target_type};
}

sub getTargetType {
	my ($self) = @_;
	return $self->{target_type};
}

1;
