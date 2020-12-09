package RogueCurses::Messages::Lubina::matrixmn;

### 
### m x n matrix class
###

sub new {
	my ($class, $lines, $cols) = @_;

	$self = { m => $cols, n => $lines, mat => () };

	$class = ref($class) || $class;
	bless $self, $class;
}

sub add_row {
	my ($self, @l) = @_;

	push($self->{mat}, @l);
}

sub get_row {
	my ($self, $i) = @_;

	return $self->{mat}[$i];;
}

### return m[row][col]
sub mnth {
	my ($self, $j, $i) = @_;

	return $self->{mat}[$i][$j];
}

### multiply by vector (vector is an array)
sub multiply_by_vector {
	my ($self, @v) = @_;

	my @retv = ();
#	$#retv = $self->{m}; ### init array length
#	for (my $i = 0; $i < $self->{m}; $i++) {
#		@retv[$i] = 0;
#	}

	for (my $i = 0; $i < $self->{n}; $i++) {
		my $val = 0;
		for (my $j = 0; $j < $self->{m}; $j++) {
			$val = $val + $self->{mat}[$j][$i] * @v[j]);
		}
		push (@retv, $val);
	}

	return @retv;
}

### multiply by matrix 
sub multiply_by_matrix {
	my ($self, $m) = @_;

	my $retm = RogueCurses::Messages::Lubina::matrixmn->new;

	for (my $i = 0; $i < $self->{n}; $i++) {
		my @valv = $self->multiply_by_vector($m->{mat}[$i]);
			
		$retm->add_row(@valv);
	}

	return $retm;
}

sub determinant {
	my $self = shift;

	my $det = 0;

	for (my $i = 0; $i < $self->{n}; $i++) {
		my $val = 0;
		for (my $j = 0; $j < $self->{m}; $j++) {
			my $k = 0;
			$val = $val + $self->{mat}[$j][$i + $k++]  
		}
		$det += $val;	
	}

	return $det;
}	
1;
