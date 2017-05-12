package Person;
use Pogo;
use PogoLink;
use Carp;
use strict;
use vars qw(@Fields %Fields);
BEGIN {
	@Fields = qw(NAME FATHER MOTHER FRIENDS CHILDREN);
	%Fields = map { $Fields[$_], $_+1 } (0 .. $#Fields);
	sub FIELDHASH { \%Fields }
}

sub new {
	my($class, $root, $name) = @_;
	my $self = new_tie Pogo::Harray 6, undef, $class;
	$self->{NAME}    = $name;
	$self->{FATHER}  = 
		new PogoLink::Scalar($self, 'Man',    'CHILDREN', undef);
	$self->{MOTHER}  = 
		new PogoLink::Scalar($self, 'Woman',  'CHILDREN', undef);
	$self->{FRIENDS} = 
		new PogoLink::Btree ($self, 'Person', 'FRIENDS', 'NAME');
	$self;
}
sub name {
	my $self = shift;
	$self->{NAME};
}
sub add_child {
	my($self, $person) = @_;
	$self->INIT_CHILDREN unless $self->{CHILDREN};
	$self->{CHILDREN}->add($person);
}
sub del_child {
	my($self, $person) = @_;
	return unless $self->{CHILDREN};
	$self->{CHILDREN}->del($person);
}
sub children {
	my $self = shift;
	return undef unless $self->{CHILDREN};
	$self->{CHILDREN}->getlist;
}
sub father {
	my $self = shift;
	$self->{FATHER}->get;
}
sub add_father {
	my($self, $person) = @_;
	$self->{FATHER}->add($person);
}
sub del_father {
	my($self, $person) = @_;
	$self->{FATHER}->del($person);
}
sub mother {
	my $self = shift;
	$self->{MOTHER}->get;
}
sub add_mother {
	my($self, $person) = @_;
	$self->{MOTHER}->add($person);
}
sub del_mother {
	my($self, $person) = @_;
	$self->{MOTHER}->del($person);
}
sub add_friend {
	my($self, $person) = @_;
	$self->{FRIENDS}->add($person);
}
sub del_friend {
	my($self, $person) = @_;
	$self->{FRIENDS}->del($person);
}
sub friends {
	my $self = shift;
	$self->{FRIENDS}->getlist;
}

package Man;
use vars qw(@ISA @Fields %Fields);
BEGIN {
	@ISA = qw(Person);
	@Fields = qw(WIFE);
	my %basefields = @ISA ? %{__PACKAGE__->SUPER::FIELDHASH} : ();
	my $basefields = keys %basefields;
	%Fields = (%basefields, 
		map { $Fields[$_], $_+$basefields+1 } (0 .. $#Fields));
	sub FIELDHASH { \%Fields }
}
sub INIT_CHILDREN {
	my($self) = @_;
	$self->{CHILDREN} = new PogoLink::Array ($self, 'Person', 'FATHER', undef);
}
sub INIT_WIFE {
	my($self) = @_;
	$self->{WIFE} = new PogoLink::Scalar($self, 'Woman',  'HUS',    undef);
}
sub show {
	my $self = shift;
	print "Father : ",$self->father->name,"\n" if $self->father;
	print "Mother : ",$self->mother->name,"\n" if $self->mother;
	print "Wife   : ",$self->wife->name,"\n" if $self->wife;
	print "Children : ",join(",",map($_->name,$self->children)),"\n" 
		if $self->children;
	print "Friends  : ",join(",",map($_->name,$self->friends)),"\n"
		if $self->friends;
}
sub wife {
	my $self = shift;
	return undef unless $self->{WIFE};
	$self->{WIFE}->get;
}
sub add_wife {
	my($self, $person) = @_;
	$self->INIT_WIFE unless $self->{WIFE};
	$self->{WIFE}->add($person);
}
sub del_wife {
	my($self, $person) = @_;
	return unless $self->{WIFE};
	$self->{WIFE}->del($person);
}

package Woman;
use vars qw(@ISA @Fields %Fields);
BEGIN {
	@ISA = qw(Person);
	@Fields = qw(HUS);
	my %basefields = @ISA ? %{__PACKAGE__->SUPER::FIELDHASH} : ();
	my $basefields = keys %basefields;
	%Fields = (%basefields, 
		map { $Fields[$_], $_+$basefields+1 } (0 .. $#Fields));
	sub FIELDHASH { \%Fields }
}
sub INIT_CHILDREN {
	my($self) = @_;
	$self->{CHILDREN} = new PogoLink::Array ($self, 'Person', 'MOTHER', undef);
}
sub INIT_HUS {
	my($self) = @_;
	$self->{HUS} = new PogoLink::Scalar($self, 'Man',    'WIFE',   undef);
}
sub show {
	my $self = shift;
	print "Father : ",$self->father->name,"\n" if $self->father;
	print "Mother : ",$self->mother->name,"\n" if $self->mother;
	print "Hus    : ",$self->hus->name,"\n" if $self->hus;
	print "Children : ",join(",",map($_->name,$self->children)),"\n" 
		if $self->children;
	print "Friends  : ",join(",",map($_->name,$self->friends)),"\n"
		if $self->friends;
}
sub hus {
	my $self = shift;
	return undef unless $self->{HUS};
	$self->{HUS}->get;
}
sub add_hus {
	my($self, $person) = @_;
	$self->INIT_HUS unless $self->{HUS};
	$self->{HUS}->add($person);
}
sub del_hus {
	my($self, $person) = @_;
	return unless $self->{HUS};
	$self->{HUS}->del($person);
}

1;
