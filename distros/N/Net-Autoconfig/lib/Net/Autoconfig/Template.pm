package Net::Autoconfig::Template;

use 5.008008;
use strict;
use warnings;

use base "Net::Autoconfig";
use Log::Log4perl qw(:levels);
use Data::Dumper;
use version; our $VERSION = version->new('v1.1.3');

#################################################################################
## Constants and Global Variables
#################################################################################

use constant TRUE   =>  1;
use constant FALSE  =>  0;
use constant DEFAULT_TIMEOUT => 10;

use constant DEFAULT_CMD => {
                                cmd         =>  "",
                                regex       =>  "",
                                timeout     =>  DEFAULT_TIMEOUT,
                                required    =>  TRUE,
                                };

# directives = keywords that the parser looks for.  The corresponding hash value
# is the regex to use to look for corresponding data.
my $file_directives = {
    cmd         =>  '.+',
    'wait'      =>  '\d+',
    regex       =>  '.*',
    default     =>  '',
    required    =>  '',
    optional    =>  '',
    device      =>  '\w+',
    host        =>  '\w+',
    hostname    =>  '\w+',
    end         =>  '',
};



#################################################################################
# Methods
#################################################################################

############################################################
# Public Methods
############################################################

########################################
# new
# public method
#
# create a new Net::Autoconfig::Template
#
# Takes a filename
#
# Returns:
#   a Net::Autoconfig::Template object
########################################
sub new {
    my $invocant = shift; # calling class
    my $filename = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = {};
    my $log      = Log::Log4perl->get_logger('Net::Autoconfig');
    my $template_data;    # a hash ref to the template data from the file

    $log->debug("Creating new template object");
    $template_data = _get_template_data($filename);
    $self = $template_data || {};

    if ($log->is_trace())
    {
        $log->info(Dumper($template_data));
    }

    return bless $self, $class;
}

############################################################
# Private Methods
############################################################

########################################
# _get_template_data
# private method
#
# Load the file and extract data from it.
# Returns:
#   array context   => a hash of the template data
#   scalar context  => a hash ref of the template data
#   failure         => undef
########################################
sub _get_template_data {
    my $filename      = shift;
    my $template_data = {};
    my $log           = Log::Log4perl->get_logger("Net::Autoconfig");
    my $current_device;      # the name of the current device
    my $set_defaults_flag;   # set if we've seen a "default" directive
    my $skip_push_cmd;       # flag indicates if we shouldn't push this to the list of commands

    $filename or return;

    eval
    {
        open(TEMPLATE, "<$filename") || die "Could not open '$filename' for reading: $!";
    };
    if ($@)
    {
        $log->warn("Loading Template - $@");
        return;
    }

    $template_data->{default} = DEFAULT_CMD;

    while (my $line = <TEMPLATE>)
    {
        my $cmds;     # the command or the directives + commands
        $log->trace("Template line: $line");

        # Only skip the line if the first character is a "#".
        # Someone may want to send a " #..." cmd.
        # Probably not, but you never know.
        next if $line =~ /^#/;
        $cmds = _get_template_directives($line);

        if ($cmds->{default})
        {
            $set_defaults_flag = TRUE;
            delete $cmds->{default};
            $cmds->{'cmd'} = '';
        }


        foreach my $hostname qw(device host hostname)
        {
            if ($cmds->{$hostname})
            {
                $current_device = $cmds->{$hostname};
                $template_data->{$current_device}->{hostname} = $current_device;
                delete $cmds->{$hostname};
                $skip_push_cmd = TRUE;   # If this exists, then don't push this onto the cmd list/stack
                $log->debug("Now using template named '$current_device'");
            }
        }
        if ( $cmds->{end} )
        {
            undef $current_device;
            undef $set_defaults_flag;
        }

        # Add the data to the right place
        if ( $set_defaults_flag and $current_device )
        {
            # Add the existing data to the default data.
            # New data overwrites old data.
            # Vivify the default data if it does not exist
            my $default_data;
            if (not $template_data->{$current_device}->{default})
            {
                if ($template_data->{default})
                {
                    $template_data->{$current_device}->{default} = $template_data->{default};
                }
                else
                {
                    $template_data->{$current_device}->{default} = DEFAULT_CMD;
                }
            }
            $default_data = $template_data->{$current_device}->{default};
            $template_data->{$current_device}->{default} = { %$default_data, %$cmds };
            $template_data->{$current_device}->{default}->{cmd} = '';
            $log->trace("Device Default Data: " . Dumper($template_data->{$current_device}->{default}));
        }
        elsif ($set_defaults_flag and not $current_device)
        {
            # Add the existing data to the global template default data.
            # New data overwrites old data.
            # Vivify the default data if it does not exist
            if (not exists $template_data->{default})
            {
                $template_data->{default} = DEFAULT_CMD;
            }
            $template_data->{default} = { %{$template_data->{default}}, %$cmds };
            $template_data->{default}->{cmd} = '';
            $log->trace("Template Default Data: " . Dumper($template_data->{default}));
        }
        elsif ($current_device)
        {
            # Add the commands to the current device.
            # If there aren't any commands yet, make them
            if ($skip_push_cmd)
            {
                undef $skip_push_cmd;
                next;
            }

            my $cmds_array;   # an array ref to the device commands
            if ( not defined $template_data->{$current_device}->{cmds})
            {
                $template_data->{$current_device}->{cmds} = [];
            }

            # Create a ref to the cmds array to make it easier to read and write
            $cmds_array = $template_data->{$current_device}->{cmds};

            if (exists $template_data->{$current_device}->{default})
            {
                $cmds = { %{$template_data->{$current_device}->{default}}, %$cmds };
            }
            else
            {
                $cmds = { %{$template_data->{default}}, %$cmds };
            }

            # Check to see if someone wanted to copy another template
            # into this one.  I.e. this is useful for entering the same
            # commands on different devices.  E.g. c2960 and c2960g can
            # use the same commands.
            #
            # Procedure: 1) Copy the data into a new hash
            #            2) Point the current device template to the new data
            # Notes:
            #       a) This prevents a change in 1 affecting both of them.
            #       b) This allows for extra commands to be added to the current device
            #          without affecting the other device.
            if ($cmds->{cmd} =~ /^<same_as\s+(.*)>/i)
            {
                my $other_device = lc $1;   # The other template to copy into this one
                my %other_template = %{ $template_data->{$other_device} };

                $template_data->{$current_device} = \%other_template;

                $log->trace("Duplicating template '$other_device' to '$current_device'");
            }
            else
            {
                $log->trace("Adding commands to $current_device: " . Dumper($cmds));
                push(@$cmds_array, $cmds);
            }
        }
        else
        {
            # Ignore blank space.  But if it looks like someone tried to put a command
            # outside of a device or default directive, then let them know about it.
            if ($cmds->{cmd} or ((scalar keys %$cmds) > 1))
            {
                $log->warn("Unknown device or default object to add commands to.");
                $log->warn(Dumper($cmds));
            }
        }

    }

    if ($log->is_trace())
    {
        $log->info(Dumper($template_data));
    }

    close(TEMPLATE);

    # Clean-up the template (i.e. remove the default config entries)
    delete $template_data->{default};
    foreach my $device (keys %$template_data)
    {
        delete $template_data->{$device}->{default};
    }

    return wantarray ? %$template_data : $template_data;
}

########################################
# _get_template_directives
# private method
#
# For a given string, extract the different
# colon separated fields and return a hash
# of the applicable directives
#
# Force all directives to lowercase to prevent
# typos or having to remember capitilization.
#
# Preserve case on commands.
#
# Returns:
#   array context   =>  hash of the commands
#   scalar context  =>  hash ref of the commands
#   failure         =>  undef
########################################
sub _get_template_directives {
    my $line   = shift;
    my $cmds   = {};     # a hash ref of the current commands
    my $log = Log::Log4perl->get_logger("Net::Autoconfig");

    chomp($line);

    if ($line =~ /^:.*:$/)
    {
        # directives only
        my @line_directives;
        $line =~ s/^://;
        $line =~ s/:$//;
        $line =~ s/\\:/~!~/g;
        $line =  lc $line;

        @line_directives = split(":", $line);

        foreach my $directive (@line_directives)
        {
            &_add_directive($directive, $cmds);
        }
    }
    elsif ($line =~ /^:/)
    {
        # directives followed by a command
        my @line_directives;
        my $param;
        $line =~ s/^://;
        $line =~ s/\\:/~!~/g;

        @line_directives = split(":", $line);

        for (my $elem_count = 0; $elem_count < scalar(@line_directives); $elem_count++)
        {
            $log->trace("Directive $elem_count of " . scalar(@line_directives)
                        . " = " . $line_directives[$elem_count]);

            # The last value of the array is a command.
            if ($elem_count == (scalar(@line_directives) - 1))
            {
                my $cmd;
                my $param;
                $cmd = "cmd";
                $param = $line_directives[$elem_count];
                $param =~ s/~!~/:/g;
                $param =~ s/^\s*//;
                $param =~ s/\s*$//;
                $cmds->{cmd} = $param;
                $log->trace("Added command: $param");
                last;
            }
            else
            {
                &_add_directive(lc $line_directives[$elem_count], $cmds);
            }
        }
    }
    else
    {
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;
        $cmds->{cmd} = $line;
    }

    return wantarray ? %$cmds : $cmds;
}

########################################
# _add_directive
# private method
#
# For a given directive, add it to the speified
# hash ref.  If the directive is invalid, undef
# If the directive is valid, return TRUE.
#
# The return value is only for error checking.  The has
# ref is modified directly.
#
# Returns:
#   valid directive =>  TRUE
#   invalid directive   =>  undef
########################################
sub _add_directive {
    my $directive = shift;
    my $hash      = shift;
    my $log = Log::Log4perl->get_logger("Net::Autoconfig");
    my $cmd;
    my $param;
    $directive =~ s/~!~/:/g;

    $log->trace("Directive = '$directive'");
    $directive    =~ /(\w+)\s*(.*)/;
    $cmd          = $1;
    $2 and $param = $2;
    if ($param)
    {
        $param =~ s/^\s*//;
        $param =~ s/\s*$//;
    }

    if (exists $file_directives->{$cmd})
    {
        my $regex = $file_directives->{$cmd};
        if (not $regex)
        {
            # no parameter expected
            # Special case for required/optional since it toggles a value
            if ($cmd =~ /required/i)
            {
                $hash->{'required'} = TRUE;
                $log->trace("Setting command to required: ". TRUE);
            }
            elsif ($cmd =~ /optional/i)
            {
                $hash->{'required'} = FALSE;
                $log->trace("Setting command to optional: ". FALSE);
            }
            else
            {
                $hash->{$cmd} = TRUE;
            }
            return TRUE;
        }
        elsif (not $param)
        {
            $log->warn("No parameter specified for command '$cmd'.");
            return;
        }
        elsif ($param =~ /$regex/)
        {
            if ($cmd =~ /wait/i)
            {
                $hash->{'cmd'} = 'wait';
                $hash->{'timeout'} = $param;
            }
            else
            {
                $hash->{$cmd} = $param;
            }
            $log->trace("Comand '$cmd' with param '$param'");
            return TRUE;
        }
        else
        {
            $param or $param = "";
            $log->warn("Invalid parameter '$param' for command '$cmd'");
            return;
        }
    }
    else
    {
        $param or $param = "";
        $log->warn("Unknown command: '$cmd' with parameter '$param'");
        return;
    }
    return;
}

########################################
# _prefix_to_netmask
#
# Given a prefix, return the corresponding
# netmask. 
#
# Returns:
#   netmask upon success
#   undef   upon failure
########################################
sub _prefix_to_netmask {
    my $prefix = shift;
    my $prefix_octets;
    my $prefix_remainder;
    my @netmask;

    ($prefix) or return;
    ($prefix =~ /\/\d{1,2}$/) or return;

    $prefix =~ s/\///;

    $prefix_octets = int($prefix / 8);
    $prefix_remainder = ($prefix % 8);

    my $prefix_values = {
                0   =>  "0",
                1   =>  "128",
                2   =>  "192",
                3   =>  "224",
                4   =>  "240",
                5   =>  "248",
                6   =>  "252",
                7   =>  "254",
                8   =>  "255",
                };

    foreach my $octet (1..4)
    {
        if ($prefix_octets > 0)
        {
            $prefix_octets--;
            push(@netmask, $prefix_values->{8});
        }
        elsif ($prefix_remainder)
        {
            push(@netmask, $prefix_values->{$prefix_remainder});
            $prefix_remainder = 0;
        }
        else
        {
            push(@netmask, $prefix_values->{0});
        }
    }
    return wantarray ? @netmask : join(".", @netmask);
}


########################################
# _netmask_to_prefix
#
# Given a netmask, return the corresponding
# prefix "/\d{1,2}"
#
# Returns:
#   prefix  upon success
#   undef   upon failure
########################################
sub _netmask_to_prefix {
    my $netmask = shift;
    my @netmask;         # the octets of the netmask
    my $prefix = 0;      # the prefix form of the netmask
    my $log = Log::Log4perl->get_logger('Net::Autoconfig');

    my %netmask_values = {
            255 =>  "8",
            254 =>  "7",
            252 =>  "6",
            248 =>  "5",
            240 =>  "4",
            224 =>  "3",
            192 =>  "2",
            128 =>  "1",
            0   =>  "0",
            };
    
    if (! $netmask)
    {
        $log->info("No netmask was specified.");
        return;
    }

    @netmask = split(/\./, $netmask);

    if ( @netmask != 4)
    {
        $log->info("Invalid netmask. '" . $netmask . "'");
        return;
    }

    foreach my $octet (@netmask)
    {
        ($octet > 255) and $log->info("Netmask octect > 255");
        ($octet < 0)   and $log->info("Netmask octect < 0");
            
        $prefix += $netmask_values{$octet};
    }
    return $prefix;
}

# Modules must return true.
TRUE;


__END__

############################################################
# Documentation
############################################################

=head1 NAME

Net::Autoconfig - Perl extension for provisioning or reconfiguring network devices.

=head1 SYNOPSIS

  use Net::Autoconfig::Device;

  my $default_device = Net::Autoconfig::Device->new();
  my $preconfigured_device = Net::Autoconfig::Device->new(@key_value_pairs);

  $default_device->hostname("Device 1");
  $default_device->ip_addr("192.168.0.1", "/24");
  $default_device->ip_addr("192.168.0.1", "255.255.255.0");
  $default_device->set_attributes(@key_value_pairs);

  print "Hostname: " . $preconfigured_device->ip_addr();

  my ($ip_addr, $netmask, $prefix) = $preconfigured_device->ip_addr();
  print "IP info: $ip_addr$prefix ($netmask)";

  my $something   = $preconfigured_device->get_attrib("somthing");
  my %device_data = $preconfigured_device->get_attrib();

=head1 DESCRIPTION

Net::Autoconfig was created to fill the void of having a utility
to configured / provision devices in an automated way.  The reason
for its existence came about from having to deploy 150 new switches
that were almost identically configured, except for the names,
ip addresses and vlans.  The devices had to be unpacked, firmware
upgraded, given an initial configuration, and then given their
final configuration.  This process is error-prone and takes a long
time.  Using this module enabled one person to configure all 150
switches within a week.

=head1 Methods

=head2 Public Methods

=over

=item new()

 Create a new Net::Autoconfig::Device object.
 Additional info can be configured after the object has been created.
 Pass an array with ( key1 => value1, key2 => value2, ...) to initialize
 the object with those key values.

=over

=item $device->new();

    Returns a Net::Autoconfig::Device object with default values.

=item $device->new(@key_value_array);

    Returns a Net::Autoconfig::Device object with user defined values.

=back

=item hostname()

 Either returns or sets the hostname of the device depending on if
 a parameter is passed or not.

=over

=item $device->hostname();

returns the hostname

=item $device->hostname("some_host");

sets the hostname and returns undef

=item $device->hostname(non string and not undef);

Error!, returns true

=back

=item ip_addr()

 Either sets the ip address or returns the ip addresses (and subnet and
 prefix if requested).

=over

=item $device->ip_addr()

    $ip_address = $device->ip_addr();
    ($ip_address, $netmask, $prefix) = $device->ip_addr();

=item $device->ip_addr("192.168.10.1");

    Sets the ip address

    returns undef if successful

    returns TRUE if failure

=item $device->ip_addr("192.168.10.1", "255.255.255.0");

=item $device->ip_addr("192.168.10.1", "/24");

    Sets the ip address and the subnet/netmask.  The method will
    add both prefix and netmask to the device.  Send either the
    netmask or the prefix.  Whichever you prefer. The method will
    calculate the other one for you.

    The prefix must be in the form "/\d\d?".  I.e., it needs the
    starting forward slash and must be followed by one or two
    digits.

    returns undef for success

    returns TRUE for failure

=back

=item get_attrib()

Get the value of the specified attribute, or get a hash ref of all of
the attribute => value pairings.  This provides a mechanism for getting
attributes that are either part of the module, or that you have defined.
Returns undef if an attribute does not exist.

=over

=item $favorite_color = $device->get_param("fav_color");

=item $my_attributes = $device->get_param();

    E.g.

    $my_attritubes = {
        hostname    =>  "",
        ip_addr     =>  "",
        ...
        fav_color   =>  "green",
    }

=back

=item set_attrib()

Set the value of an attribute.  If the attribute does not
yet exist, create it.

This method is used by passing an array to the method.  The
method then adds/overwrites existing key => value pairs
to the object.

=over

=item $device->set_attrib("model", "hp2600");

=item @attribs = ( model => "hp2600", vendor => "hp" );

Returns undef for success
Returns TRUE for failure

=back

=head1 SEE ALSO

    Net::Autoconfig

=head1 AUTHOR

Kevin Ehlers E<lt>kevin@uoregon.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kevin Ehlers, University of Oregon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

