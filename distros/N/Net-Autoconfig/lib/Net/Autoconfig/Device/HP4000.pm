package Net::Autoconfig::Device::HP4000;

use 5.008008;
use strict;
use warnings;

use base "Net::Autoconfig::Device";
use Log::Log4perl qw(:levels);
use Data::Dumper;
use Expect;
use version; our $VERSION = version->new('v1.0.1');

#################################################################################
## Constants and Global Variables
#################################################################################

use constant TRUE   =>  1;
use constant FALSE  =>  0;
use constant LONG_TIMEOUT   => 30;
use constant MEDIUM_TIMEOUT => 15;
use constant SHORT_TIMEOUT  =>  5;

####################
# Expect Command Definitions
# These statements are strings, which need to be
# eval'ed within the methods to get their
# actual values.  This provides a way to pre-declare
# common expect commands without having to copy-paste
# them into each and every method that uses them.
# This incurs a performance hit, but I think it's
# worth it.
#
# Yay!
####################
my $expect_password_cmd = '[
                            -re => "word[.:.]",
                            sub
                            {
                                $session->clear_accum();
                                $session->send($self->password . "\n");
                                sleep(1);
                            }
                        ]';
my $expect_exec_mode_cmd = '[
                            -re => "Switch",
                            sub
                            {
                                sleep(1);
                                $connected_to_device = TRUE;
                            }
                        ]';
my $expect_timeout_cmd = '[
                    timeout =>
                        sub
                        {
                            $command_failed = TRUE;
                        }
                    ]';

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
# create a new Net::Autoconfig::Device::HP4000 object.
#
# If passed an array, it will assume those are key
# value pairs and assign them to the device.
#
# If no values are defined, then default ones are assigned.
#
# Returns:
#   A Net::Autoconfig::Device::HP4000 object
########################################
sub new {
    my $invocant = shift; # calling class
    my $class    = ref($invocant) || $invocant;
    my $self     = {
                    @_,
                    invalid_cmd_regex   => 'failed',
                    };
    my $log      = Log::Log4perl->get_logger( $class );

    $log->debug("Creating new Net::Autoconfig::Device::HP4000");
    $self = bless $self, $class;

    # HP 4000s only have telnet access
    # and use a different password for
    # mgmt access.  So, assume an admin
    # password was specified
    $self->access_method('telnet');
    $self->admin_status(TRUE);
    $self->paging_disabled(TRUE);

    return $self;
}



########################################
# connect
# public method
#
# overloads the parent method.
# Takes into account the ecentricities of
# hp devices.'
########################################
sub connect {
    my $self = shift;
    my $session;              # a ref to the expect session
    my $access_command;       # the string to use to the telnet/ssh app.
    my $result;               # the value returned after executing an expect cmd
    my @expect_commands;      # the commands to run on the device
    my $spawn_cmd;            # command expect uses to connect to the device
    my $log = Log::Log4perl->get_logger("Net::Autoconfig");

    # Expect success/failure flags
    my $connected_to_device;      # indicates a successful connection to the device
    my $command_failed;           # indicates a failed     connection to the device

    # Do some sanity checking
    if (not $self->hostname)
    {
        $log->warn("No hostname defined for this device.");
        return "No hostname defined for this devince.";
    }

    if (not $self->access_method)
    {
        $log->warn("Access method for " . $self->hostname . " not defined.");
        return "Access method not defined.";
    } 
    
    if (not $self->access_cmd)
    {
        $log->warn("Access command for " . $self->hostname . " not defined.");
        return "Access command not defined";
    }

    # Setup the access command
    if ($self->access_method =~ /^ssh$/)
    {
        # Force using ssh version 1 due to old firmware problems.
        $spawn_cmd = join(" ", $self->access_cmd, "-l", $self->username, $self->hostname);
    }
    else
    {
        $spawn_cmd = join(" ", $self->access_cmd, $self->hostname);
    }

    # Okay, let's get on with connecting to the device
    $session = $self->session;
    if (&_invalid_session($session))
    {
        $log->info("Connecting to " . $self->hostname);
        $log->debug("Using command '" . $self->access_cmd . "'");
        $log->debug("Spawning new expect session with: '$spawn_cmd'");
        eval
        {
            $session = new Expect;
            $session->raw_pty(TRUE);
            $session->spawn($spawn_cmd);
        };
        if ($@)
        {
            $log->warn("Connecting to " . $self->hostname . " failed: $@");
            return $@;
        }
    }
    else
    {
        $log->info("Session for ". $self->hostname . " already exists.");
    }

    # Enable dumping data to the screen.
    if ($log->is_trace() || $log->is_debug() )
    {
        $session->log_stdout(TRUE);
    }
    else
    {
        $session->log_stdout(FALSE);
    }

    ####################
    # Setup Expect command array
    #
    # The commands are defined for the class, but they need
    # to be eval'ed before we can use them.
    ####################
    # Setup the expect commands to do the initial login.
    # Up to four commands may need to be run:
    # accept the ssh key
    # send the username
    # send the password
    # verify connection (exec or priv exec mode)
    ####################
    push(@expect_commands, [
                            eval $expect_password_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_exec_mode_cmd,
                    ]);

    foreach my $command (@expect_commands)
    {
        $session->expect(MEDIUM_TIMEOUT, @$command, eval $expect_timeout_cmd);
        if ($log->level == $TRACE)
        {
            $log->trace("Expect matching before: " . $session->before);
            $log->trace("Expect matching match : " . $session->match);
            $log->trace("Expect matching after : " . $session->after);
        }
        if ($connected_to_device)
        {
            $log->debug("Connected to device " . $self->hostname);
            $self->session($session);
            last;
        }
        elsif ($command_failed)
        {
            $log->warn("Failed to connect to device " . $self->hostname);
            $log->debug("Failed on command: " , @$command);
            $session->soft_close();
            $self->session(undef);
            last;
        }
    }

    return $connected_to_device ? undef : 'Failed to connect to device.';
}

########################################
# discover_dev_type
# public method
#
# overloads the parent method.
#
# Since this is already discovered,
# return what type of device it is.
########################################
sub discover_dev_type {
    my $self = shift;
    return ref($self);
}

########################################
# get_admin_rights
# public method
#
# overloads the parent method.
# Takes into account the ecentricities of
# hp devices.
#
# Returns:
#   success = undef
#   failure = reason for failure (aka a true value)
########################################
sub get_admin_rights {
    my $self     = shift;
    my $log      = Log::Log4perl->get_logger("Net::Autoconfig");

    $self->admin_status(TRUE);
    $log->debug("Admin rights not fully implemented for hp4000s");

    return;
}

########################################
# disable_paging
# public method
#
# Disable terminal paging (press -Enter-
# to continue) messages.  They cause problems
# when using expect.
#
# Returns:
#   success = undef
#   failure = reason for failure
########################################
sub disable_paging {
    my $self = shift;
    my $session;         # the object's expect session
    my $log           = Log::Log4perl->get_logger("Net::Autoconfig");
    my $command_failed;  # a flag to indicate if the command failed
    my @commands;        # an array of commands to execute

    $session = $self->session;
    if (&_invalid_session($session))
    {
        return "Failed - session not defined";
    }

    $log->debug("No paging for this device - It's menu based.");

    return;
}

########################################
# configure
# public method
#
# Configure a device using the
# specified template.
#
# Template data should be in the form of
# a hash:
# $template_data = {
#   {cmds}    = [ {cmd 1}, {cmd 2}, {cmd 3} ]
#   {default} = { default data }
#
# Returns
#    success = undef
#    failure = Failure message.
########################################
sub configure {
    my $self          = shift;
    my $template_data = shift;
    my $session;      # the object's expect session
    my $error_cmd;    # expect cmd to see if a cmd was invalid
    my $error_flag;   # indicates if the command was invalid
    my $log           = Log::Log4perl->get_logger("Net::Autoconfig");
    my $last_cmd;     # record keeping for error reporting

    $log->trace("Using the hp4000s specific configure method!");


    # Let's do some sanity checking
    if (not $template_data)
    {
        $log->warn("Failed - No template data");
        return "Failed - No template data";
    }

    if (&_invalid_session($self->session))
    {
        my $hostname = $self->hostname || "no hostname";
        $log->warn("Failed - No session for " . $hostname);
        return "Failed - No session for " . $hostname;
    }

    if (not $self->admin_status)
    {
        my $hostname = $self->hostname || "no hostname";
        $log->warn("Failed - do not have admin access to device.");
        return "Failed - do not have admin access to device.";
    }
    
    if (not exists $template_data->{default})
    {
        $template_data->{default} = {};
    }
    $session = $self->session;

    # Enable verbose debugging
    if ( $log->is_trace )
    {
        $session->debug(3);
    }


    # Each cmd is a hash ref
    # Join it with the default data.  The cmd data
    # will overwrite the default data.  Yay!
    COMMAND:
    foreach my $cmd (@{ $template_data->{cmds} })
    {
        my $expect_cmd;        # the command to run on the CLI
        my $error_cmd;         # the cmd that detects an error/invalid command
        my $command_failed;    # a flag to indicate if the command failed
        my $timeout_cmd;       # what to do if there's a timeout

        # This is a perfance hit for each command.  Does it matter?
        if ($cmd->{required} )
        {
            $timeout_cmd = eval $expect_timeout_cmd;
        }
        else
        {
            undef $timeout_cmd;
        }

        if ( $self->replace_command_variables( $cmd ) )
        {
            $self->error_end_session( "Failed to replace command variables" );
            return "Command failed.";
        }

        # HP4000s have Microsoft style newlines
        # newlines = MS new lines = carriage return + newlie
        $cmd->{cmd} =~ s/\n/\r\n/g;

        $error_cmd = [
                    -re =>  $self->invalid_cmd_regex,
                    sub
                    {
                        $log->warn("Invalid command entered! '$last_cmd'");
                        $command_failed = TRUE;
                    }
                    ];

        $expect_cmd = [
                    -re =>  $cmd->{regex},
                    sub
                    {
                        $session->clear_accum();
                        $session->send($cmd->{cmd});
                    }
                    ];


        # Okay, send the command
        if ($cmd->{cmd} =~ /wait/i)
        {
            $session->expect($cmd->{timeout}, [ -re => "BOGUS REGEX" ] );
        }
        else
        {
            $session->expect($cmd->{timeout}, $error_cmd, $expect_cmd, $timeout_cmd);
        }

        if ($log->is_trace or $log->is_debug )
        {
            $log->trace("== Expect Matches ==");
            $log->debug(Dumper($cmd));
            $log->trace("Expect before: " . $session->before);
            $log->trace("Expect match : " . $session->match );
            $log->trace("Expect after : " . $session->after );
        }

        $last_cmd = $cmd->{cmd};

        if ($command_failed)
        {
            # close session and alarm
            $log->trace("== Expect Matches - Failed Command ==");
            $log->debug(Dumper($cmd));
            $log->trace("Expect before: " . $session->before);
            $log->trace("Expect match : " . $session->match );
            $log->trace("Expect after : " . $session->after );
            $self->error_end_session("Required command failed for " . $self->hostname);
            return "Command failed.";
        }
        sleep(2);
    }

    # Disable verbose expect debugging
    if ( $log->is_trace )
    {
        $session->debug(0);
    }

    # One last check to see if the last comand was invalid.
    # This is different than the one in the COMMAND loop
    # The Expect->expect method can't exit or return from _this_
    # method.  So, detect the error and do our own exiting.
    $error_cmd = [
                -re =>  $self->invalid_cmd_regex,
                sub
                {
                    $error_flag = TRUE;
                    $log->warn("Invalid command entered! '"
                    . $template_data->{cmds}->[-1]->{cmd}
                    . "'" 
                    );
                }
                ];
    
    if ($log->is_trace)
    {
        $log->trace( "Error command: " . Dumper($error_cmd) );
    }

    $session->expect(SHORT_TIMEOUT, $error_cmd );

    if ($error_flag)
    {
        $self->error_end_session("Last command entered was invalid for " . $self->hostname);
        return "Last command was invalid.";
    }

    $log->info("All commands executed successfullly for " . $self->hostname . ".");
    return;
}

############################################################
# Private Methods
############################################################


########################################
# _invalid_session
# private method
#
# Determine if this is a valid session.
# We're using expect, so it has to be an
# expect object reference, and it has to
# be defined.
#
# Returns:
#   true if invalid
#   undef if valid
########################################
sub _invalid_session {
    my $session = shift;

    if (not defined $session)
    {
        return TRUE;
    }
    elsif (not ref($session))
    {
        return TRUE;
    }
    elsif (not ref($session) eq 'Expect')
    {
        return TRUE;
    }
    else
    {
        return;
    }
}

# Modules must return true.
TRUE;


__END__

############################################################
# Documentation
############################################################

=head1 NAME

Net::Autoconfig::Device::HP4000 - Perl extension for provisioning or reconfiguring network devices.

=head1 SYNOPSIS

  use Net::Autoconfig::Device::HP4000;

  my %data = (
               hostname        => dev1,
               username        => user1,
               password        => pass1,
               enable_password => enable1,
               snmp_version    => '2c',
               snmp_community  => 'public',
            );
  my $device = Net::Autoconfig::Device::HP4000->new(%data);

  $device->connect();
  $device->get_admin_rights();
  $device->disable_paging();
  $device->discover_dev_type();          # always returns Net::Autoconfig::Device::HP4000
  $device->configure($config_template);  # see Net::Autoconfig::Template

=head1 DESCRIPTION

This essentially only overloads the expect commands and handles some
of the idiosycrasies of HP devices regarding login, paging, etc.

For more information, see Net::Autoconfig::Device.

=head1 Overloaded Methods

All commands from Net::Autoconfig::Device are inhereted by this
module.  Some of the default Net::Autoconfig::Device commands
are overloaded.

=over

=item new()

Create a new Net::Autoconfig::Device::HP4000 object.
Additional info can be configured after the object has been created.
Pass an array with ( key1 => value1, key2 => value2, ...) to initialize
the object with those key values.

=item connect()

Connect to the device using the specified method, username and password

Returns:
 Success = undef
 Failure = reason why it failed (aka true)

=item discover_dev_type()

Returns the class of the ojbect.  Useful if you want to know the
specific module/class of this device.

=item get_admin_rights()

Gain administrative rights on this device using the specified
password/credentials.  In the case of HP devices, this uses
the C<enable> command.  If admin access is already granted,
this keeps it the same.

Returns:
 Success = undef
 Failure = reason why it failed (aka true)

=item disable_paging()

Disable paging on the terminal.  I.e. make it so  the switch
doesn't prompt to see the next screen of output.  It just writes
it all to the screen.

In case you wanted to know, the HP command for doing this is
C<terminal length 1000>

Returns:
 Success = undef
 Failure = reason why it failed (aka true)

=back

=head1 SEE ALSO

Net::Autoconfig, Net::Autoconfig::Device, and Net::Autoconfig::Template

=head1 AUTHOR

Kevin Ehlers E<lt>kevin@uoregon.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kevin Ehlers, University of Oregon.
All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRENTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE
LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
OTHER PARTIES PROVIDE THE PROGRAM “AS IS” WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM
PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR
OR CORRECTION.

=cut

