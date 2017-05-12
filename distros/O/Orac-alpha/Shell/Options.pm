
package Shell::Options;

use strict;
use Carp;

sub new {
	my $proto = shift; 
	my $class = ref($proto) || $proto;

	my $self  = {
			autoexec				=> 1,
			debug						=> $main::debug,
			display_format	=> q{neat},
			editor					=> qq{vi},
			font						=> undef,
			ignore_comments => 0,
			mini_main_wd		=> 1,
   		rows						=> q{all},
			statement_term  => q{[;/]},
			stop_on_error 	=> 1,
			write_error_rslt => 0,
		};
	bless($self, $class);
}

sub opt_keys {
	my $self = shift;
	return keys %$self;
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
