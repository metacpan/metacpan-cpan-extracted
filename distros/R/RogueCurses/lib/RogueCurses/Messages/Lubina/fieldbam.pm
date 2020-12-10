package RogueCurses::Messages::Lubina::fieldbam;

### 
### Bi-Associative Matrix with developed somewhat random fielded 
### filled in values. One needs to enter a premutation of values
### for each row/column (or less, the matrix is integer random valued to start
###

use parent 'RogueCurses::Messages::Lubina::bam';

sub new {
	my ($class, $integer_precision, $n) = @_;

	my $self = $class->SUPER::new($n,$n);

	for (my $i = 0; $i < $self->{matrix}->{n}; $i++) {
		my @randomstartvalues = ();
		for (my $j = 0; $j < $self->{matrix}->{n}; $j++) {
			push(@randomstartvalues, 1 / int(rand($integer_precision)));
		}
		$self->{matrix}->add_row(@randomstartvalues);
	}
}

sub add_and_permute {
	### @values to be filled in does not grow your matrix, it's maximum
	### length is n x n
	my ($self, @values) = @_;

	my $rowoffset = 0;
	my $coloffset = 0;
	for (my $i = 0; $i < int($#values / $self->matrix->{n}); $i++) {
		for (my $j = 0; $j < $self->{matrix}->{n}; $j++) {
			$self->{matrix}->{mat}[$j+$i*$self->{matrix}->{n}] = @values[$j+$i*$self->{matrix}->{n}];
			$rowoffset++;
		}
		$coloffset++;
	}	
 
	$rowoffset %= $self->{matrix}->{n};
	$coloffset %= $self->{matrix}->{n};
	### n x n - remainder, last remaining @values indexes
	my $backwardoffset = $self->{matrix}->{n} * 2 - ($#values % $self->{matrix}->{n});

	for (my $i = 0; $i < $#values % $self->{matrix}->{n}; $i++) {
		$self->{matrix}->{mat}[$rowoffset][$coloffset] = @values[$backwardoffset++]
	}
}

sub permute_row {
	### substitute row [$i] for [$j]
	my ($self, $i, $j) = @_;

	my $row = $self->{matrix}->{mat}[$j];

	$self->{matrix}->{mat}[$j] = $self->{matrix}->{mat}[$i];
	$self->{matrix}->{mat}[$i] = $row;
}

sub permute_column {
	### substitute column [$i] for [$j]
	my ($self, $coli, $colj) = @_;

	my @column = ();		

	for (my $i = 0; $i < $self->{matrix}->{n}; $i++) {
		push(@column, $self->{matrix}->{mat}[$i][$colj]);
	}	
	for (my $i = 0; $i < $self->{matrix}->{n}; $i++) {
		$self->{matrix}->{mat}[$i][$colj] = $self->{matrix}->{mat}[$i][$coli];
	} 
	for (my $i = 0; $i < $self->{matrix}->{n}; $i++}) {
		$self->{matrix}->{mat}[$i][$coli] = column[$i];
	} 
}

1;
