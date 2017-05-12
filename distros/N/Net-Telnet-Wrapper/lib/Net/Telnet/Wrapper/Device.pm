package Net::Telnet::Wrapper::Device;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device
##
## This is the base class for each device type.
##
## $Id: Device.pm 39 2007-07-11 14:29:01Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-07-11 16:29:01 +0200 (Wed, 11 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------


$VERSION = "0.1";

use strict;
use warnings;
use Carp;
use Data::Dumper;

use vars qw( @ISA $DEBUG );
@ISA=( );		# will be altered by _is_installed()


$Carp::Verbose = 0;
$Carp::CarpLevel = 0;
$DEBUG = 1;


BEGIN { $SIG{'__WARN__'} = sub { carp($_[0]) if ($DEBUG); } }


# depending on 'device_class' either Net::Telnet or Net::Telnet::Cisco is inherited
# basically any class that's derived from Net::Telnet could be used
# this is done in _init()
#use Net::Telnet;
#use Net::Telnet::Cisco;

sub new()  {
	my ($this, %parm) = @_;
	my  $class = ref($this) || $this;
	# we want to override the open function to handle retries
	# so we must filter out the -host parameter and call open()
	# ourselves if needed
	my $host = '';
	if (defined($parm{'-host'}))  {
		$host = $parm{'-host'};
		delete $parm{'-host'};
	}

	# these are some variables that we can use but don't want to pass on to our parent Net::Telnet or Net::Telnet::Cisco
	# TODO: this needs to be done for each overriden procedure like open() or cmd()
	my %temp;
	$temp{'inherit_auto'} = 1;
	$temp{'inherit_class'} = 'Net::Telnet';
	$temp{'retry_open'} = 3;
	$temp{'retry_login'} = 3;
	$temp{'retry_cmd'} = 3;

	# override the defaults with the parameters if they are provided
	foreach ( qw( inherit_auto inherit_class retry_open retry_login retry_cmd ) )  {
		if (defined($parm{"$_"}))  {
			$temp{"$_"} = $parm{"$_"};
			delete $parm{"$_"};
		}
	}
	# now inherit from our class (normally Net::Telnet or Net::Telnet::Cisco)
	$temp{'device_class'} = $this;
	&_get_class(%temp);

	my  $self = $class->SUPER::new(%parm);	 
	bless($self,$class);

	*$self->{'net_telnet_wrapper'} = {
			'device_class' 	=> $temp{'device_class'},
			'inherit_class'	=> $temp{'inherit_class'},
			'retry_open'	=> $temp{'retry_open'},
			'retry_login'	=> $temp{'retry_login'},
			'retry_cmd'		=> $temp{'retry_cmd'},
			'mode'			=> 'undef',				# = current mode => undef | connect | login | enable | config
			'mode_support_login'	=> 1,			# supports login mode (ex. unix, router)
			'mode_support_enable'	=> 0, 			# supports enable mode (ex. router)
			'mode_support_config'	=> 0,			# supports config mode (ex. router)
			 #### ONLY session_prompt has to have reges between / / ####
			 #### ?? why was that again .. ?? ####
			'session_prompt'	=> *$self->{'net_telnet'}->{'cmd_prompt'},	# this is the prompt once we're in connect mode
			'prompt_login'		=> '[\$%#>] $',	# this is the prompt after we're logged in
			'prompt_enable'		=> '^NOTUSED$',				# this is the prompt that's used to recognize we're in enable mode
			'prompt_config'		=> '^NOTUSED$',				# this is the prompt that's used to recognize we're in config mode
			'terminal_length_cmd'	=> 'terminal length 0',			# this is the prompt that's used to recognize we're in enable mode
			'config_command'	=> 'conf t',				# this is the prompt that's used to recognize we're in config mode
			'run_post_login'	=> 1,			# run post login commands
			'run_post_enable'	=> 0,			# run post enable login commands
	};
	
	$self->_init();

	# now open the connection if needed (host is already know)
	($host)?($self->host($host)):($self->host(""));
	
	return($self);
}

sub _get_class()  {
	my (%parm) = @_;
	my $rc;
	my $inherit;
	# inherit the correct class
	if ($parm{'inherit_auto'})  {
		if (lc($parm{'device_class'})=~/cisco/)  {
			$inherit = 'Net::Telnet::Cisco';
		}
		else  {
			$inherit = 'Net::Telnet';
		}
	}
	else  {
		$inherit = $parm{'inherit_class'};
	}
	
	$rc = &_is_installed($inherit);
	
	return $inherit;
}

sub _init()  {
	my ($self) = shift;
}

sub open()  {
	my ($self) = shift;
	
	next unless ($self->host);
	
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_open'};
	my $attempt = 1;
	# try to connect
	while (($attempt <= $max_retries) && (!*$self->{'net_telnet'}->{'opened'}))  {
#		carp("OPEN ATTEMPT $attempt for host ",$self->host(),"\n");
		eval {
			$self->SUPER::open(@_);
		};
		if ($@)  {
			carp("OPEN FAILED: ",$@);
		}
		else  {
		}
		$attempt++;
	}
	# successful connection!
	if (*$self->{'net_telnet'}->{'opened'})  {
			$self->SUPER::prompt(*$self->{'net_telnet_wrapper'}->{'session_prompt'});
		#return 1;
	}
	# something went wrong
	else {
		croak("ERROR: unable to connect to ", $self->host());
	}
}


# parameters =     "config" => "", "enable" => "", "login" => "" , "connect" => ""
sub close()  {
	my ($self) = shift;
	my %parms = @_;
	my $attempt = 3;
	#my $max_retries = 1;
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_cmd'};
	my $mode;
	my $m;
	
	# try to close the session "gently" meaning that we're exiting the session by entering
	# the correct exit commands
	# exit config + enable + login + connect mode if defined
	foreach $m ("config", "enable", "login", "connect")  {
		if (defined($parms{"$m"}))  {
			$attempt = 1;
			$mode = $self->get_mode();
			while (($attempt <= $max_retries) && ($mode=~/$m/))  {
				eval {
					$self->print($parms{"$m"});
					$self->waitfor();
				};
				$attempt++;
				$mode = $self->get_mode();
				#warn "mode = $mode\nm = $m\n";
			}
		}
	}
	eval {
		$self->SUPER::close();
	};
}


sub login()  {
	my ($self) = shift;
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_login'};
	my $attempt = 1;
	my $loggedin = $self->_logged_in();

	# try to connect
	while (($attempt <= $max_retries) && (!$loggedin))  {
#		carp("LOGIN ATTEMPT $attempt for host ",$self->host(),"\n");
		eval {
			$self->SUPER::login(@_);
		};
		if ($@)  {
			carp("LOGIN FAILED: ", $@);
		}
		$loggedin = $self->_logged_in();
		## try to send "terminal length 0" if needed
		## but don't generate an error if it fails
		$self->_post_login($loggedin);
		$attempt++;
	}
	if (!$loggedin)  {
		croak("UNABLE TO LOGIN TO ", $self->host());
	}
}



sub _post_login()  {
	my ($self, $loggedin) = @_;
	
	return unless (*$self->{'net_telnet_wrapper'}->{'run_post_login'});
	
	$loggedin = $self->_logged_in() unless (defined $loggedin);
	## try to send "terminal length 0" if needed
	## but don't generate an error if it fails
	if ($loggedin)  {
		eval  {
			if (*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'})  {
					$self->cmd(*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'});
			}
		};
	}
}


sub _post_enable()  {
	my ($self, $enabled) = @_;

	return unless (*$self->{'net_telnet_wrapper'}->{'run_post_enable'});

	$enabled = $self->_mode_enable() unless (defined $enabled);
	## try to send "terminal length 0" if needed
	## but don't generate an error if it fails
	if ($enabled)  {
		eval  {
			if (*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'})  {
					$self->cmd(*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'});
			}
		};
	}
}


## default enable procedure for Net::Telnet::Cisco
## override this for non-Cisco connections
sub enable()  {
	my ($self) = shift;
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_login'};
	if (!*$self->{'net_telnet_wrapper'}->{'mode_support_enable'})  {
		carp("ENABLE MODE NOT SUPPORTED");
		#return 0;
	}
	my $attempt = 1;
	my $enabled = $self->_mode_enable();
#	carp("Are we in enable mode : $enabled\n");
	# try to connect
	while (($attempt <= $max_retries) && (!$enabled))  {
#		carp("ENABLE ATTEMPT $attempt for host ",$self->host(),"\n");
		eval {
			$self->SUPER::enable(@_);
		};
		if ($@)  {
			carp("ENABLE FAILED: ",$@);
		}
		$enabled = $self->_mode_enable();
		## try to send "terminal length 0" if needed
		## but don't generate an error if it fails
		$self->_post_enable($enabled);
		$attempt++;
	}
	if (!$enabled)  {
		croak("ENABLE MODE FAILED FOR ", $self->host());
	}
}


sub config()  {
	my ($self) = shift;
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_login'};
	my $cmd = *$self->{'net_telnet_wrapper'}->{'config_command'};
	if (!*$self->{'net_telnet_wrapper'}->{'mode_support_config'})  {
		carp("CONFIG MODE NOT SUPPORTED");
		#return 0;
	}
	my $attempt = 1;
	my $config = $self->_mode_config();
	while (($attempt <= $max_retries) && (!$config))  {
#		carp("ENABLE ATTEMPT $attempt for host ",$self->host(),"\n");
		eval {
			$self->cmd($cmd);
		};
		if ($@)  {
			carp("CONFIG FAILED: ",$@);
		}
		$config = $self->_mode_config();
		$attempt++;
	}
	if (!$config)  {
		croak("CONFIG MODE FAILED FOR ", $self->host());
	}
}


sub cmd()  {
	my ($self) = shift;
	
	## if telnet_mode is 0 then run cmd_tcp() instead of default cmd()
	## usually this is for connecting to non-telnet ports (ex. POP or HTTP)
	## there's no prompt so we don't want to check for this
	if (!$self->SUPER::telnetmode())  {
		return $self->cmd_tcp(@_);
	}
	
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_cmd'};
	my $attempt = 1;
	my $success = 0;
	my @output;
	# try to connect
	while (($attempt <= $max_retries) && (!$success))  {
#		carp("CMD ATTEMPT $attempt for host ",$self->host(),"\n");
		eval {
			@output = $self->SUPER::cmd(@_);
		};
		if ($@)  {
			carp("CMD FAILED [@_] ",$@);
		}
		else  {
			$success++;
		}
		$attempt++;
	}
	if (!$success)  {
		croak("COMMAND @_ FAILED FOR ", $self->host());
	}
	return @output;
}



sub cmd_tcp()  {
	my ($self) = shift;
	my @output;

	foreach my $cmd (@_)  {
		$self->print("$cmd");
		push(@output, $self->getlines());
	}
	
	return @output;	
}



sub get_device_class()  {
	my $self = shift;
	return *$self->{'net_telnet_wrapper'}->{'device_class'};
}


# returns the current connection mode or state
# values are 'undef' => not connected or status unknonw
#            'connect' => connected to the device
#            'login' => connected + logged in
#            'enable' => connected + logged in + enabled mode (ex. for routers)
#			 'config' => connected + logged in + enabled mode + config mode (ex. for routers)
sub get_mode()  {
	my ($self) = @_;
	*$self->{'net_telnet_wrapper'}->{'mode'} = 'undef';
	if (*$self->{'net_telnet'}->{'opened'})  {
		*$self->{'net_telnet_wrapper'}->{'mode'} = 'connect';
		if ($self->_mode_config() == 1)  {
			*$self->{'net_telnet_wrapper'}->{'mode'} = 'config';
		}
		elsif ($self->_mode_enable() == 1)  {
			*$self->{'net_telnet_wrapper'}->{'mode'} = 'enable';
		}
		elsif ($self->_mode_login() == 1)  {
			*$self->{'net_telnet_wrapper'}->{'mode'} = 'login';
		}
	} 
	return *$self->{'net_telnet_wrapper'}->{'mode'};
}


# returns 1 if we are in login mode
sub _mode_login()  {
	my ($self) = @_;
	if ( ($self->last_prompt() =~ *$self->{'net_telnet_wrapper'}->{'prompt_login'}) &&
	        (*$self->{'net_telnet_wrapper'}->{'mode_support_login'}) )  {
		return 1;
	}
	return 0;
}

# returns 1 if we are in enable mode
sub _mode_enable()  {
	my ($self) = @_;
	if ( ($self->last_prompt() =~ *$self->{'net_telnet_wrapper'}->{'prompt_enable'}) &&
	        (*$self->{'net_telnet_wrapper'}->{'mode_support_enable'}) )  {
		return 1;
	}
	return 0;
}

# returns 1 if we are in config mode
sub _mode_config()  {
	my ($self) = @_;
	if ( ($self->last_prompt() =~ *$self->{'net_telnet_wrapper'}->{'prompt_config'}) &&
	        (*$self->{'net_telnet_wrapper'}->{'mode_support_config'}) )  {
		return 1;
	}
	return 0;
}


# returns 1 if we're logged in
sub _logged_in()  {
	my ($self) = @_;
	my $loggedin = 0;
	my $mode = $self->get_mode();
	if (grep { lc($mode) =~ /$_/ }  qw( login enable config ) )  {
		$loggedin = 1;
	}
	return $loggedin;
}

sub _is_installed {
	my($module) = @_;
	my $rc;
	(my $filename = $module) =~ s@::@/@g;
	$rc = eval { require $filename.".pm" };
	if ($@)  {
		croak("ERROR: device_class '$module' cannot be found");
	}
	push(@ISA,$module);
	return $rc;
}



sub DESTROY()  {
	my ($self) = @_;
	eval {
		$self->close();
	};
}


1;


__END__

=head1 NAME

Net::Telnet::Wrapper::Device

=head1 DESCRIPTION

This is the base class for each device type.
For example when you call Net::Telnet::Wrapper with device_class = Cisco::IOS then
this will take care of calling the Cisco::IOS device class and it will also take care of 
correct inheritance from Net::Telnet or Net::Telnet::Cisco.

Do not call this module directly.

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut
