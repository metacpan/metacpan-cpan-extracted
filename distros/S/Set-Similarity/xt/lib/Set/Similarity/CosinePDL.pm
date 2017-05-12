package Set::Similarity::CosinePDL;

use strict;
use warnings;

use parent 'Set::Similarity';

use PDL;
use Data::Dumper;


sub from_sets {
	my ($self, $set1, $set2) = @_;
	return $self->_similarity(
		[keys %$set1],
		[keys %$set2]
	);
}

sub _similarity {
	my ( $self, $tokens1,$tokens2 ) = @_;
	
	$self->make_elem_list($tokens1,$tokens2);
	
	#print STDERR 'elem_index: ', Dumper($self->{'elem_index'}),"\n";
	#print STDERR 'elem_list: ', Dumper($self->{'elem_list'}),"\n";
	#print STDERR 'elem_count: ', Dumper($self->{'elem_count'}),"\n";
	
	my $vec1 = $self->make_vector( $tokens1 );
	my $vec2 = $self->make_vector( $tokens2 );
	
	
	my $cosine = $self->cosine( norm($vec1), norm($vec2) );
	
	#print STDERR 'cosine: ',$cosine,"\n";
	
	return $cosine;
}

sub build_index {
	my ( $self ) = @_;
	$self->make_word_list();
	my @vecs;
	for my $doc ( @{ $self->{'docs'} }) {
		my $vec = $self->make_vector( $doc );
		push @vecs, norm $vec;
	}
	$self->{'doc_vectors'} = \@vecs;
	print "Finished with word list\n";
}

sub make_vector {
	my ( $self, $tokens ) = @_;
	my %elements = $self->get_elements( $tokens );
	#print STDERR '%elements: ',Dumper(\%elements),"\n";	
	my $vector = zeroes $self->{'elem_count'};
	
	for my $key ( keys %elements ) {
		my $value = $elements{$key};
		my $offset = $self->{'elem_index'}->{$key};
		index( $vector, $offset ) .= $value;
	}
	#print STDERR '$vector: ',$vector,"\n";
	return $vector;
}

sub get_elements {			
	my ( $self, $tokens ) = @_;
	my %elements;  
	do { $_++ } for @elements{@$tokens};
	return %elements;
}	

sub make_elem_list {
	my ( $self,$tokens1,$tokens2 ) = @_;
	my %all_elems;
	for my $tokens ( $tokens1,$tokens2 ) {
		my %elements = $self->get_elements( $tokens );
		for my $key ( keys %elements ) {
			#print "Word: $k\n";
			$all_elems{$key} += $elements{$key};
		}
	}
	
	# create a lookup hash
	my %lookup;
	my @sorted_elems = sort keys %all_elems;
	@lookup{@sorted_elems} = (0..scalar(@sorted_elems)-1 );
	
	$self->{'elem_index'} = \%lookup;
	$self->{'elem_list'} = \@sorted_elems;
	$self->{'elem_count'} = scalar @sorted_elems;
}

# Assumes both incoming vectors are normalized
sub cosine {
	my ( $self, $vec1, $vec2 ) = @_;
	#print STDERR '$vec1: ',$vec1,"\n";
	#print STDERR '$vec2: ',$vec2,"\n";
	my $cos = inner( $vec1, $vec2 );	# inner product
	return $cos->sclr();  # converts PDL object to Perl scalar
}

1;
