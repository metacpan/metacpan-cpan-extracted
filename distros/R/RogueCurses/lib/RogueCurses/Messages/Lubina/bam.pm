package RogueCurses::Messages::Lubina::bam;

### 
### Bi-Associative Matrix 
###

use RogueCurses::Messages::Lubina::matrixmn;

sub new {
	my ($class, $m, $n) = @_;

	my $self = { 
		matrix => RogueCurses::Messages::Lubina::matrixmn->new($m, $n),
	};

	$class = ref($class) || $class;
	bless $self, $class;
}

sub energy {
	my $self = shift;
	my $det =  $self->{matrix}->determinant;

	return ($det * $det);
}

1;
