package SystemManagement::GSP;

use 5.006;
use strict;
use warnings;
use IO::Socket::INET;
use Expect;

use Carp qw(confess);

our @ISA = qw(Exporter);

our $VERSION = 1.000_000;

=head1 NAME

SystemManagement::GSP - Perl extension for GSP remote system management

=head1 SYNOPSIS

  use SystemManagement::GSP;
  
  my $manage=SystemManagement::GSP->new( host => 'hostname' );
  my $rc = $manage->is_powered_on();
  if (!defined($rc)) {
	die $manage->errmsg();
  }
  elsif ($rc==0) {
	$manage->power_on();
  }
  else {
	$manage->power_off();
  }

=head1 DESCRIPTION

SystemManagement::GSP is used to control GSP-based telnet interfaces
found on Hewlett-Packard Management Processors.  It can be used to
control system power on the attached system.

=head1 USAGE

=over 4

=item $manage = SystemManagement::GSP->new( host => 'hostname' )

Creates the management object.  Valid parameters are:

  host      - IP or hostname to connect to (required)
  user      - User to authenticate as (default: "Admin")
  password  - Password to authenticate with (default: "Admin")
  timeout   - Number of seconds to wait while connecting (default: 5)
  debug     - Whether or not to report debugging info (default: 0)
  port      - Port to connect to (default: "telnet(23)")

=cut

sub new {
        my $proto = shift;
        my $class   = ref($proto) || $proto;
        my $self = {
                host     => undef, # host to control
                user     => 'Admin',
                password => 'Admin',
		timeout  => 5,
		debug    => 0,
		port     => "telnet(23)",
                @_,             # Override previous attributes
        };
	# Require a host
	return undef if (!defined($self->{'host'}));

        return bless $self, $class;
};

=item $manage->errmsg()

Reports any textual error messages from a previous function call that
failed with an "undef" value.

=cut

# Report any errors
sub errmsg {
	my $self = shift;
	return $self->{'_error'};
}

=item $manage->establish_session()

Performs connection establishment, and returns "undef" if the connection
fails.  This is called automatically by any function that requires a
session be established.

=cut

# Check to see if we're logged in.  If not, log in.
sub establish_session {
        my ($self) = @_;
	print "_establish_session...\n" if ($self->{'debug'});

	# Default error message
	$self->{'_error'}="Could not establish session";

	return $self->_verify_session();
};

sub _verify_session {
        my ($self) = @_;
	print "_verify_session...\n" if ($self->{'debug'});

	# If there is no session, try to create it and log in
	if (!defined($self->{_session})) {
		$self->{'_error'}="Could not verify session";
		return $self->_connect();
	}

	print "_verify_session done\n" if ($self->{'debug'});
	return 1;
}

sub _connect {
        my ($self) = @_;
	print "_connect...\n" if ($self->{'debug'});

	if (defined($self->{_socket})) {
		$self->{'_error'}="Tried to connect with existing socket";
		return undef;
	}

	$self->{_socket}=IO::Socket::INET->new(
				PeerAddr => $self->{'host'},
				PeerPort => $self->{'port'},
				Proto    => "tcp",
				Timeout  => $self->{'timeout'},
				);
	if (!defined($self->{_socket})) {
		$self->{'_error'}=$@ if (defined($@));
		return undef;
	}

	$self->{'_error'}="Could not attach Expect to connection";
	$self->{_session}=Expect->init($self->{_socket})
		or return undef;
	# This is mostly useless without defining log output
	#$self->{_session}->debug($self->{'debug'});
	$self->{_session}->raw_pty(1);
	
	return $self->_login();
}

sub _login {
        my ($self) = @_;
	print "_login...\n" if ($self->{'debug'});

	if (!defined($self->{'_session'})) {
		$self->{'_error'}="Tried to login without an Expect session";
		return undef;
	}

	my $index;

	# Username
	warn " -- login prompt\n" if ($self->{'debug'});
	$self->{'_error'}="Never saw login prompt";
	defined($self->{'_session'}->expect($self->{'timeout'}, " login: "))
		or return undef;
	warn	$self->{_session}->before().
		$self->{_session}->match().
		$self->{_session}->after()."\n" if ($self->{'debug'});
	$self->{'_error'}="Failed to send login";
	defined($self->{'_session'}->send($self->{'user'}."\r"))
		or return undef;
	
	# Password
	warn " -- password prompt\n" if ($self->{'debug'});
	$self->{'_error'}="Never saw password prompt";
	defined($self->{'_session'}->expect($self->{'timeout'}, " password: "))
		or return undef;
	warn	$self->{_session}->before().
		$self->{_session}->match().
		$self->{_session}->after()."\n" if ($self->{'debug'});
	$self->{'_error'}="Failed to send password";
	defined($self->{'_session'}->send($self->{'password'}."\r"))
		or return undef;

	$self->{'_error'}="Never saw main menu";
	warn " -- main menu\n" if ($self->{'debug'});
	defined($index=$self->{'_session'}->expect($self->{'timeout'},
			" MAIN MENU:", " login: "))
		or return undef;
	warn	$self->{_session}->before().
		$self->{_session}->match().
		$self->{_session}->after()."\n" if ($self->{'debug'});
	if ($index != 1) {
		$self->{'_error'}="Bad 'user' or 'password'";
		return undef;
	}
		
	$self->{'_error'}="Never saw menu prompt";
	defined($self->{'_session'}->expect($self->{'timeout'}, "> "))
		or return undef;

	# Get a prompt for good measure
	defined($self->_get_prompt()) or return undef;

	$self->{'_error'}="Logged in";
	return 1;
}

sub _get_prompt {
        my ($self) = @_;
	print "_get_prompt...\n" if ($self->{'debug'});

	$self->{'_error'}="Tried to get a prompt without an Expect session";
	return undef if (!$self->_verify_session());

	my $index;

	$self->{'_session'}->clear_accum();

	$self->{'_error'}="Could not escape to top-level menu prompt";
	defined($self->{'_session'}->send("q\r"))
		or return undef;
	warn " -- get prompt\n" if ($self->{'debug'});
	$index=$self->{'_session'}->expect($self->{'timeout'},
			[ qr/:[:\w]+> /, sub { my $self = shift;
					      $self->send("\cB");
					      #warn " backing out of menu\n";
					      exp_continue_timeout; }],
			"> " );
	warn	$self->{_session}->before().
		$self->{_session}->match().
		$self->{_session}->after()."<EOB\n" if ($self->{'debug'});
	return undef if (!defined($index) || $index != 2);

	$self->{'_error'}="Never saw top-level menu prompt";
	defined($self->{'_session'}->send("\r"))
		or return undef;
	$index=$self->{'_session'}->expect($self->{'timeout'},"> ");

	$self->{'_session'}->clear_accum();

	return (defined($index));
}

sub _logout {
        my ($self) = @_;
	print "_logout...\n" if ($self->{'debug'});
	
	undef $self->{_session} if ($self->{_session});
	undef $self->{_socket}  if ($self->{_socket});

	return 1;
}

=item $manage->power_on()

Returns "undef" on error, or "1" if power was turned on (or if power was
already on).

=cut

sub power_on {
        my ($self) = @_;
	print "power_on...\n" if ($self->{'debug'});

	return $self->_power("on");
}

=item $manage->power_off()

Returns "undef" on error, or "1" if power was turned off (or if power was
already off).

=cut

sub power_off {
        my ($self) = @_;
	print "power_off...\n" if ($self->{'debug'});

	return $self->_power("off");
}

=item $manage->power_cycle()

Returns "undef" on error, or "1" if power was cycled.
Power can only be cycled if power is on to start with.

=cut

sub power_cycle {
        my ($self) = @_;
	print "power_cycle...\n" if ($self->{'debug'});

	return $self->_power("cycle");
}

sub _power {
        my ($self,$cmd) = @_;
	print "_power...\n" if ($self->{'debug'});

	my $index;

	return undef if (!$self->_get_prompt());

	return undef if (!$self->_enter_power_control());	

	$self->{'_error'}="Could not issue power $cmd command";
	defined($self->{'_session'}->send("$cmd\r"))
		or return undef;
	$index=$self->{'_session'}->expect($self->{'timeout'},
			'Confirm? (Y/[N]): ',
			'-re', '\*\* System Power is already .*');
	if (!defined($index)) {
		return undef;
	}
	elsif ($index == 2) {
		# Fail on a "cycle" rejection
		if ($cmd eq "cycle") {
			$self->{'_error'}=$self->{'_session'}->match();
			$self->{'_error'}=~s/^[\* \r\n]+//g;
			$self->{'_error'}=~s/[\* \r\n]+$//g;
			return undef;
		}

		# All others are considered a success
		return undef if (!$self->_get_prompt());
		return 1;
	}
	elsif ($index != 1) {
		return undef;
	}

	# Confirm
	$self->{'_error'}="Could not confirm power $cmd command";
	defined($self->{'_session'}->send("y\r"))
		or return undef;
	defined($self->{'_session'}->expect($self->{'timeout'},
			'-re', '-> System is being powered (on|off)\.'))
		or return undef;

	return undef if (!$self->_get_prompt());

	$self->{'_error'}="Powered on";
}

sub _enter_power_control {
        my ($self) = @_;
	print "_enter_power_control...\n" if ($self->{'debug'});

	$self->{'_error'}="Tried to enter power control without a session";
	return undef unless (defined($self->{'_session'}));

	# command menu
	$self->{'_error'}="Could not enter command menu";
	defined($self->{'_session'}->send("cm\r"))
		or return undef;
	defined($self->{'_session'}->expect($self->{'timeout'},":CM> "))
		or return undef;

	# power control menu
	$self->{'_error'}="Could not enter power control menu";
	defined($self->{'_session'}->send("pc\r"))
		or return undef;
	defined($self->{'_session'}->expect($self->{'timeout'},
			"Power Control Menu:"))
		or return undef;
	defined($self->{'_session'}->expect($self->{'timeout'},
			"Enter menu item or [Q] to Quit: "))
		or return undef;

	return 1;
}

=item $manage->is_powered_on()

Returns "undef" on error, or the power state of the system.

=cut

# What is the power state (1 = powered on, 0 = powered off, undef = error)
sub is_powered_on {
        my ($self) = @_;
	print "is_powered_on...\n" if ($self->{'debug'});

	my $state = undef; # assume unknown error

	return undef if (!$self->_get_prompt());

	$self->{'_error'}="Could not enter command menu";
	warn " -- cm\n" if ($self->{'debug'});
	defined($self->{'_session'}->send("cm\r"))
		or return undef;
	defined($self->{'_session'}->expect($self->{'timeout'},":CM> "))
		or return undef;
	warn	$self->{_session}->before().
		$self->{_session}->match().
		$self->{_session}->after()."<EOB\n" if ($self->{'debug'});
	warn " -- ps\n" if ($self->{'debug'});
	$self->{'_error'}="Could not get power status report";
	defined($self->{'_session'}->send("ps\r"))
		or return undef;
	defined($self->{'_session'}->expect($self->{'timeout'},
		'-re', qr/System Power state: .+/))
		or return undef;
	warn	$self->{_session}->before().
		$self->{_session}->match().
		$self->{_session}->after()."<EOB\n" if ($self->{'debug'});

	my $line=$self->{'_session'}->match();
	$line=~s/[\r\n]//g;
	warn "line: '$line'\n" if ($self->{'debug'});
	
	return undef if (!$self->_get_prompt());

	$self->{'_error'}="Power Status report made no sense: '$line'";
	if ($line=~/: On/) {
		$state=1;
	}
	elsif ($line=~/: Off/) {
		$state=0;
	}
	else {
	}

	print "is_powered_on: ".$self->_tristate($state)."\n"
		if ($self->{'debug'});
	return $state;
}

sub _tristate {
	my ($self,$value)=@_;
	if (defined($value)) {
		return 1 if ($value);
		return 0;
	}
	return "[undef]";
}

sub DESTROY {
	my $self = shift;
	print "DESTROY...\n" if ($self->{'debug'});

	$self->_logout();
	print "DESTROY done\n" if ($self->{'debug'});
}

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

C<PowerEdge::Rac>
C<SystemManagement::ASMA>

=head1 AUTHOR

Kees Cook, OSDL E<lt>kees@osdl.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Kees Cook, OSDL E<lt>kees@osdl.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
