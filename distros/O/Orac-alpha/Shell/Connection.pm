#
#
#
package Shell::Connection;
use strict;
use Carp;

my $DBCONNECT = {
	label => undef,
	dbh		=> undef,
	db_type => undef,
};

sub new {
	my $proto = shift; 
	my $class = ref($proto) || $proto;

	my $self  = {
			name => \$DBCONNECT,
		};
	bless($self, $class);
}

sub default {
	my $self = shift;
}

sub name {
	my $self = shift;
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $option = $AUTOLOAD;
	$option =~ s/.*:://;
	
	unless (exists $self->{$option}) {
		croak "Can't access '$option' field in object of class $type";
	}
	if (@_) {
		return $self->{$option} = shift;
	} else {
		return $self->{$option};
	}
	croak qq{This line shouldn't ever be seen}; #'
}

1;
