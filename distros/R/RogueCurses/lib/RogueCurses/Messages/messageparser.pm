package RogueCurses::Messages::messageparser;

use Curses;

### NOTE : build in an engine (inference?) for parsing messages which
###	   are displayed then talk about surroundings

sub new {
	my $class = shift;
	my $self = { 
		words => RogueCurses::Messages::messagewords->new,
	};
	$class = ref($class) || $class;

	bless $self, $class;
}

### partial grep of parser
sub parse_speed_partial_grep {
	### $surroundings is an instance of a class
	my ($self, $msg, $surroundings) = @_;

	### split $msg into words
	my @listmsg = split(/( |,|, | ,| , |.|. |'| '| ' )/, $msg);
	my $p = -1; ### output probability
	
	my @freenature = values $self->{words}->{freenaturenouns}; 
	my @dungeon = values $self->{words}->{dungeonnouns};
	my @creatures = values $self->{words}->{creaturesnouns};

	my @values = ();

	### NOTE $surroundings

	if ($surroundings->is_dungeon) {
		### remove scores (ns == no score), constant speed, remove each parse 
		my (@dungeonns, @creaturesns) = 
			$self->get_words_remove_scores((values @dungeon, 
					values @creatures));

		for (my $i = 0; $i < $#listmsg; $i++) {
			push (@values,  grep(@listmsg[$i], @dungeonns));
			push (@values,  grep(@listmsg[$i], @creaturesns));
		}
	} else if ($surroundings->is_wood) {
		### remove scores (ns == no score), constant speed, remove each parse 
		my (@freenaturens, @creaturesns) = 
			$self->get_words_remove_scores((values @freenature, 
					values @creatures));

		for (my $i = 0; $i < $#listmsg; $i++) {
			push (@values, grep(@listmsg[$i], @freenaturens));
			push (@values,  grep(@listmsg[$i], @creaturesns));
		}
	}	

	### @values is a list of words containing $msg words
	my $lubina = RogueCurses::Messages::Lubina::lubina->new;
	$p = $lubina->work_on_mulitple_words(@values);
	return $lubina->{probability} = $p and $p;
}

sub get_words_remove_scores(@nounslists)
{
	my $self = shift;
	my @retl = ();

	for (my $i = 0; $i < $#nounslists; $i++) {
		my @l = ();
		for (my $j = 0; $j < $#nounslists[$i]; $j++) {
			push(@l, @nounslists[$i][$j][0]);
		}
		push(@retl, @l);
	}

	return @retl;
}

1;
