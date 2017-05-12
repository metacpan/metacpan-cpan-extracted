package Net::Telnet::Wrapper::Device::Packeteer::PacketShaper;

## ----------------------------------------------------------------------------------------------
## Net::Telnet::Wrapper::Device::Packeteer::PacketShaper
##
## Device class for PacketShapers
##
## $Id: PacketShaper.pm 39 2007-07-11 14:29:01Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-07-11 16:29:01 +0200 (Wed, 11 Jul 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------

$VERSION = "0.1";

use Net::Telnet::Wrapper::Device;
use strict;
use warnings;
use Carp;

use vars qw( @ISA );

@ISA = ("Net::Telnet::Wrapper::Device");

sub new()  {
	my ($this, %parm) = @_;
	my  $class = ref($this) || $this;
	my  $self = $class->SUPER::new(%parm);	
	bless($self,$class);

	*$self->{'net_telnet_wrapper'}->{'device_class'} = "Packeteer::PacketShaper";
	*$self->{'net_telnet_wrapper'}->{'mode_support_enable'} = 1;	# router supports enable mode
	*$self->{'net_telnet_wrapper'}->{'mode_support_config'} = 0;	# router supports config mode
	*$self->{'net_telnet_wrapper'}->{'session_prompt'} = '/(?:PacketShaper|\/.*)[>#: ]+$/';		# when we see this we're connected
	*$self->{'net_telnet_wrapper'}->{'prompt_login'} = '[>#] *$';	# when we see this we're in login mode
	*$self->{'net_telnet_wrapper'}->{'prompt_enable'} = '# *$';	# when we see this we're in enable mode
	*$self->{'net_telnet_wrapper'}->{'prompt_config'} = 'conf';	# when we see this we're in config mode
	*$self->{'net_telnet_wrapper'}->{'terminal_length_cmd'} = '';	# if set then the terminal length will be set to 0 before each command
	*$self->{'net_telnet_wrapper'}->{'config_command'} = '';	# command used to go to config mode
	$self->open();

	$self->_init();
	return($self);
}

sub _init()  {
	my ($self) = shift;
}

# override the default close method
# parameters are config =>  (command used to exit 'config' mode)
#                enable =>  (command used to exit 'enable' mode)
#                login =>   (command used to exit 'login' mode)
sub close()  {
	my ($self) = shift;
	$self->SUPER::close( "enable" => "exit", "login" => "exit");
}



## default enable procedure for Net::Telnet::Cisco
## override this for non-Cisco connections
sub enable()  {
	my ($self) = shift;
	my (%args) = @_;
	
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_login'};
	if (!*$self->{'net_telnet_wrapper'}->{'mode_support_enable'})  {
		carp("ENABLE MODE NOT SUPPORTED");
		return 0;
	}

	my $attempt = 1;
	my $enabled = $self->_mode_enable();

	# try to connect
	while (($attempt <= $max_retries) && (!$enabled))  {

		## send 'touch' to go to enable mode
		eval {
			$self->put(String => "touch\n");
		};
		if ($@)  {
			croak ("ENABLE MODE FAILED FOR ",$self->host()," : ",$@);
		}

		my ($prematch, $match);
		eval {
			($prematch, $match) = $self->waitfor(Match => '/(?:Login|Password|Username)[>#: ]*$/i'); #, Errmode => "return")
			$self->last_prompt($match) if ($match);
		};
		if ($@)  {
			carp ($@);
		}

		## Delay sending response, sometimes login fails if response comes too quickly
		sleep(0.1);

		## check if username is asked
		if ($self->last_prompt() =~ /Login/i)  {
			## Send login name and password
			eval {
				$self->put(String => $args{'name'}."\n");
			};
			if ($@)  {
				carp ($@);
			}

			## wait for the password
			eval {
				($prematch, $match) = $self->waitfor(Match => '/(?:Login|Password|Username)[>#: ]*$/i'); #, Errmode => "return");
				$self->last_prompt($match) if ($match);
			};
			if ($@)  {
				carp ($@);
			}
		}

		## now send the password
		if ($self->last_prompt() =~ /Password/i)  {
			## Send login name and password
			eval {
				$self->put(String => $args{'passwd'}."\n");
			};
			if ($@)  {
				carp ($@);
			}
		}

		## wait for the session prompt so that we can set last_prompt
		eval {
			($prematch, $match) = $self->waitfor(Match => *$self->{'net_telnet_wrapper'}->{'session_prompt'}); #, Errmode => "return")
			$self->last_prompt($match) if ($match);
		};
		if ($@)  {
			carp ($@);
		}

		$enabled = $self->_mode_enable();
		$attempt++;
	}
	if (!$enabled)  {
		croak("ENABLE MODE FAILED FOR ", $self->host());
	}
}




sub login()  {
	my ($self) = shift;
	my (%args) = @_;
	
	my $max_retries = *$self->{'net_telnet_wrapper'}->{'retry_login'};
	my $attempt = 1;

	my $loggedin = $self->_logged_in();

	# try to connect
	while (($attempt <= $max_retries) && (!$loggedin))  {

		my ($prematch, $match);
		eval {
			($prematch, $match) = $self->waitfor(Match => '/(?:Login|Password|Username)[>#: ]*$/i'); #, Errmode => "return")
			$self->last_prompt($match) if ($match);
		};
		if ($@)  {
			carp ($@);
		}

		## Delay sending response, sometimes login fails if response comes too quickly
		sleep(0.1);

		## check if username is asked
		if ($self->last_prompt() =~ /Login/i)  {
			## Send login name and password
			eval {
				$self->put(String => $args{'name'}."\n");
			};
			if ($@)  {
				carp ($@);
			}

			## wait for the password
			eval {
				($prematch, $match) = $self->waitfor(Match => '/(?:Login|Password|Username)[>#: ]*$/i'); #, Errmode => "return");
				$self->last_prompt($match) if ($match);
			};
			if ($@)  {
				carp ($@);
			}
		}

		## now send the password
		if ($self->last_prompt() =~ /Password/i)  {
			## Send login name and password
			eval {
				$self->put(String => $args{'passwd'}."\n");
			};
			if ($@)  {
				carp ($@);
			}
		}

		## wait for the session prompt so that we can set last_prompt
		eval {
			($prematch, $match) = $self->waitfor(Match => *$self->{'net_telnet_wrapper'}->{'session_prompt'}); #, Errmode => "return")
			$self->last_prompt($match) if ($match);
		};
		if ($@)  {
			carp ($@);
		}

		## check if we're logged in
		$loggedin = $self->_logged_in();

		## run the default post login tasks
		$self->_post_login($loggedin);

		$attempt++;
	}
	
	
	if (!$loggedin)  {
		croak("UNABLE TO LOGIN TO ", $self->host());
	}
}

1;



__END__

=head1 NAME

Net::Telnet::Wrapper::Device::Packeteer::PacketShaper

=head1 DESCRIPTION

Packeteer::PacketShaper device class template.

This defines the default prompts for this device type.

Do not call this module directly.

=head1 SUPPORTED MODES

    CONNECT
    LOGIN
    ENABLE

=head1 SPECIFICS

    - After logging in go to enable mode and reset terminal paging    
    - login method overrides default login method
    - enable method overrides default enable method
    - close method overrides default method

=head1 AUTHOR

Maarten Wallraf E<lt>perl@2nms.comE<gt>

=cut


