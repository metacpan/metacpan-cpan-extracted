package RSA::Toolkit;

use 5.008008;
use strict;
use warnings;
use DynaLoader;
use Data::Dumper;

our $VERSION = '0.04';
our @ISA = qw(DynaLoader);

bootstrap RSA::Toolkit;


sub new{
	my $class = shift;
	my $type = ref($class) || $class;
	my $self = bless {}, $type;

	$self->connect;
	$self;
}

sub fetch_user {
	my $self = shift;
	my $login = shift;

	use RSA::Toolkit::User;
	my $user = $self->_fetch_user($login);
	$user->_reformat;
}

sub fetch_users {
	my $self = shift;
	my $arg_ref = { @_ };

	my $field = $arg_ref->{'field'} || 0;
	my $type = $arg_ref->{'type'} || 0;
	my $value = $arg_ref->{'value'} || '';
	my $group = $arg_ref->{'group'} if $arg_ref->{'group'};
	
	use RSA::Toolkit::User;
	my $user;
	if ($group) {
		while(my $user_group = $self->_fetch_users_by_group($group)) {
			return if $user_group eq 'Done';
			my ($_login, $_group) = split(/ \| /, $user_group);
			$user = $self->_fetch_user($_login);
			next if !$user;
			last;
		}
	}else{
		$user = $self->_fetch_users($field, $type, $value);
	}
	return $user->_reformat;
}

sub fetch_groups {
	my $self = shift;

	grep { s/ ,\s+$// } @{ $self->_fetch_groups };
}


1;

