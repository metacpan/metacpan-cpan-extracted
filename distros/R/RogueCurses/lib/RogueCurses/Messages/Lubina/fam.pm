package RogueCurses::Messages::Lubina::fam;

### 
### Fuzzy Associative Matrix 
###

use RogueCurses::Messages::Lubina::matrixmn;

sub new {
	my ($class, $m, $n, $wordmatrixrowtype, $wordmatrixcoltype) = @_;

	my $self = { 
		### The word matrix contains a row and column of match words
		### therefor its dimension is 1 higher than normal
		wordmatrix => RogueCurses::Messages::Lubina::matrixmn->new($m, $n),
		### these are strings that can be parsed in a message parser
		### e.g. if the rowtype is hitpoints, its values will be
		### weakhpr highhp
		wordmatrixrowtype => $wordmatrixrowtype,
		wordmatrixcoltype => $wordmatrixcoltype,
	

		numbermatrix => RogueCurses::Messages::Lubina::matrixmn->new($m, $n), 
	};

	$class = ref($class) || $class;
	bless $self, $class;
}

sub add_number_row {
	my ($self, @l) = @_;

	$self->{numbermatrix}->add_number_row(@l);	
}

sub add_word_row {
	my ($self, @l) = @_;

	$self->{wordmatrix}->add_number_row(@l);	
}

sub search_number_matrix {
	my ($self, $row, $col) = @_;

	return $self->{wordmatrix}->mnth($row,$col);
}

sub search_word_matrix {
	my ($self, $rowword, $columnword) = @_;
	my $rowindex = -1;
	my $columnindex = -1;

	### word matrix has unique row and column words (else the first one
	### gets returned)
	## the first row contains the $rowword
	@firstrowwithmatchwords = $self->{wordmatrix}->get_row[0];
	for (my $i = 0; $i < $self->{wordmatrix}->{m}; $i++) {
		if (@firstrowwithmatchwords[$i] == $rowword) {
			$rowindex = $i;
			last;
		}
	}

	for (my $i = 0; $i < $self->{wordmatrix}->{n}; $i++) {
		my $word = $self->{wordmatrix}->get_row()[$i];
		if ($word == $columnword) {
			$columnindex = $i;
			last;
		}
	}
			
	if ($rowindex >= 0 and $columnindex >= 0) {
		return $self->{wordmatrix}->mnth($rowindex, $columnindex);
	} else {
		return -1;
	}
			
}

1;
