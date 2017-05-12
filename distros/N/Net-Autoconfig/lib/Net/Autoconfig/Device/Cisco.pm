package Net::Autoconfig::Device::Cisco;

use 5.008008;
use strict;
use warnings;

use base "Net::Autoconfig::Device";
use Log::Log4perl qw(:levels);
use Expect;
use version; our $VERSION = version->new('v1.1.1');

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
my $expect_ssh_key_cmd   = '[
                            -re => "continue connecting",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("yes\n"); sleep(1);
                            }
                        ]';
my $expect_username_cmd  = '[
                            -re => "name:",
                            sub
                            {
                                $session->clear_accum();
                                $session->send($self->username . "\n");
                                sleep(1);
                            }
                        ]';
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
                            -re => ">",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("\n");
                                sleep(1);
                                $connected_to_device = TRUE;
                            }
                        ]';
my $expect_priv_mode_cmd = '[
                            -re => "#",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("\n");
                                sleep(1);
                                $self->admin_status(TRUE);
                                $connected_to_device = TRUE;
                            }
                        ]';
my $expect_enable_cmd = '[
                            -re => ">",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("enable\n");
                                sleep(1);
                            }
                        ]';
my $expect_enable_passwd_cmd = '[
                            -re => "[Pp]assword:",
                            sub
                            {
                                $session->clear_accum();
                                $session->send($self->enable_password . "\n");
                                sleep(1);
                            }
                        ]';
my $expect_already_enabled_cmd = '[
                            -re => "#",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("\n");
                                sleep(1);
                                $already_enabled = TRUE;
                            }
                        ]';
my $expect_disable_paging_cmd = '[
                            -re => "#",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("terminal length 0\n");
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
# create a new Net::Autoconfig::Device::Cisco object.
#
# If passed an array, it will assume those are key
# value pairs and assign them to the device.
#
# If no values are defined, then default ones are assigned.
#
# Returns:
#   A Net::Autoconfig::Device::Cisco object
########################################
sub new {
    my $invocant = shift; # calling class
    my $class    = ref($invocant) || $invocant;
    my $self     = {
                    @_,
                    invalid_cmd_regex   =>  '[iI]nvalid input detected',
                    };
    my $log      = Log::Log4perl->get_logger('Net::Autoconfig');

    $log->debug("Creating new Net::Autoconfig::Device::Cisco");
    return bless $self, $class;
}



########################################
# connect
# public method
#
# overloads the parent method.
# Takes into account the ecentricities of
# cisco devices.'
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
                            eval $expect_ssh_key_cmd,
                            eval $expect_username_cmd,
                            eval $expect_password_cmd,

                            # Check to see if we already have access
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_username_cmd,
                            eval $expect_password_cmd,
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_password_cmd,
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
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
# cisco devices.
#
# Returns:
#   success = undef
#   failure = reason for failure (aka a true value)
########################################
sub get_admin_rights {
    my $self     = shift;
    my $password = $self->enable_password;
    my $log      = Log::Log4perl->get_logger("Net::Autoconfig");
    my $command_failed;       # indicates of the command failed.
    my $already_enabled;      # indicates if already in admin mode
    my @expect_commands;      # the commands to run on the device
    my $session;              # the expect session

    # Do some sanity checking
    $session = $self->session;
    if (not $session)
    {
        $log->warn("No session defined for get admin rights.");
        return "No session defined for get admin rights.";
    }

    if ($self->admin_status)
    {
        $log->debug("Already have admin rights.");
        return;
    }

    $log->debug("Getting admin rights.");

    ####################
    # Setup Expect command array
    #
    # The commands are defined for the class, but they need
    # to be eval'ed before we can use them.
    ####################
    # Setup the expect commands to get admin rights
    # send "enable"
    # send the enable password
    # verify priv mode
    ####################
    push(@expect_commands, [
                            eval $expect_enable_cmd,
                            eval $expect_already_enabled_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_enable_passwd_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_priv_mode_cmd,
                    ]);

    foreach my $command (@expect_commands)
    {
        $session->expect(MEDIUM_TIMEOUT, @$command, eval $expect_timeout_cmd);
        if ($command_failed)
        {
            $log->warn("Command failed.");
            $log->debug("Failed command(s): " . @$command);
            $self->admin_status(FALSE);
            return "Enable command failed.";
        }
        elsif ($already_enabled)
        {
            $log->info("Already have admin privileges");
            last;
        }
    }

    $log->debug("Got admin rights");
    $self->admin_status(TRUE);
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

    $log->debug("Disabling paging");

    $session->expect(MEDIUM_TIMEOUT, eval $expect_disable_paging_cmd, eval $expect_timeout_cmd);
    if ($command_failed)
    {
        $log->warn("Failed to disable paging.  The rest of the configuration could fail.");
        return "Failed - paging command timed out";
    }

    $session->send("\n");

    $log->debug("Paging disabled.");

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

Net::Autoconfig::Device::Cisco - Perl extension for provisioning or reconfiguring network devices.

=head1 SYNOPSIS

  use Net::Autoconfig::Device::Cisco;

  my %data = (
               hostname        => dev1,
               username        => user1,
               password        => pass1,
               enable_password => enable1,
               snmp_version    => '2c',
               snmp_community  => 'public',
            );
  my $device = Net::Autoconfig::Device::Cisco->new(%data);

  $device->connect();
  $device->get_admin_rights();
  $device->disable_paging();
  $device->discover_dev_type();          # always returns Net::Autoconfig::Device::Cisco
  $device->configure($config_template);  # see Net::Autoconfig::Template

=head1 DESCRIPTION

This essentially only overloads the expect commands and handles some
of the idiosyncrasies of Cisco devices regarding login, paging, etc.

For more information, see Net::Autoconfig::Device.

=head1 Overloaded Methods

All commands from Net::Autoconfig::Device are inhereted by this
module.  Some of the default Net::Autoconfig::Device commands
are overloaded.

=over

=item new()

Create a new Net::Autoconfig::Device::Cisco object.
Additional info can be configured after the object has been created.
Pass an array with ( key1 => value1, key2 => value2, ...) to initialize
the object with those key values.

=item connect()

Connect to the device using the specified method, username and password

Returns:
 Success = undef
 Failure = reason why it failed (aka true)

=item discover_dev_type()

Returns the class of the object.  Useful if you want to know
what the specific module/class of this device.

=item get_admin_rights()

Gain administrative rights on this device using the specified
password/credentials.  In the case of Cisco devices, this uses
the C<enable> command.  If admin access is already granted,
this keeps it the same.

Returns:
 Success = undef
 Failure = reason why it failed (aka true)

=item disable_paging()

Disable paging on the terminal.  I.e. make it so  the switch
doesn't prompt to see the next screen of output.  It just writes
it all to the screen.

In case you wanted to know, the Cisco command for doing this is
C<terminal length 0>

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

