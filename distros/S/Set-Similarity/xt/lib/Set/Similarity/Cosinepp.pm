package Set::Similarity::Cosinepp;

use strict;
use warnings;

use parent 'Set::Similarity';

#use PDL;
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
	
	#print STDERR 'tokens1: ', Dumper($tokens1),"\n";
	#print STDERR 'tokens2: ', Dumper($tokens2),"\n";
	
	
	$self->make_elem_list($tokens1,$tokens2);
	
	#print STDERR 'elem_index: ', Dumper($self->{'elem_index'}),"\n";
	#print STDERR 'elem_list: ', Dumper($self->{'elem_list'}),"\n";
	#print STDERR 'elem_count: ', Dumper($self->{'elem_count'}),"\n";
	
	my $vec1 = $self->make_vector( $tokens1 );
	my $vec2 = $self->make_vector( $tokens2 );
	
	
	my $cosine = $self->cosine( $self->normalize($vec1), $self->normalize($vec2) );
	
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
	#my %elements = $self->get_elements( $tokens );
	#print STDERR '%elements: ',Dumper(\%elements),"\n";	
	my $vector = $self->zeros($self->{'elem_count'});
	
	for my $key ( @$tokens ) {
		my $value = 1;
		my $offset = $self->{'elem_index'}->{$key};
		$vector->[$offset] = $value;
	}
	#print STDERR '$vector: ',Dumper($vector),"\n";
	return $vector;
}

sub make_elem_list {
	my ( $self,$tokens1,$tokens2 ) = @_;
	my %all_elems;
	@all_elems{@$tokens1,@$tokens2} = ();
	#@all_elems{@$tokens2} = ();
	#print STDERR '%all_elems: ',Dumper(\%all_elems),"\n";	
	
	# create a lookup hash
	my %lookup;
	$self->{'elem_list'} = [sort keys %all_elems];
	$self->{'elem_count'} = scalar @{$self->{'elem_list'}};
	@lookup{@{$self->{'elem_list'}}} = (0..$self->{'elem_count'}-1 );
	#print STDERR '%lookup: ',Dumper(\%lookup),"\n";	
	
	$self->{'elem_index'} = \%lookup;
}

# Assumes both incoming vectors are normalized
sub cosine {
	my ( $self, $vec1, $vec2 ) = @_;
	#print STDERR '$vec1: ',Dumper($vec1),"\n";
	#print STDERR '$vec2: ',Dumper($vec2),"\n";
	my $cos = $self->dot( $vec1, $vec2 );	# inner product
	return $cos;
}

sub norm {
  my $self = shift;
  my $vector = shift;
  my $sum = 0;
  for my $index (0..scalar(@$vector)-1) {
    my $value = $vector->[$index];
    $sum += $value ** 2;
  }
  return sqrt $sum;
}

sub normalize {
  my $self = shift;
  my $vector = shift;
  my $vnorm = $self->norm($vector);

  return $self->div($vector,$vnorm);
}

sub zeros {
  my $self = shift;
  my $count = shift;
  my $vector = [];
  for my $index (0..$count-1) {
    $vector->[$index] = 0;
  }
  return $vector;
}

sub dot {
    my $self = shift;
    my $v1 = shift;
    my $v2 = shift;

    my $dotprod = 0;

    for my $index (0..scalar(@$v1)-1) {
      $dotprod += $v1->[$index] * $v2->[$index];
    }

    return $dotprod;
}

# divides each vector entry by a given divisor
sub div {
    my $self = shift;
    my $vector = shift;
    my $divisor = shift;

    my $vector2 = [@$vector];
    for my $index (0..scalar(@$vector2)-1) {
        $vector2->[$index] /= $divisor;
    }
    return $vector2;
}


1;
