package RogueCurses::Messages::Lubina::lubina;

### 
### Lubina is a Sampling and/or Strategy library
###

sub new {
	my ($class) = @_;

	$self = { probability => -1, highwords => (), };

	$class = ref($class) || $class;
	bless $self, $class;
}

sub work_on_mulitple_words {
	my ($self, @values) = @_; ### @values is a list of lists of words, containging a message word (message gets split up)

	if ($#values <= 0) {
		return $self->{probability};
	}

	my @ps = ();
	my $c = 0;
	my $lastword = @values[0];
	for (my $i = 0; $i < $#values, $i++) {
		if ($lastword == @values[$i]) {
			@ps[$c] += 0.01; ### there are never 100 occurences of a word
		} else {
			$c++;
			push(@ps, 0.01);
		}
	}

	$self->{probability} = max(@ps);
	$self->set_highword(@ps, @values);

	### FIXME permutate matrix (fill in row by row) with @ps
}

sub set_highwords
{
	my ($self, @counts, @words) = @_;
	
	for (my $i = 0; $i < $#counts; $i++) {
		if (@counts[$i] == $self->{probability}) {
			push ($self->{highwords}, @words[$i]);
		}
	}
}

1;
