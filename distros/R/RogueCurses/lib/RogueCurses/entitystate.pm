package RogueCurses::entitystate;

### NPC stats

use RogueCurses::RNG;

sub new {
	my ($class) = @_;
	my $self = { 
		str => -1, # Strength 
		dex => -1, # Dexterity
		int => -1, # Intelligence
		luck => -1,# Luck 
		wis => -1, # Wisdom
		con => -1, # Constitution
		hp => 1,   # Hit Points
		xp = 1,    # Experience Points
		rng => RogueCurses::RNG->new,  };

	$self->generate_entity_stats;
	$self->generate_entity_hp;
	$self->generate_entity_xp;

	$class = ref($class) || $class;

	bless $self, $class;
}

sub generate_entity_stats {
	my $self = shift;

	$self->{str} = $self->{rng}->rolld18;	
	$self->{dex} = $self->{rng}->rolld18;	
	$self->{int} = $self->{rng}->rolld18;	
	$self->{luck} = $self->{rng}->rolld18;	
	$self->{wis} = $self->{rng}->rolld18;	
	$self->{con} = $self->{rng}->rolld18;	
};

sub generate_entity_hp {
	my $self = shift;

	$self->{hp} = $self->{rng}->rolld4;
}

sub generate_entity_xp {
	my $self = shift;

	$self->{xp} = $self->{rng}->rolldX(20);
}

1;
