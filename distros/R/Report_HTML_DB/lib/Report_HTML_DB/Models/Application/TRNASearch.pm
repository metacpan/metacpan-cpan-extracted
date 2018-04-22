package Report_HTML_DB::Models::Application::TRNASearch;
use Moose;
use MooseX::Storage;
with Storage('format'	=>	'JSON');

=pod

This class will be used like a model responsible of results from tRNA annotations

=cut

has id			=>	(is => 'ro', isa => 'Str');
has sequence	=>	(is => 'ro', isa => 'Str');
has amino_acid	=>	(is => 'ro', isa => 'Str');
has codon		=>	(is => 'ro', isa => 'Str');

sub setID {
	my ($self, $id) = @_;
	$self->{id} = $id;
	return $self->{id};
}

sub getID {
	my($self) = @_;
	return $self->{id};
}

sub setSequence {
	my ($self, $sequence) = @_;
	$self->{sequence} = $sequence;
	return $self->{sequence};
}

sub getSequence {
	my($self) = @_;
	return $self->{sequence};
}

sub setAminoAcid {
	my ($self, $amino_acid) = @_;
	$self->{amino_acid} = $amino_acid;
	return $self->{amino_acid};
}

sub getAminoAcid {
	my($self) = @_;
	return $self->{amino_acid};
}

sub setCodon {
	my ($self, $codon) = @_;
	$self->{codon} = $codon;
	return $self->{codon};
}

sub getCodon {
	my($self) = @_;
	return $self->{codon};
}
1;