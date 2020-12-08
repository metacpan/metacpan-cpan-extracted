package RogueCurses::Messages::messagewords;

sub new {
	my $class = shift;
	my $self = { 
			dungeonnouns => gen_dungeon_nouns($entityname), 
			dungeonverbs => gen_dungeon_verbs($entityname),
			freenaturenouns => gen_freenature_nouns($entityname), 
			freenatureverbs => gen_freenature_verbs($entityname),
			creaturesnouns => gen_creatures_nouns($entityname), 
			creaturesverbs => gen_creatures_verbs($entityname),
	};

	$class = ref($class) || $class;
	bless $self, $class;
}

sub gen_dungeon_nouns {
	my ($self, $entityname) = @_;
	my %db = {};

	my $score = -1;

	%db[0] = ('candle', $score);
	%db[1] = ('wall', $score);
	%db[2] = ('chest', $score);

	return %db;
}

sub gen_dungeon_verbs {
	my ($self, $entityname) = @_;
	my %db = {};

	my $score = -1;

	return %db;
}

sub gen_freenature_nouns {
	my ($self, $entityname) = @_;
	my %db = {};

	my $score = -1;

	%db[0] = ('flower', $score);
	%db[1] = ('grass', $score);
	%db[2] = ('tree', $score);
	%db[3] = ('forest', $score);
	%db[4] = ('wood', $score);
	%db[4] = ('mountain', $score);

	return %db;
}

sub gen_freenature_verbs {
	my ($self, $entityname) = @_;
	my %db = {};

	my $score = -1;

	%db[0] = ('look', $score);
	%db[1] = ('rest', $score);

	return %db;
}

sub gen_creatures_nouns {
	my ($self, $entityname) = @_;
	my %db = {};

	my $score = -1;

	%db[0] = ('will-o'-the wisp', $score);
	%db[1] = ('gnome', $score);
	%db[2] = ('dragon', $score);
	%db[3] = ('crab', $score);
	%db[4] = ('fly', $score);
	%db[5] = ('newt', $score);
	%db[5] = ('troll', $score);
	%db[6] = ('mongbat', $score);

	return %db;
}

sub gen_creatures_verbs {
	my ($self, $entityname) = @_;
	my %db = {};

	my $score = -1;

	%db[0] = ('eat', $score);
	%db[1] = ('wander', $score);
	%db[2] = ('live', $score);

	return %db;
}

1;
