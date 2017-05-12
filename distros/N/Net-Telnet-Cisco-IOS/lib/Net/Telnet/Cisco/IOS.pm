#!#/usr/bin/perl
#
#  TODO:
#  	See sourceforge.net's task list
#
#
#####
#
#  Package  Net::Telnet::Cisco::IOS
#
#  Written by Aaron Conaway
#
#  This package extends the Net::Telnet::Cisco package written by 
#  Joshua Keroes.  Go go http://nettelnetcisco.sourceforge.net/ for
#  details on that package.
#
#  The IOS package is for use on Cisco IOS devices.  It will not work on
#  CatOS or any other Cisco OSes.  
#
#  I am not a programmer.  I merely developed this package out of 
#  necessity to help automate monitoring and configuration of Cisco
#  devices at work.  The code is undoubtedly inefficient and there
#  are probably 84928 better ways to do what I'm trying to do.
#
#  See the documentation at http://ntci.sourceforge.net.
#
#####
package Net::Telnet::Cisco::IOS;

use Net::Telnet::Cisco;
use strict;
use vars qw($AUTOLOAD @ISA $VERSION $DEBUG);
#  Declare ourselves a child of Net::Telnet::Cisco
@ISA        = qw(Net::Telnet::Cisco);
#  Keep the version number
$VERSION    = "0.6beta";

#  Constructor
sub new  {
	#  Get my own class type
  	my $class = shift;
  	my ($self, $host, %args);
  
	#  Call the super constructor
	$self = $class->SUPER::new(@_) or return;
	
	our ( $platform, $model, $iosver, @config );
  	return $self;
}

sub login  {
	my $self = shift;
	$self->SUPER::login(@_) or return;
	$self->cmd("terminal length 0");
	return;
}

#  Returns the version number
sub getModVer  {
	return $VERSION;
}

#  Returns IOS version of router
#  Priv 1
sub getIOSVer  {
	my $cmd = "show version";
	my $self = shift;
	#  Try to run the command
        my @result = $self->cmd( $cmd );

	foreach my $line ( @result )  {
		if ( $line =~ /, Version (.+),/ )  {
			return $1;
		}
	}
	return 0;
}


#  Returns hash of 5-sec, 1-min, and 5-minute CPU averages
#  Priv 1
sub getCPU  {
        #  cmd is what command we send to the IOS device
        my $cmd = "show process cpu";
	#  Initialize the hash
	my %ret = (  	"5sec" => "na",
			"1min" => "na",
			"5min" => "na"
			);
        #  Set the object up
        my $self = shift;
        #  Try to run the command
        my @result = $self->cmd( $cmd );

	foreach my $line ( @result )  {
		if ( $line =~ /five seconds: (.+)\/.+; one minute: (.+); five minutes: (.+)/ )  {
			$ret{ "5sec" } = $1;
			$ret{ "1min" } = $2;
			$ret{ "5min" } = $3;
		}
	}
	return %ret;
}
		
#  Returns all the ints in an array
#  Priv 1
sub listInts  {
	my $self = shift;
	my @ret;
	my $int;
	my $cmd = "sh ip interface brief";
	my @result = $self->cmd( $cmd );

	foreach my $line ( @result )  {
		if ( $line =~ /^Interface/i )  { }
		elsif ( $line =~ /^-----/ )  { }
		elsif ( $line =~ /^\s/ )  { }
		elsif ( $line =~ /^\W/ )  { }
		else  {
			my $int = substr( $line, 0, 23 );
			$int =~ s/\s+$//g;
			push ( @ret, $int );
		}
	}
	return @ret;
}

#  Priv 1
sub listVLANs  {
	my $self = shift;
	my @ret;
	my $cmd = "show vlan brief";
	my ( $vlanid, $vlanname );
        my @result = $self->cmd( $cmd );

	#  Go through each line of the command result
        foreach my $line ( @result )  {
                #  If it starts with "Port", do nothing
                if ( $line =~ /^VLAN/i )  { }
                #  If it starts with "----", do nothing
                elsif ( $line =~ /^----/ )  { }
                #  If it starts with whitespace, do nothing
                elsif ( $line =~ /^\s+/ )  { }
                else  {
			#  Get the first two columns
			$vlanid = substr( $line, 0, 4);
			$vlanname = substr ( $line, 5, 30 );
			if ( $vlanid =~ /100[2-5]/ )  { }
			else  {
				$vlanid =~ s/\s+$//g;
                        	#  Put the line onto the end of the return array
                        	push ( @ret, $vlanid );
			}
                }
        }
        #  Return the return array
        return @ret;
}	

#  Priv 1
sub getIntState  {
        my ( $self, @args ) = @_;
        my %result;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @output = $self->cmd( $cmd );

        foreach my $line ( @output )  {
                if ( $line =~ /$if is (.+), line protocol is (.+) / )  {
                        $result{'port'} = $1;
                        $result{'lineprotocol'} = $2;
                }  else  { }
        }
        return %result;
}   

#  Priv 1
sub getIntDesc  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /Description: (.+)/ )  {
                        return $1;
                }  else  { }
        }
	return 0;
}

#  Priv 1
sub getEthSpeed  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /Auto Speed \((.+)\),/ )  {
                        return $1;
                }  elsif ( $line =~ /, (.+)Mb\/s/ )  {
                                return $1;
                }
        }
	return 0;
}

#  Priv 1
sub getEthDuplex  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /\s+Auto-duplex \((.{4})\),/ )  {
                        return $1;
                }  elsif ( $line =~ /\s+(.+)-duplex/ )  {
                        if ( $1 eq "Auto" )  { }
                        else  {
                                return $1;
                        }
                }
        }
	return 0;
}

#  Priv 1
sub getIntBandwidth  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /\s+BW (.+) Kbit/ )  {
                        return $1;
                }  else  { }
        }

}


#  Priv 1
sub getIntInputRate  {
	my ( $self, @args ) = @_;
	my $if = &harmonizeInts( $args[0] );
	my $cmd = "sh interface " . $if;
	my @result = $self->cmd( $cmd );

	foreach my $line ( @result )  {
		if ( $line =~ /5 minute input rate (.+) bits/ )  {
			return $1;
		}  else  { }
	}
	
}

#  Priv 1
sub getIntInputErrors  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /(.+) input errors,/ )  {
                        return $1;
                }  else  { }
        }
	return 0;

}

#  Priv 1
sub getIntOutputRate  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /5 minute output rate (.+) bits/ )  {
                        return $1;
                }  else  { }
        }

}

#  Priv 1
sub getIntOutputErrors  {
        my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if;
        my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /(.+) output errors,/ )  {
                        return $1;
                }  else  { }
        }
	return 0;
}

#  Priv 1
sub findVLAN  {
	my ( $self, @args ) = @_;
        my $if = &harmonizeInts( $args[0] );
        my $cmd = "sh interface " . $if . " status";
        my @result = $self->cmd( $cmd );
	my $vlan = undef;

        foreach my $line ( @result )  {
		if ( $line =~ /^Port/ )  { }
		elsif ( $line =~ /^-----/ )  { }
		elsif ( $line =~ /^\s+/ )  { }
                else  {
			$vlan = substr( $line, 40, 8 );
			$vlan =~ s/\s+//g;
			return $vlan;
		}
        }
        return $vlan;
}

#  Priv 15
sub getConfig  {
	my $self = shift;
	my $cmd = "show running-config";
	my @result = $self->cmd( $cmd );

	return @result;
}

#  Priv 1
sub getModel  {
	my $self = shift;
	my $cmd = "sh ver";
	my $plat;
	my @result = $self->cmd( $cmd );

        foreach my $line ( @result )  {
                if ( $line =~ /^IOS \(tm\) (.+) Software/ )  { 
			return $1;
                }  elsif  ( $line =~ /cisco (.+) processor/ )  {
			return $1;
		}
        }
        return 0;
}

#  Priv 1
sub getPlatform  {
        my ( $self, @args ) = @_;
	my $platform;
        my $model = $args[0];
	
	if ( $model =~ /29.0/ || $model =~ /3750/ )  {
		return "s";
	}  elsif  ( $model =~ /RSP/ || $model =~ /7200/ )  {
		return "r";
	} 
	return 0;
}

#  Priv 1
sub getIntCAM  {
	my ( $self, @args ) = @_;
	my $int = harmonizeInts( $args[0] );
	my $cmd = "show mac-address-table interface " . $int;
	my @ret;
	my @output = $self->cmd( $cmd );
	my $model = $self->getModel();

	foreach my $line ( @output )  {
		my $mac;
		if ( $line =~ /(\w{4}\.\w{4}\.\w{4})/ )  {
			push ( @ret, $1 );
		}
	}
	return @ret;
}

#  Priv 1
sub getIntARP  {
        my ( $self, @args ) = @_;
        my $int = harmonizeInts( $args[0] );
	my $cmd = "show arp";
	my @ret;
	my @output = $self->cmd( $cmd );

	foreach my $line ( @output )  {
		chomp $line;
		if ( $line =~ /$int/ && $line =~ /(\w{4}\.\w{4}\.\w{4})/ )  {
			push ( @ret, $1 );
		}
	}
	return @ret;
}

#  Priv 1
sub arpLookup  {
	my ( $self, @args ) = @_;
	my $cmd = "show arp";
	my @output = $self->cmd( $cmd );

	foreach my $line ( @output )  {
		chomp $line;
		if ( $line =~ /$args[0]/ )  {
			my $ip = substr ( $line, 10, 15 );	
			if ( length( $ip ) == 0 )  { }
			else  {
				return $ip;
			}
		}
	}
	return 0;
}

#  Priv 1
sub getACLs  {
	my $self = shift;
	my $cmd = "show access-lists";
	my @ret;
	my @output = $self->cmd( $cmd );

	foreach my $line ( @output )  {
		if ( $line =~ /access list (.+)\n/ )  {
			push ( @ret, $1 );
		}
	}
	return @ret;
}
	
#  Priv 15
sub getSNMPComm  {
	my $self = shift;
	my @ret;
	my @output = $self->getConfig();

	foreach my $line ( @output )  {
		if ( $line =~ /snmp-server community (.+) / )  {
			push ( @ret, $1 );
		}
	}
	return @ret;
} 

#  Priv 1
sub privLevel  {
	my $self = shift;
	my $cmd = "show privilege";
	my $ret = 0;
	my @output = $self->cmd( $cmd );

	foreach my $line ( @output )  {
		if ( $line =~ /^Current privilege level is (\d{1,2})/ )  {
			$ret = $1;
		}
	}
	return $ret;
}
	
#  Priv 1			
sub getVTP  {
	my $self = shift;
	my $cmd = "show vtp status";
	my ( $ver, $mode, $domain );
	my %ret;
	my @output = $self->cmd( $cmd );
	
	foreach my $line ( @output )  {
		if ( $line =~ /^VTP Version\s+: (.)\n/ )  {
			$ver = $1;
		}
		elsif ( $line =~ /^VTP Operating Mode\s+: (.+)\n/ )  {
			$mode = $1;
		}
		elsif ( $line =~ /^VTP Domain Name\s+: (.+)\n/ )  {
			$domain = $1;
		}
	}
	%ret = (
		version => $ver,
		mode => $mode,
		domain => $domain,
	);
	return %ret;
}

#  Priv 1
sub getIntACL  {
	my ( $self, @args ) = @_;
	my $inacl = 0;
	my $outacl = 0;
        my $cmd = "show ip int " . $args[0];
	my @outacl =  ("Outgoing access list is ", "Outbound access list is ");
	my @inacl = ("Inbound  access list is ", "Inbound access list is ");
        my %ret;
	my @output = $self->cmd( $cmd );
	
	foreach my $line ( @output )  {
		ACL:
		{
			foreach my $acl ( @outacl )  {
				if ( $line =~ /$acl(.+)/ )  {
					$outacl = $1;
					last ACL;
				}	
			}
			foreach my $acl ( @inacl )  {
				if ( $line =~ /$acl(.+)/ )  {
					$inacl = $1;
					last ACL;
				}
			}
		}  #  ACL
	}
	
	if ( $inacl eq "not set" || $inacl eq "" )  {
		$inacl = 0;
	}
	if ( $outacl eq "not set" || $outacl eq "")  {
		$outacl = 0;
	}

	%ret = (
		inbound => $inacl,
		outbound => $outacl,
	);
	return %ret;
}

#  Priv 1
sub getIPRoute  {
	my ( $self, @args ) = @_;
	my %ret = ( 	route => 0,
			protocol => 0,
		 	nexthop => 0);
	my $cmd = "show ip route " . $args[0];
	my @result = $self->cmd( $cmd );
	foreach my $line ( @result )  {
		if ( $line =~ /Routing entry for (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2})/ )  {
			$ret{'route'} = $1;
		}
		if ( $line =~ /Known via \"(.+)\"/ )  {
			$ret{ 'protocol' } = $1;
		}
		if ( $line =~ /directly connected, via (.+)\W/ )  {
			$ret{ 'nexthop' } = $1;
		}
		if ( $line =~ /\* (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ )  {
			$ret{ 'nexthop' } = $1;
		}
	}
	return %ret;
}

# Priv 15
sub getNTP  {
	my $self = shift;
	my %ret;
	my ( $server, $source, $mode );

	my @result = $self->getConfig();
	foreach my $line ( @result )  {
		if ( $line =~ /^ntp server (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) source (\w+) (\w+)/ )  {    
			$server = $1;
			$source = harmonizeInts( $2 );
			$mode = $3;
                }
		elsif ( $line =~ /^ntp server (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) prefer/ )  {
			$server = $1;
			$mode = "prefer";
		}
		elsif ( $line =~ /^ntp source (.+)$/ )  {
			$source =  harmonizeInts( $1 );
		}
	}
	%ret = (	server => $server,
			source => $source,
			mode => $mode );
	return %ret;
}
#  Priv 15
sub disableInt  {
#  Fix the return codes.
	my ( $self, @args ) = @_;
	my  $result;
	my $if = &harmonizeInts( $args[0] );
	my $cmd = "shutdown";
	eval  {
		$self->cmd( "configure terminal" );
		$self->cmd( "interface $if" );
		$self->cmd( "$cmd" );
		$self->cmd( "exit\nexit" );
	};
	if ( length( $self->errmsg() ) > 0 )  {
		return 0;
	}
	return 1;
}

#  Priv 15
sub saveConfig  {
	my $self = shift;
	my $cmd = "write memory";
	if ( !$self->cmd( $cmd ) )  {
		print "Couldn't do it";
		<STDIN>;
		return 0;
	}
	return 1;
}

sub harmonizeInts  {
	my $input = shift;
	my @FastEthernet = qw(FastEthernet FastEth Fast FE Fa F);
	my @GigEthernet = qw(GigabitEthernet GigEthernet GigEth GE Gi G);
	my @Ethernet = qw(Ethernet Eth E);
	my @Serial = qw(Serial Se S);
	my @PortChannel = qw(PortChannel Port-Channel Po);
	my @POS = qw(POS P);
	my @VLAN = qw(VLAN VL V);
	my @LOOPBACK = qw(Loopback Loop Lo);
	my @ATM = qw(ATM AT A);
	my @DIALER = qw(Dialer Dial Di D);
	my @VIRTUALACCESS = qw(Virtual-Access Virtual-A Virtual Virt);
	IFS:
	{
		#  Go through the array @FastEthernet
        	foreach my $fe ( @FastEthernet )
        	{
               		#  If the user's input matches
                	if ( $input =~ /^$fe\d/i )
	        	{
              			#  Take the number part out
                		$input =~ /^$fe(.+)\b/i;
        	        	#  Reset $val to the long name + number
	                	$input = "FastEthernet" . $1;
                        	#  Leave the block because we found it
                		last IFS;
        		}
		}
		#  Go through the array @GigEthernet
                foreach my $ge ( @GigEthernet )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$ge\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$ge(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "GigabitEthernet" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		#  Go through the array @Ethernet
                foreach my $e ( @Ethernet )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$e\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$e(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "Ethernet" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		#  Go through the array @Serial
                foreach my $s ( @Serial )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$s\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$s(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "Serial" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		#  Go through the array @PortChannel
                foreach my $po ( @PortChannel )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$po\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$po(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "Port-channel" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		#  Go through the array @POS
                foreach my $pos ( @POS )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$pos\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$pos(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "POS" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		#  Go through the array @VLAN
		foreach my $vlan ( @VLAN )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$vlan\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$vlan(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "VLAN" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		# Go through the array @LOOPBACK
		foreach my $lb ( @LOOPBACK )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$lb\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$lb(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "Loopback" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
                # Go through the array @ATM
                foreach my $atm ( @ATM )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$atm\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$atm(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "ATM" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
                # Go through the array @DIALER
                foreach my $dialer ( @DIALER )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$dialer\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$dialer(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "Dialer" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
                # Go through the array @VIRTUALACCESS
                foreach my $virt ( @VIRTUALACCESS )
                {
                        #  If the user's input matches
                        if ( $input =~ /^$virt\d/i )
                        {
                                #  Take the number part out
                                $input =~ /^$virt(.+)\b/i;
                                #  Reset $val to the long name + number
                                $input = "Virtual-Access" . $1;
                                #  Leave the block because we found it
                                last IFS;
                        }
                }
		#  Since we didn't find it, set $input to 0
		return 0;
	}  #  IFS
	$input =~ s/\s+//g;
	return $input;
}

1;
=head1 NAME

Net::Telnet::Cisco::IOS -- Manage Cisco IOS Devices

=head1 DESCRIPTION

Net::Telnet::Cisco::IOS (NTCI) is an extension of Joshua Kereos's Net::Telnet::Cisco module and provides an easy way to manage and monitor Cisco IOS devices.  I'll mention this a lot, but make sure you read up on Net::Telnet::Cisco for a lot of information.

=head1 WHEN TO USE NTCI

NTCI can do a lot, but it's not the best way to do all of it.  I'd suggest you take a look at some SNMP solutions.  It's up to you to figure out when and where you want to use it, but don't say I didn't warn you.  :)

=head1 METHODS

There are way too many methods to list here, so head over to http://ntci.sourceforge.net for a full list with documentation.

=head1 SYNOPSIS

	use Net::Telnet::Cisco:IOS;

	# Connect and login
	$connection = Net::Telnet::Cisco::IOS->new( Host => 'hostname');
	$connection->login( Name => 'username', Password => 'password' 	);

	# Get the IOS version
	if ( $ver = $connection->getIOSVer() )  {
		print "The device is running version " . $ver . "\n";
	}
	else  {
		print "Can't get the version:\n";
		print $connection->errmsg();
	}
	
	# Close the connection
	$connection->close();

=head1 MORE INFO

For more information, examples, and some tips, turn your browser to http://ntci.sourceforge.net.

=head1 AUTHOR

NTCI is written by Aaron Conaway.  He can be reached at aaron at aconaway period com.

=head1 COPYRIGHT AND LICENSE

(c) 2005 by Aaron Conaway.  

NTCI is distributed under the GPL and may be used by anyone without changes.