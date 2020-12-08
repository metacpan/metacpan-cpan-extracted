package RogueCurses::Messages::Lubina::fam;

### 
### Fuzzy Associative Matrix 
###

use RogueCurses::Messages::Lubina::matrixmn;

sub new {
	my ($class, $m, $n) = @_;

	my $self = { 
		wordmatrix => RogueCurses::Messages::Lubina::matrixmn->new($m, $n),
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

sub search_word_matrix {
	my ($self, $row, $col) = @_;

	return $self->{wordmatrix}->mnth($row,$col);
}

1;
