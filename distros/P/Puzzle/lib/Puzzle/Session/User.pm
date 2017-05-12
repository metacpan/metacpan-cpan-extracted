package Puzzle::Session::User;

our $VERSION = '0.02';

use Puzzle::Utility;

use Params::Validate qw(:types);;
use base 'Class::Container';

use HTML::Mason::MethodMaker(
				read_write => [ 
					[id => { parse => 'string', type => SCALAR }],
					[gid => { parse => 'list', type => ARRAYREF }],
					[auth => { type => BOOLEAN }],
					[time_login => { parse => 'string', type => SCALAR }],
					[time_last_login => { parse => 'string', type => SCALAR }],
				]
				
);

sub new {
	my $class 	= shift;
	my $self 	= $class->SUPER::new(@_);
	$self->default;
	return $self;
}

sub default {
	my $self	= shift;
	delete $self->{id};
	$self->gid(['everybody','anonymous']);
	delete $self->{auth};
	delete $self->{time_login};
	delete $self->{time_last_login};
}

sub load {
	my $self	= shift;
	$self->default;
	$self->_hash2obj;
}

sub save {
	my $self	= shift;
	$self->_obj2hash;
}

sub isGid {
	my $self		= shift;
  my $gid2ver	= shift;
  my @ugids 	= @{$self->gid};
  my @gids  	= ref($gid2ver) eq 'ARRAY' ? @$gid2ver : ($gid2ver);
  foreach my $ugid (@ugids) {
    return 1 if &isIn($ugid,@gids);
  } 
  return 0;
}

sub _hash2obj {
	my $self	= shift;
	foreach (qw/id gid auth time_login time_last_login/) {
	  if (exists $self->container->internal_session->{user}->{$_}) {
			$self->{$_}   = $self->container->internal_session->{user}->{$_} ;
		}
	}
}

sub _obj2hash {
	my $self	= shift;
	foreach (qw/id gid auth time_login time_last_login/) {
	  if (exists $self->{$_}) {
			$self->container->internal_session->{user}->{$_}   = $self->{$_};
		} else {
			delete $self->container->internal_session->{user}->{$_};
		}
	}
}



1;
