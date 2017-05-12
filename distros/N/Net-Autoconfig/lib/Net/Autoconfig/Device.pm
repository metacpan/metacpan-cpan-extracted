package Net::Autoconfig::Device;

use 5.008008;
use strict;
use warnings;

use base "Net::Autoconfig";
use Log::Log4perl qw(:levels);
use Net::SNMP;
use Expect;
use Net::Ping;
use Data::Dumper;
use version; our $VERSION = version->new('v1.4.6');

#################################################################################
## Constants and Global Variables
#################################################################################

use constant TRUE   =>  1;
use constant FALSE  =>  0;
use constant LONG_TIMEOUT   => 30;
use constant MEDIUM_TIMEOUT => 15;
use constant SHORT_TIMEOUT  =>  5;

use constant SSH_CMD    =>  "/usr/bin/ssh";
use constant TELNET_CMD =>  "/usr/bin/telnet";

# Default device parameters
use constant DEFAULT_INVALID_CMD_REGEX => '[iI]nvalid input';
use constant DEFAULT_SNMP_VERSION      => "2c";
use constant DEFAULT_ACCESS_METHOD     => "ssh";

####################
# device    =>  matching regex tables
####################
use constant SPECIFIC_DEVICE_MODEL_REGEX => {
    hp2512        =>    'Switch 2512',
    hp2524        =>    'Switch 2524',
    hp2626        =>    'Switch 2626\s',
    hp2650        =>    'Switch 2650\s',
    hp2626pwr     =>    'Switch 2626-PWR',
    hp2650pwr     =>    'Switch 2650-PWR',
    hp2824        =>    'Switch 2824',
    hp2848        =>    'Switch 2848',
    'hp2810-24g'  =>    'Switch 2810-24',
    'hp2810-48g'  =>    'Switch 2810-48',
    'hp2900-24g'  =>    'Switch 2900-24',
    'hp2900-48g'  =>    'Switch 2900-48',
    'hp3500-24g'  =>    'Switch 3500-24',
    'hp3500-48g'  =>    'Switch 3500-48',
    hp4104        =>    'Switch 4104',
    hp4108        =>    'Switch 4108',
    hp4208        =>    'Switch 4208',
    hp6108        =>    'Switch 6108',
    hub224        =>    'J2603A/B',
    hub48         =>    'J2603A ',
    c3550         =>    'C3550',
    c3560         =>    'C3560-',
    c3560g        =>    'C3560G-',
    c3560e        =>    'C3560E-',
    c3750         =>    'C3750-',
    c3750g        =>    'C3750G-',
    c3750e        =>    'C3750E-',
    c2960         =>    'C2960-',
    c2960g        =>    'C2960G-',
};

use constant GENERIC_DEVICE_MODEL_REGEX => {
    hp1600        =>    'Switch 16',
    hp2500        =>    'Switch 25',
    hp2600        =>    'Switch 26',
    hp2800        =>    'Switch 28(2|4)',
    hp2810        =>    'Switch 2810',
    hp2900        =>    'Switch 29',
    hp3500        =>    'Switch 35',
    hp4100        =>    'Switch 41',
    hp4200        =>    'Switch 42',
    hp6100        =>    'Switch 61',
    hp4000        =>    'Switch 40',
    hp8000        =>    'Switch 80',
    hp224         =>    '1991-1994',
    hub           =>    'J2603A',
    c3xxx         =>    'C3(5|6|7)',
    c29xx         =>    'C29(5|6)',
};

use constant ALL_TYPES_MODEL_HASH => {
    hp1600        =>  'hp_switch',
    hp2600        =>  'hp_switch',
    hp2500        =>  'hp_switch',
    hp2800        =>  'hp_switch',
    hp2810        =>  'hp_switch',
    hp2900        =>  'hp_switch',
    hp3500        =>  'hp_switch',
    hp4100        =>  'hp_switch',
    hp4200        =>  'hp_switch',
    hp6100        =>  'hp_switch',
    hp4000        =>  'hp_switch',
    hp8000        =>  'hp_switch',
    hp224         =>  'hp_switch',
    hub           =>  'hp_hub',
    c3xxx         =>  'cisco_switch',
    c29xx         =>  'cisco_switch',
};

use constant VENDORS_REGEX => {
    'Switch 16'         =>  'HP',
    'Switch 26'         =>  'HP',
    'Switch 25'         =>  'HP',
    'Switch 28(2|4)'    =>  'HP',
    'Switch 2810'       =>  'HP',
    'Switch 29'         =>  'HP',
    'Switch 35'         =>  'HP',
    'Switch 41'         =>  'HP',
    'Switch 42'         =>  'HP',
    'Switch 61'         =>  'HP',
    'Switch 40'         =>  'HP4000',
    'Switch 80'         =>  'HP4000',
    '1991-1994'         =>  'HPHub',
    'J2603A'            =>  'HPHub',
    '(?i:cisco|C\d{4})' =>  'Cisco',
};

####################
# Expect Commands
####################

####################
# Expect Command Definitions
# These statements are strings, which need to be
# evaled within the methods to get their
# actual values.  This provides a way to pre-declare
# common expect commands without having to copy-paste
# them into each and every method that uses them.
# This incurs a performance hit, but I think its
# worth it.
#
# Define package variables for the variables.
# Do this for the following reasons:
# 1) I want to use a separate eval function to do some
#    error checking.
# 2) Eval'ing the statements is useless without the
#    correct variable references.
# 3) If a global (our) variable is locally scoped (local),
#    if the eval func. is called from that block, then
#    it will have the right values.  However, all other
#    methods/functions will have the global value.
# 4) Maybe I should change the way I eval these things.
#
####################

our $connected_to_device;
our $command_failed;

my $expect_show_version_cmd = '[
                            -re => "#",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("show version\n");
                                $log->trace($self->hostname . " - Expect CMD -  Show Version");
                                sleep(1);
                            }
                        ]';
my $expect_ssh_key_cmd   = '[
                            -re => "continue connecting",
                            sub
                            {
                                $log->trace($self->hostname . " - Expect Cmd - SSH unknown key command.");
                                $session->clear_accum();
                                $session->send("yes\n");
                                sleep(1);
                            }
                        ]';
my $expect_username_cmd  = '[
                            -re => "name:",
                            sub
                            {
                                $session->clear_accum();
                                $session->send($self->username . "\n");
                                $log->trace($self->hostname . " - Expect CMD - Sending device username");
                                sleep(1);
                            }
                        ]';
my $expect_password_cmd = '[
                            -re => "word:",
                            sub
                            {
                                $session->clear_accum();
                                $session->send($self->password . "\n");
                                $log->trace($self->hostname . " - Expect CMD - Sending device password");
                                sleep(1);
                            }
                        ]';
# Expect console login cmd.  Make sure we're using the correct 
# password.
my $expect_console_login_cmd = '[
                            -re => "word:",
                            sub
                            {
                                $log->trace($self->hostname . " - Expect Cmd - Sending console password.");
                                $session->clear_accum();
                                $session->send($self->console_password . "\n");
                                sleep(1);
                            }
                        ]';
my $expect_hp_continue_cmd = '[
                            -re => "any key to continue",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("\n");
                                $log->trace($self->hostname . " - Expect CMD - Sending HP continue command");
                                sleep(1);
                            }
                        ]';
# Find the prompt, and preserve the accumulator
my $expect_exec_mode_cmd = '[
                            -re => ">",
                            sub
                            {
                                my $accumulated;
                                $accumulated = $session->clear_accum();
                                $session->set_accum( $session->before.
                                                     $session->match.
                                                     $session->after.
                                                     $accumulated
                                                     );
                                #$session->send("\n");
                                $log->trace($self->hostname . " - Expect CMD - Got device exec mode");
                                sleep(1);
                                $connected_to_device = TRUE;
                            }
                        ]';
# Find the prompt, and preserve the accumulator
my $expect_priv_mode_cmd = '[
                            -re => "#",
                            sub
                            {
                                my $accumulated;
                                $accumulated = $session->clear_accum();
                                $session->set_accum( $session->before.
                                                     $session->match.
                                                     $session->after.
                                                     $accumulated
                                                     );
                                #$session->clear_accum();
                                #$session->send("\n");
                                $log->trace($self->hostname . " - Expect CMD - Got device admin mode");
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
                                $log->trace($self->hostname . " - Expect CMD - Sending device enable command");
                                sleep(1);
                            }
                        ]';
my $expect_enable_passwd_cmd = '[
                            -re => "[Pp]assword:",
                            sub
                            {
                                $session->clear_accum();
                                $session->send($self->enable_password . "\n");
                                $log->trace($self->hostname . " - Expect CMD - Sending device enable password");
                                sleep(1);
                            }
                        ]';
#my $expect_already_enabled_cmd = '[
#                            -re => "#",
#                            sub
#                            {
#                                $session->clear_accum();
#                                $session->send("\n");
#                                sleep(1);
#                                $already_enabled = TRUE;
#                            }
#                        ]';
my $expect_initial_console_prompt_cmd = '[
                            -re => "how and erase",
                            sub
                            {
                                $log->trace($self->hostname . " - Expect Cmd - Initial Console Prompt (Buffered) Command.");
                                $session->clear_accum();
                                sleep(3);
                                $session->send("I\n");
                                sleep(1);
                                $session->send("\r\n\r\n");
                                sleep(1);
                                $log->debug($self->hostname , " - Connected via inital console prompt cmd");
                                $connected_to_device = TRUE;
                            }
                        ]';

# Match and don't destroy the accumulated data.
my $expect_get_priv_console_output = '[
                            -re => "#",
                            sub
                            {
                                #$session->clear_accum();
                                #$session->send("\n");
                                my $accumulated;
                                $accumulated = $session->clear_accum();
                                $session->set_accum( $session->before.
                                                     $session->match.
                                                     $session->after.
                                                     $accumulated,
                                                     );
                                $log->trace($self->hostname " - Expect CMD - Got admin console output");
                                sleep(1);
                            }
                        ]';
# Compromise - set the length to 512
#     Cisco disable paging = set length to 0
#     HP    disable paging = set length to 1000
my $expect_disable_paging_cmd = '[
                            -re => "#",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("terminal length 512\n");
                                $log->trace($self->hostname . " - Expect CMD - Disabling paging");
                                sleep(1);
                            }
                        ]';
my $expect_initial_config_dialog = '[
                            -re => "initial configuration",
                            sub
                            {
                                $session->clear_accum();
                                $session->send("no\n");
                                $log->trace($self->hostname . " - Expect CMD - Bypassing initial config dialog");
                                sleep(1);
                            }
                        ]';
my $expect_timeout_cmd = '[
                    timeout =>
                        sub
                        {
                            $session->clear_accum();
                            $log->info($self->hostname . " - Expect CMD - Timeout");
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
# create a new Net::Autoconfig::Device object.
#
# If passed an array, it will assume those are key
# value pairs and assign them to the device.
#
# If no values are defined, then default ones are assigned.
#
# Returns:
#   A Net::Autoconfig::Device object
#
# Publis variable descriptions
#   See the POD below
# Private/Internal Variables
#   session
#       - Expect ref or undef
#       - contains a ref to the expect session
#   connected
#       - TRUE or FALSE
#       - indicates if a successful connection was made
#   admin_rights_status
#       - TRUE or FALSE
#       - Indicates if admin rights have been established
########################################
sub new {
    my $invocant = shift; # calling class
    my $class    = ref($invocant) || $invocant;
    my $self     = {
                    hostname            =>    "",
                    model               =>    "",
                    vendor              =>    "",
                    auto_discover       =>    TRUE,
                    admin_rights_status =>    FALSE,
                    console_username    =>    "",
                    console_password    =>    "",
                    console_hostane     =>    "",
                    console_tty         =>    "",
                    username            =>    "",
                    password            =>    "",
                    enable_password     =>    "",
                    session             =>    undef,
                    connected           =>    FALSE,
                    snmp_community      =>    "",
                    snmp_version        =>    DEFAULT_SNMP_VERSION,
                    access_method       =>    DEFAULT_ACCESS_METHOD,
                    access_cmd          =>    SSH_CMD,
                    invalid_cmd_regex   =>    DEFAULT_INVALID_CMD_REGEX,
                    @_,
                    };
    my $log      = Log::Log4perl->get_logger($class);
    my $hostname;
    bless $self, $class;

    $log->debug("Creating new device object");

    $hostname = $self->hostname;

    if ($log->is_trace())
    {
        $log->trace(Dumper($self));
    }

    # Check to see if it's using a console server
    if ($self->hostname =~ /(.*)\@(.*)/)
    {
        $log->debug("$hostname - Setting Provision mode");
        $log->debug("$hostname - using console server $2, tty/line $1");
        $self->provision(TRUE);
        $self->set('auto_discover', FALSE);
        $self->console_hostname($2);
        $self->console_tty($1);

        if ( not $self->console_username )
        {
            $log->info("$hostname - Console username not set, using access username.");
            $self->console_username($self->username);
            $log->trace("$hostname - console username = " . $self->console_username);
        }

        if ( not $self->console_password)
        {
            $log->info("$hostname - Console password not set, using access password.");
            $self->console_password($self->password);
        }
    }

    return $self->get('auto_discover') ? $self->auto_discover : $self;
}

########################################
# auto_discover
# public method
#
# Try to determine the make and model of the device.
# If it's possible, return a more specific device.
# Else, return itself (the old device)
########################################
sub auto_discover {
    my $self           = shift;
    my $vendor         = $self->vendor         || "";
    my $model          = $self->model          || "";
    my $snmp_community = $self->snmp_community || "";
    my $snmp_version   = $self->snmp_version   || "2c";
    my $session        = $self->session        || "";
    my $log            = Log::Log4perl->get_logger( ref($self) );
    my $device_type;   # The name of the module for that device.

    $log->debug($self->hostname . " - auto-discovering device.");

    $device_type = $self->lookup_model();

    if (not $device_type)
    {
        $log->info($self->hostname . " - using default device class");
    }

    # Unset "auto_discover" so it doesn't try to recurse to infinity
    $self->set('auto_discover', FALSE);

    # Make a new object of the returned device type.
    # If we didn't get one, return the same object.
    if ($device_type)
    {
        eval "require $device_type;";
        if ($@)
        {
            $log->warn($self->hostname
                    . " - Failed - unable to load module: $device_type");
            return;
        }
        $self = $device_type->new( $self->get() );
    }

    return $self;
}



########################################
# get
#
# return a value for a given attribute,
# or return all attributes as a hash or  hash ref
# if no value is passed.
########################################
sub get {
    my $self = shift;
    my @attribs = @_;
    my $ref = ref($self);
    my %data; 

    if (not @attribs)
    {
        %data = %{ $self };
    }
    elsif (scalar(@attribs) == 1)
    {
        return $self->{$attribs[0]};
    }
    else
    {
        foreach my $attrib (@attribs)
        {
            $data{$attrib} = $self->{$attrib};
        }
    }
    return wantarray ? %data : \%data;
}


########################################
#set()
#
# Set the value of an attribute.  If the attribute does not
# yet exist, create it.
# 
# Returns undef for success
# Returns TRUE for failure
############################################################
sub set {
    my $self = shift;
    my %attribs = @_;
    my $log = Log::Log4perl->get_logger( ref($self) );

    if ($self->hostname)
    {
        $log->trace($self->hostname . " - setting attribute(s)");
    }
    else
    {
        $log->trace("hostname not defined - setting attribute(s)");
    }

    foreach my $key ( keys %attribs )
    {
        $self->{$key} = $attribs{$key} || '';
    }

    return;
}


########################################
# Below are a set of accessor/mutator methods.
# They return or set values for the attribute specified
########################################
sub model {
    my $self = shift;
    my $model = shift;
    defined $model and $self->{'model'} = $model;
    return defined $model ? [] : $self->{'model'};
}
sub vendor {
    my $self = shift;
    my $vendor = shift;
    defined $vendor and $self->{'vendor'} = $vendor;
    return defined $vendor ? undef : $self->{'vendor'};
}
sub hostname {
    my $self = shift;
    my $hostname = shift;
    defined $hostname and $self->{'hostname'} = $hostname;
    return defined $hostname ? undef : $self->{'hostname'};
}
sub username {
    my $self = shift;
    my $username = shift;
    defined $username and $self->{'username'} = scalar $username;
    return defined $username ? undef : $self->{'username'};
}
sub password {
    my $self = shift;
    my $password = shift;
    defined $password and $self->{'password'} = scalar $password;
    return defined $password ? undef : $self->{'password'};
}
sub provision {
    my $self = shift;
    my $provision = shift;
    defined $provision and $self->{'provision'} = scalar $provision;
    return defined $provision ? undef : $self->{'provision'};
}
sub admin_status {
    my $self = shift;
    my $admin_status = shift;
    defined $admin_status and $self->{'admin_status'} = scalar $admin_status;
    return defined $admin_status ? undef : $self->{'admin_status'};
}
sub console_username {
    my $self = shift;
    my $console_username = shift;
    defined $console_username and $self->{'console_username'} = scalar $console_username;
    return defined $console_username ? undef : $self->{'console_username'};
}
sub console_password {
    my $self = shift;
    my $console_password = shift;
    defined $console_password and $self->{'console_password'} = scalar $console_password;
    return defined $console_password ? undef : $self->{'console_password'};
}
sub console_hostname {
    my $self = shift;
    my $console_hostname = shift;
    defined $console_hostname and $self->{'console_hostname'} = scalar $console_hostname;
    return defined $console_hostname ? undef : $self->{'console_hostname'};
}
sub console_tty {
    my $self = shift;
    my $console_tty = shift;
    defined $console_tty and $self->{'console_tty'} = scalar $console_tty;
    return defined $console_tty ? undef : $self->{'console_tty'};
}
###
sub enable_password {
    my $self = shift;
    my $enable_password = shift;
    defined $enable_password and $self->{'enable_password'} = scalar $enable_password;
    return defined $enable_password ? undef : $self->{'enable_password'};
}
sub snmp_community {
    my $self = shift;
    my $snmp_community = shift;
    defined $snmp_community and $self->{'snmp_community'} = scalar $snmp_community;
    return defined $snmp_community ? undef : $self->{'snmp_community'};
}
# The same things as snmp_community, but easier to type
# I.e. I didn't use snmp_community in some other code and this
# was easer to change than the other code.
sub community {
    my $self = shift;
    my $snmp_community = shift;
    defined $snmp_community and $self->{'snmp_community'} = scalar $snmp_community;
    return defined $snmp_community ? undef : $self->{'snmp_community'};
}
sub snmp_version {
    my $self = shift;
    my $snmp_version = shift;
    defined $snmp_version and $self->{'snmp_version'} = scalar $snmp_version;
    return defined $snmp_version ? undef : $self->{'snmp_version'};
}
sub session {
    my $self = shift;
    my $session = shift;
    defined $session and $self->{'session'} = scalar $session;
    return defined $session ? undef : $self->{'session'};
}
sub paging_disabled {
    my $self = shift;
    my $paging_disabled = shift;
    defined $paging_disabled and $self->{'paging_disabled'} = scalar $paging_disabled;
    return defined $paging_disabled ? undef : $self->{'paging_disabled'};
}


########################################
# access_method
# public method
#
# Set the access method to either ssh,
# telnet or something user defined.
# OR
# Get the access method if undef is passed
########################################
sub access_method {
    my $self = shift;
    my $access_method = shift;

    $access_method or $access_method = "";

    if ($access_method =~ /ssh/i)
    {
        $self->{'access_method'} = "ssh";
    }
    elsif ($access_method =~ /telnet/i)
    {
        $self->{'access_method'} = "telnet";
    }
    elsif ($access_method)
    {
        $self->{'access_method'} = "user_defined";
    }

    return $access_method ? undef : $self->{'access_method'};
}

########################################
# access_cmd
# public method
#
# Get the command to connect to the device.
# ssh and telnet are defined.  Anything else must
# have an absolute path or else it's ignored.
#
# Also set the access_method.  This can be
# overwritten.
#
# Specifying "ssh" or "telnet", without the
# absoluate path, will use the default
# ssh and telnet locations.
########################################
sub access_cmd {
    my $self = shift;
    my $access_cmd = shift;
    my $log = Log::Log4perl->get_logger( ref($self) );

    $access_cmd or $access_cmd = "";

    if ($access_cmd =~ /^ssh$/i)
    {
        $self->{'access_cmd'} = SSH_CMD;
    }
    elsif ($access_cmd =~ /^telnet$/i)
    {
        $self->{'access_cmd'} = TELNET_CMD;
    }
    elsif ($access_cmd =~ /^\/.+/)
    {
        $self->{'access_cmd'} = $access_cmd;
    }
    elsif ($access_cmd)
    {
        $log->warn($self->hostname . ": Access command, '$access_cmd', specified but not recognized.");
    }

    if ($access_cmd =~ /ssh/i)
    {
        $self->access_method('ssh');
    }
    elsif ($access_cmd =~ /telnet/i)
    {
        $self->access_method('telnet');
    }
    elsif ($access_cmd)
    {
        $self->access_method('user_Defined');
    }

    return $access_cmd ? undef : $self->{'access_cmd'};
}

########################################
# invalid_regex
# public
#
# Either get or set the regex that
# determines if a command was invalid
# or was not recognized by the device.
########################################
sub invalid_cmd_regex {
    my $self  = shift;
    my $regex = shift;
    defined $regex and $self->{'invalid_cmd_regex'} = $regex;
    return defined $regex ? undef : $self->{'invalid_cmd_regex'};
}

########################################
# connect
# public method
#
# Connect to a generic device using parameters
# specified in the device object, i.e.
# hostname, username and password.
#
# This expects to be overridden by a sub class
# E.g. Net::Autoconfig::Device::Cisco.
########################################
sub connect {
    my $self = shift;
    my $session;              # a ref to the expect session
    my $access_command;       # the string to use to the telnet/ssh app.
    my $result;               # the value returned after executing an expect cmd
    my @expect_commands;      # the commands to run on the device
    my $spawn_cmd;            # command expect uses to connect to the device
    my $log = Log::Log4perl->get_logger( ref($self) );

    $log->debug($self->hostname . " - using default connect method.");

    # Expect success/failure flags
    local $connected_to_device;      # indicates a successful connection to the device
    local $command_failed;           # indicates a failed     connection to the device

    # Do some sanity checking
    if (not $self->hostname)
    {
        $log->warn("No hostname defined for this device.");
        return "No hostname defined for this devince.";
    }

    if (not $self->access_method)
    {
        $log->warn($self->hostname . " - access method not defined.");
        return "Access method not defined.";
    } 
    
    if (not $self->access_cmd)
    {
        $log->warn($self->hostname . " - access command not defined.");
        return "Access command not defined";
    }

    if (not $self->username)
    {
        $log->warn($self->hostname . " - No username defined.");
        return "No username defined.";
    }

    # Setup the access command
    if ($self->access_method =~ /^ssh$/)
    {
        $spawn_cmd = join(" ", $self->access_cmd,
                            "-l", $self->username, $self->hostname);
    }
    else
    {
        $spawn_cmd = join(" ", $self->access_cmd, $self->hostname);
    }

    # Okay, let's get on with connecting to the device
    $session = $self->session;
    if (&_invalid_session($session))
    {
        $log->info($self->hostname . " - initiating connection");
        $log->debug($self->hostname . " - using command '"
                    . $self->access_cmd . "'");
        $log->debug($self->hostname
                    . " - spawning new expect session with: '$spawn_cmd'");

        if (&_host_not_reachable($self->hostname))
        {
            return "Failed " . $self->hostname . " not reachable via ping.";
        }

        eval
        {
            $session = new Expect;
            $session->raw_pty(TRUE);
            $session->spawn($spawn_cmd);
        };
        if ($@)
        {
            $log->warn($self->hostname . " Failed - connection failed: $@");
            return $@;
        }
    }
    else
    {
        $log->info($self->hostname . " - session already exists.");
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
    # hp->bypass initial login screen
    # verify connection (exec or priv exec mode)
    ####################
    push(@expect_commands, [
                            eval $expect_ssh_key_cmd,
                            eval $expect_username_cmd,
                            eval $expect_password_cmd,

                            # Used for initial configuration of cisco devices
                            eval $expect_initial_config_dialog,

                            # Check to see if we already have access
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
                    ]);
    # Handle some HP weirdness
    push(@expect_commands, [
                            eval $expect_username_cmd,
                            eval $expect_password_cmd,
                            # Get past the initial login banner
                            eval $expect_hp_continue_cmd,
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
                    ]);
    push(@expect_commands, [
                            eval $expect_password_cmd,
                            # Get past the initial login banner
                            eval $expect_hp_continue_cmd,
                            eval $expect_exec_mode_cmd,
                            eval $expect_priv_mode_cmd,
                    ]);
    push(@expect_commands, [
                            # Get past the initial login banner
                            eval $expect_hp_continue_cmd,
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
            $self->error_end_session("Failed to connect to device " . $self->hostname);
            $log->debug("Failed on command: " , Dumper($command));
            last;
        }
    }

    return $connected_to_device ? undef : 'Failed to connect to device.';
}

########################################
# console_connect
# public method
#
# Connect to a console server for a given
# hostname. Assumes various characterisitics about
# the hostname and username + password
#
# After connecting to the console server,
# this then calls the normal connect method.
#
# At this point in time, this returns undef.
########################################
sub console_connect {
    my $self = shift;
    my $hostname;   # hostname of the console server
    my $tty;        # console port name
    my $username;   # console username
    my $session;              # a ref to the expect session
    my $access_command;       # the string to use to the telnet/ssh app.
    my $result;               # the value returned after executing an expect cmd
    my @expect_commands;      # the commands to run on the device
    my $spawn_cmd;            # command expect uses to connect to the device
    my $log = Log::Log4perl->get_logger( ref($self) );

    $log->debug("Using default console connect method.");

    # Expect success/failure flags
    local $connected_to_device;      # indicates a successful connection to the device
    local $command_failed;           # indicates a failed     connection to the device

#    if ($self->_connected)
#    {
#        $log->info($self->hostname . " - connection already established.");
#        return "Connection already established.";
#    }

    # Do some sanity checking
    if (not $self->hostname)
    {
        $log->warn("No hostname defined for this device.");
        return "No hostname defined for this devince.";
    }

    if (not $self->provision)
    {
        $log->warn($self->hostname
                    . "Device not configured for provisioning"
                    . " (console server) proceeding anyway.");
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

    if (not $self->console_username)
    {
        $log->warn("Failed - No console user defined.");
        return "No console user defined.";
    }

    if (not $self->username)
    {
        $log->warn("Failed - No normal username defined.");
    }

    $hostname = $self->console_hostname;
    $username = $self->console_username;
    $tty      = $self->console_tty;

    # this could read (not $tty or not $hostname)
    if (not $tty or not $username)
    {
        $log->warn($self->hostname
                    . ' - Failed - Invalid tty@console hostname.');
        return 'Failed - Invalid tty@console hostname.';
    }

    $username = join(":", $username, $tty);

    # Setup the access command
    if ($self->access_method =~ /^ssh$/)
    {
        $spawn_cmd = join(" ", $self->access_cmd, "-l", $username, $hostname);
    }
    else
    {
        $spawn_cmd = join(" ", $self->access_cmd, $hostname);
    }

    # Okay, let's get on with connecting to the device
    $session = $self->session;
    if (&_invalid_session($session))
    {
        $log->info($self->hostname . " - Connecting to console server.");
        $log->debug($self->hostname
                    . " - Using command '" . $self->access_cmd . "'");
        $log->debug($self->hostname
                    . " - Spawning new expect session with: '$spawn_cmd'");

        if (&_host_not_reachable($hostname))
        {
            $log->warn($self->hostname . " - Failed"
                        . " - '$hostname' not reachable via ping.");
            return "Failed $hostname not reachable via ping.";
        }

        eval
        {
            $session = new Expect;
            $session->raw_pty(TRUE);
            $session->spawn($spawn_cmd);
        };
        if ($@)
        {
            $log->warn($self->hostname . " - Failed"
                        . " - Connecting to $hostname failed: $@");
            return $@;
        }
        $self->session($session);
    }
    else
    {
        $log->info($self->hostname . " - Session for already exists.");
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
    # Setup the expect commands to login to the console server.
    # This method only connects to the server, not the device.
    # Therefore, if we see the login prompt for the device, preserve
    # the output so the connect() method sees it too.
    #
    # Up to seven things may happen:
    # 1) send the password
    # 2) Bypass the "what to do with data buffer" from the console
    # 3) see and preserve a username prompt
    # 4) see and preserve a password prompt
    # 5) see an exec mode prompt
    # 6) see a  priv mode prompt
    # 7) bypass HP "continue" screen
    ####################
    push(@expect_commands, [
                            _eval($expect_console_login_cmd, $self),
                            _eval( $expect_ssh_key_cmd, $self),
                       ]);
    push(@expect_commands, [
                            _eval($expect_console_login_cmd, $self),
                            _eval($expect_initial_console_prompt_cmd, $self),
                       ]);
    push(@expect_commands, [
                            _eval($expect_initial_console_prompt_cmd, $self),
                       ]);

    # There are two cases when connecting to a console server:
    # 1) the console server has a buffer and you need to clear it
    # 2) the console server has _no_ buffer and it gives you a blank
    #    prompt.

    foreach my $command (@expect_commands)
    {
        $session->expect(MEDIUM_TIMEOUT, @$command, eval $expect_timeout_cmd);
        if ($log->level == $TRACE)
        {
            $log->trace("Expect matching before: " . $session->before);
            $log->trace("Expect matching match : " . $session->match);
            $log->trace("Expect matching after : " . $session->after);
            $log->trace("Expect command: " . Dumper($command));
        }
        if ($connected_to_device)
        {
            $log->debug($self->hostname . " - Console Buffered - Connected to device ");
            last;
        }
        elsif ($command_failed)
        {
###            $self->error_end_session("Failed - Unable to connect to device");
###            $log->debug($self->hostname . " - Failed - on command: "
###                        . Dumper($command));
            $log->debug($self->hostname . " - Console Connect Problem - Command timed out");
            last;
        }
    }

    # It may not have failed/timed out.  It could have connected and had
    # an empty buffer.
    if ($command_failed)
    {
        # Check to see if we connected to the device
        $command_failed = FALSE;
        my $expect_command = [
                    _eval($expect_initial_config_dialog, $self),
                    _eval($expect_exec_mode_cmd, $self),
                    _eval($expect_priv_mode_cmd, $self),
                    _eval($expect_username_cmd, $self),
                    _eval($expect_password_cmd, $self),
                    _eval($expect_initial_console_prompt_cmd, $self),
                    ];

        $session->clear_accum();
        $session->send("\r\n\r\n");
        sleep(1);
        $session->expect(   MEDIUM_TIMEOUT,
                            @$expect_command,
                            _eval($expect_timeout_cmd, $self)
                        );
        if ($command_failed)
        {
            $self->error_end_session("Failed - Unable to connect to device");
        }
        elsif ($connected_to_device)
        {
            $log->debug($self->hostname
                        . " - Console Not Buffered - Connected to device ");
            $self->session($session);
        }
        else
        {
            $log->error($self->hostname . " - Undefined Console State");
        }
    }

    return $connected_to_device ? undef : 'Failed to connect to device.';
}

########################################
# configure
# public method
#
# This can be overwritten in submodules
# if necessary.
# E.g. Net::Autoconfig::Device::Cisco.
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
    my $log           = Log::Log4perl->get_logger( ref($self) );
    my $last_cmd;     # record keeping for error reporting

    $log->trace("Using the default configure method!");


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

        $log->trace("Command: Regex   :" . $cmd->{regex});
        $log->trace("Command: Cmd     :" . $cmd->{cmd});
        $log->trace("Command: Timeout :" . $cmd->{timeout});
        $log->trace("Command: Required:" . $cmd->{required});

        VARIABLE_INTERPOLATION:
        {
            my $old_cmd = $cmd->{cmd};
            my $new_cmd = $old_cmd;
            # matches $variable_name; not \$variable_name
            # "-" counts as a word boundry, which is good for things like "range $a-$b"
            FIND_VARIABLE:
            while ($old_cmd =~ /[^\\]\$(\w+)/g)
            {
                my $replacement = $self->get($1);
                if (defined $replacement)
                {
                    $log->trace("Replacing '$1' with '$replacement' for cmd "
                                . "'$old_cmd' for device " . $self->hostname);
                    $new_cmd =~ s/\$$1/$replacement/;
                }
                else
                {
                    if ($cmd->{required})
                    {
                        my $message = "'$1' not defined for required command "
                                      . "'$old_cmd' for " . $self->hostname;
                        $self->error_end_session($message);
                        return "Command failed.";
                    }
                    else
                    {
                        $log->info("Skipping... ". "'$1' not defined for optinal command "
                                    . "'$old_cmd' for " . $self->hostname);
                        next COMMAND;
                    }
                }
            }
            # Since we escape the $s, remove the
            # escape characters.
            $new_cmd =~ s/\\\$/\$/g;
            if (not $new_cmd eq $old_cmd)
            {
                $cmd->{cmd} = $new_cmd;
            }

            #Re-insert command characters
            # i.e. tabs and newlines
            $cmd->{cmd} =~ s/\\t/\t/g;
            $cmd->{cmd} =~ s/\\n/\n/g;
            $log->trace("\$cmd->{cmd} after replacing tabs and newlines '"
                        . $cmd->{cmd} . "'");
        }


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
                        $session->send($cmd->{cmd} . "\n");
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

        $last_cmd = $cmd->{cmd};

        if ($command_failed)
        {
            # close session and alarm
            $self->error_end_session("Required command failed for " . $self->hostname);
            $log->debug(Dumper(%$cmd));
            return "Command failed.";
        }
        sleep(1);
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

########################################
# lookup_model
# public method
#
# Try to match the vendor and model device parameters against
# a lookup tableto see if the model and vendor can be discerned.
#
# See the defined constants at the beginning of the module for
# the definitions.
#
# Return the object name for the device.
########################################
sub lookup_model {
    my $self    = shift;
    my $class   = ref($self);
    my $log     = Log::Log4perl->get_logger($class);

    my $model   = $self->model   || '';
    my $vendor  = $self->vendor  || '';;
    my $models  = GENERIC_DEVICE_MODEL_REGEX;
    my $snmp_community = $self->snmp_community   || '';
    my $snmp_device_type;  # holds the output from the snmp query
    my $device_model;
    my $device_vendor;

    if ( $self->hostname)
    {
        $log->debug($self->hostname . "Looking up device info (model/vendor).");
    }

    $self->identify_vendor;
    $self->identify_model;

    if ( $self->vendor )
    {
        $class = join('::', $class, $self->vendor );
        $log->debug($self->hostname . "Found device model: $class");
    }
    else
    {
        $log->debug($self->hostname
                    . "Unable to determine device model.  Using $class.");
    }

    return $class;
}

########################################
# identify_vendor
# public method
#
# Lookup the device vendor.  Use (in order)
# one of the following methods.  Sets the
# vendor attribute of the device
#
# configured in device file
# snmp (sysDescr.0)
# console (show ver...doesn't always work)
#
# Returns:
#   success => undef
#   failure => error message
########################################
sub identify_vendor {
    my $self    = shift;
    my $log     = Log::Log4perl->get_logger( ref($self) );
    my $info;   # String to look at to determine the vendor
    my $vendor; # the name of the device vendor

    if ($self->vendor)
    {
        $log->debug($self->hostname . "Vendor already defined.");
        $vendor = _get_vendor_from_string( $self->vendor );
        if ( not ($self->vendor eq $vendor) )
        {
            $self->vendor($vendor);
            $log->trace("Defined vendor incorrect.  Correcting...");
        }
        return;
    }
    elsif ($self->session and $self->provision)
    {
        $log->debug($self->hostname . " - Using terminal to determine vendor.");
        $info = $self->console_get_description;
    }
    elsif ($self->snmp_community)
    {
        $info = $self->snmp_get_description;
        $log->debug($self->hostname . "Using snmp to determine vendor.");
    }
    else
    {
        $log->info($self->hostname . "Unable to determine the vendor");
        return "Unable to determine the vendor.";
    }

    $info and $log->trace("Found snmp or console info: $info");

    $vendor = _get_vendor_from_string($info);

    if ($vendor)
    {
        $self->vendor($vendor);
    }

    return $info ? undef : "Unable to determine vendor.";
}

########################################
# identify_model
# public method
#
# Lookup the device model.  Use (in order)
# one of the following methods.  Sets the
# model attribute of the device
#
# configured in device file
# snmp (sysDescr.0)
# console (show ver...doesn't always work)
#
# Returns:
#   success => undef
#   failure => error message
########################################
sub identify_model {
    my $self    = shift;
    my $log     = Log::Log4perl->get_logger( ref($self) );
    my $info;   # String to look at to determine the model
    my $model;  # the device model

    if ($self->model)
    {
        $log->debug("Model already defined for " . $self->hostname);
        return;
    }
    elsif ($self->session and $self->provision)
    {
        $log->debug($self->hostname . " - Using terminal to determine model");
        $info = $self->console_get_description;
    }
    elsif ($self->snmp_community)
    {
        $info = $self->snmp_get_description;
        $log->debug($self->hostname . " - Using snmp to determine model");
    }
    else
    {
        $log->info("Unable to determine the model for " . $self->hostname);
    }

    $model = &_get_model_from_string($info);

    if ($model)
    {
        $self->model( $model );
    }

    return $model ? undef : "Unable to determine device model";
}

########################################
# snmp_get_description
# public method
#
# Get the sysDescr.0 from the device
#
# Returns:
#   success =>  the sysDescr.0 string
#   failure =>  undef
########################################
sub snmp_get_description {
    my $self         = shift;
    my $log          = Log::Log4perl->get_logger( ref($self) );
    my $snmp;        # snmp session
    my $snmp_error;  # the error from a snmp session
    my $snmp_vendor; # output from the snmp get request
    my $snmp_oid;    # oid of the attribute to get
    my $snmp_result; # the result of the snmp query

    if ($self->provision)
    {
        $log->debug($self->hostname . " Ignored - Not using snmp to determine"
                . " device type.");
        return undef;
    }

    $log->debug("Using snmp to determine the vendor.");
    ($snmp, $snmp_error) = Net::SNMP->session(
                        -hostname   =>  $self->hostname,
                        -version    =>  $self->snmp_version,
                        -community  =>  $self->snmp_community,
                    );
    if (not $snmp)
    {
        $log->warn($self->hostname . " - Error determining vendor using snmp.");
        return undef;
    }

    # sysDescr.0
    $snmp_oid = '.1.3.6.1.2.1.1.1.0';

    eval
    {
        $snmp_result = $snmp->get_request(
                             -varbindlist    =>  [ $snmp_oid ],
                             );
    };
    if ($@)
    {
        $log->warn($self->hostname . " - Error getting snmp info - $@.");
        undef $snmp_result;
    }

    if ($snmp_result)
    {
        $log->debug("snmp sysDescr.0 for " . $self->hostname . " was "
                    . $snmp_result->{$snmp_oid});
    }
    else
    {
        $log->warn("Unable to get the sysDescr via SNMP from "
                    . $self->hostname . " using community " . $self->community
                    . " with version " . $self->snmp_version);
    }

    return $snmp_result ? $snmp_result->{$snmp_oid} : undef;
}

########################################
# console_get_description
# public method
#
# Get the output from "show version"
# 
# Returns:
#   success =>  the result from "show version"
#   failure =>  undef
########################################
sub console_get_description {
    my $self = shift;
    my $log  = Log::Log4perl->get_logger( ref($self) );
    my $session = $self->session;
    my $command_failed;     # a flag to indicate success or failure of the command.
    my $result;             # the output from the show version command
    my $processed_result;   # massage the data to return meaningful data

    $log->debug("Using the CLI to determine the device model.");

    if ($session)
    {
        if (not $self->admin_status)
        {
            $self->get_admin_rights;
        }


        # XXX
        # I know hp will fail if you try to "show ver" and not admin.
        # However, cisco will work.  Maybe we should try it anyway...
        if ($self->admin_status)
        {
            $session->expect(MEDIUM_TIMEOUT, eval $expect_show_version_cmd
                                           , eval $expect_timeout_cmd);
            $session->expect(MEDIUM_TIMEOUT, eval $expect_get_priv_console_output
                                           , eval $expect_timeout_cmd);
            if ($command_failed)
            {
                $log->warn($self->hostname . " - Failed"
                            . " - Unable to show version via cli.");
            }
            $result = $session->before();
            $log->debug($self->hostname 
                        . " - Got console description - '$result'");
        }
        else
        {
            $log->warn($self->hostname . " - Failed"
                            . " - Unable to show version via cli");
        }
    }

#    if ($result =~ /[iI]mage\s*stamp/)
#    {
#        $processed_result = "HP";
#    }
#    elsif ($result =~ /cisco/i)
#    {
#        $processed_result = "Cisco";
#    }
#    else
#    {
#        $processed_result = "";
#    }

#    return $processed_result;
    return $result;
}


########################################
# get_admin_rights
# public method
#
# Tries to gain administrative privileges
# on the device.  Should work with both
# cisco and hp.
#
# Returns:
#   success = undef
#   failure = reason for failure (aka a true value)
########################################
sub get_admin_rights {
    my $self     = shift;
    my $session  = $self->session;
    my $password = $self->enable_password;
    my $log      = Log::Log4perl->get_logger( ref($self) );
    local $command_failed;       # indicates of the command failed.
    local $connected_to_device;  # Added so eval statements don't generate errors
    my @expect_commands;      # the commands to run on the device

    $log->debug("Using default get_admin_rights method.");

    # Do some sanity checking
    if (not $self->session)
    {
        $log->warn("No session defined for get admin rights.");
        return "No session defined for get admin rights.";
    }

    if ($self->admin_status)
    {
        $log->debug("Already have admin rights.");
        return;
    }

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
                            _eval($expect_enable_cmd, $self),
#                            eval $expect_already_enabled_cmd,
                            _eval($expect_priv_mode_cmd, $self),
                    ]);
    push(@expect_commands, [
                            _eval($expect_enable_passwd_cmd, $self),
                            _eval($expect_priv_mode_cmd, $self),
                    ]);
    push(@expect_commands, [
                            _eval($expect_priv_mode_cmd, $self),
                    ]);

    foreach my $command (@expect_commands)
    {
        $self->session->expect(MEDIUM_TIMEOUT, @$command, _eval($expect_timeout_cmd, $self));
        if ($log->level == $TRACE)
        {
            $log->trace("Expect matching before: " . $session->before);
            $log->trace("Expect matching match : " . $session->match);
            $log->trace("Expect matching after : " . $session->after);
        }
        if ($command_failed) {
            $log->warn("Command failed.");
            $log->debug("Failed command(s): " . @$command);
            $self->admin_status(FALSE);
            return "Enable command failed.";
        }
        elsif ($self->admin_status)
        {
            $log->info($self->hostname
                        . " - Administrative privileges granted");
            last;
        }
    }

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
    my $log           = Log::Log4perl->get_logger( ref($self) );
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

#    $session->send("\n");

    $log->debug("Paging disabled.");

    return;
}

########################################
# end_session
# public method
#
# If the device has a valid session,
# end it.
#
# Returns undef
########################################
sub end_session {
    my $self = shift;
    my $log  = Log::Log4perl->get_logger( ref($self) );

    if ($self->session)
    {
        $log->info($self->hostname . " - Terminating session");
        $self->session->soft_close();
        $self->session(FALSE);
    }
    else
    {
        $log->info($self->hostname . " - No session to terminate");
    }
    return;
}

########################################
# error_end_session
# public method
#
# Terminate a session due to an error.
# Mainly it has different logging options
# than the normal end_session method
#
# Takes:
#   A string to output to the log.
#
# Returns undef
########################################
sub error_end_session {
    my $self = shift;
    my $message = shift;
    my $log  = Log::Log4perl->get_logger("Net::Autoconfig");

    if (defined $message)
    {
        $log->warn($self->hostname, " - $message");
    }

    if ($self->session)
    {
        $log->warn($self->hostname . " - Terminating session");
        $self->session->soft_close();
        $self->session(FALSE);
    }
    else
    {
        $log->info($self->hostname . " - No session to terminate");
    }
    return;
}

########################################
# replace_command_variables
# public method
#
# Replaces variables in comands
#
# Expects:
# a command hash ref
#
# Returns
# Success   = sets the cmd->{cmd} value
#             returns undef
# Failure   = returns an error message
########################################
sub replace_command_variables {
    my $self    = shift;
    my $log     = Log::Log4perl->get_logger( ref($self) );
    my $cmd     = shift; # The command hash
    my $old_cmd;         # The command with variables that need replacing
    my $new_cmd;         # new string with variables replaced

    if ( not $cmd )
    {
        $log->warn($self->hostname . " - no command hash reference passed.");
        return "No comand hash reference passed.";
    }
    elsif ( not ref($cmd) eq 'HASH' )
    {
        $log->warn($self->hostnaem . " - command passed, but it was not a hash reference.");
        return "Command passed, but it was not a hash reference.";
    }

    $old_cmd = $cmd->{cmd};

    # Do some sanity checking
    if ( not $old_cmd )
    {
        $log->info($self->hostname . " - no command specified.  Using \"\".");
        $old_cmd = "";
        $new_cmd = $old_cmd;
    }
    $new_cmd = $old_cmd;

    # matches $variable_name; not \$variable_name
    # "-" counts as a word boundry, which is good for things like "range $a-$b"
    FIND_VARIABLE:
    while ($old_cmd =~ /[^\\]\$(\w+)/g)
    {
        my $replacement = $self->get($1);
        if (defined $replacement)
        {
            $log->trace($self->hostname . "Replacing '$1' with '$replacement'"
                        . " for cmd '$old_cmd'");
            $new_cmd =~ s/\$$1/$replacement/;
        }
        else
        {
            if ( $cmd->{required} )
            {
                my $message = $self->hostname . " - '$1' not defined"
                              . " for required command '$old_cmd'";
                $log->warn( $message );
                return $message;
            }
            else
            {
                $log->info($self->hostname . " - '$1' not defined for"
                            . " optinal command '$old_cmd'");
            }
        }
    }

    # Since we escape the $s, remove the
    # escape characters.
    $new_cmd =~ s/\\\$/\$/g;
    if (not $new_cmd eq $old_cmd)
    {
        $cmd->{cmd} = $new_cmd;
    }

    #Re-insert command characters
    # i.e. tabs and newlines
    if ( $cmd->{cmd} )
    {
        $cmd->{cmd} =~ s/\\t/\t/g;
        $cmd->{cmd} =~ s/\\n/\n/g;
        $log->trace($self->hostname . " - \$cmd->{cmd} after replacing"
                    . " tabs and newlines = '" . $cmd->{cmd} . "'");
    }
    return undef;
}


############################################################
# Private Methods
############################################################

########################################
# _connected
# private method
#
# Accessor
#   Returns the connection status (TRUE/FALSE)
#
# Mutator
#   Sets the connection status to TRUE or FALSE
#   any perl "true" value => TRUE
#   any perl "false" value => FALSE
#   Returns undef
########################################
sub _connected {
    my $self   = shift;
    my $status = shift;
    my $log    = Log::Log4perl->get_logger( ref($self) );

    if ( defined $status )
    {
        if ( $status )
        {
            $self->set('connected', TRUE);
            $log->trace($self->hostname . " - Setting connected status to TRUE");
        }
        else
        {
            $self->set('connected', FALSE);
            $log->trace($self->hostname . " - Setting connected status to FALSE");
        }
    }

    return defined $status ? undef : $self->{'connected'};
}

########################################
# _host_not_reachable
# private function
#
# Ping the specified hostname / ip address.
# 
# Returns
#   success = FALSE
#   failure = TRUE
########################################
sub _host_not_reachable {
    my $hostname = shift;
    my $log      = Log::Log4perl->get_logger(__PACKAGE__);
    my $ping;    # Ping object

    if (not $hostname)
    {
        $log->warn("No hostname defined.");
        return TRUE;
    }

    $ping = eval { Net::Ping->new( $> ? "tcp" : "icmp" ) };
    if ($@)
    {
        $log->error("Net::Ping Failed - $@");
        $log->error("Connection to '$hostname' failed.");
        return TRUE;
    }

    # If using a console server, extract the console server
    # hostname so ping doesn't fail.
    if ($hostname =~ /.*\@(.*)/) {
        $hostname = $1;
    }
        
    if ($ping->ping($hostname))
    {
        $log->debug("'$hostname' is reachable via ping.");
        return FALSE;
    }
    else
    {
        $log->warn("Ping failed - '$hostname' not reachable via ping.");
        return TRUE;
    }
}



########################################
# _get_vendor_from_string
# private function
#
# Given a string, search through it
# to determine the manufacturer of the
# device.  The output of "show version"
#
# Example:
#   
#   $show_ver = "Cisco Systems, C3560E 12.2(46)SE...."
#   $vendor = _get_model_from_string($show_ver)
#
# Returns:
#   success - The name of the vendor
#   failure - undef
########################################
sub _get_vendor_from_string {
    my $string         = shift;
    my $vendors        = VENDORS_REGEX;      # a hash ref of regex => vendors
    my $device_model;  # a string that links to the module for that device type
    my $log            = Log::Log4perl->get_logger(__PACKAGE__);

    (defined $string) or $string = "";

    foreach my $regex (keys %$vendors)
    {
        my $vendor = $vendors->{$regex};
        if ($string =~ /$regex/)
        {
            $log->trace("Vendor matched: $regex => $vendor");
            $device_model = $vendor;
            last;
        }
    }

    if ($device_model)
    {
        $log->debug("Got vendor: $device_model");
    }
    else
    {
        $log->debug("Failed to get vendor.");
    }

    return $device_model ? $device_model : undef;
}

########################################
# _get_model_from_string
# private function
#
# Given a string, search through it
# to determine the model of the
# device.  Can be the output from show
# version (cisco devices), or snmp (sysDescr.0)
#
# Example:
#   
#   $show_ver = "Cisco Systems, C3560E 12.2(46)SE...."
#   $vendor = _get_model_from_string($show_ver)
#
# The returned array or array ref contains
# all of the different model types that
# this devices matches.  This makes it so
# you can specify all switches, or hp2600
# or hp2626 in the template file and it will
# use the right template.
#
# Returns:
#   success
#       Scalar context = array ref
#       Array context  = array
#   failure - undef
########################################
sub _get_model_from_string {
    my $string          = shift;
    my $specific_models = SPECIFIC_DEVICE_MODEL_REGEX;
    my $generic_models  = GENERIC_DEVICE_MODEL_REGEX;
    my $all_types       = ALL_TYPES_MODEL_HASH;
    my $models          = []; # The array ref of models this device matches
    my $log             = Log::Log4perl->get_logger(__PACKAGE__);

    if (not $string)
    {
        $log->debug("No or false string passed.");
        return undef;
    }

    SPECIFIC_MODEL:
    foreach my $model (keys %$specific_models)
    {
        my $regex = $specific_models->{$model};
        if ( $string =~ qr($regex) )
        {
            $log->debug("Found specifc model: $model");
            push(@$models, $model);
            last SPECIFIC_MODEL;
        }
    }

    GENERIC_MODEL:
    foreach my $model (keys %$generic_models)
    {
        my $regex = $generic_models->{$model};
        if ( $string =~ qr($regex) )
        {
            $log->debug("Found generic model: $model");
            push(@$models, $model);
            last GENERIC_MODEL;
        }
    }

    # Sanity checking
    if (not @$models)
    {
        $log->debug("Unable to determine model for '$string'");
        return undef;
    }

    # Look for the most generic model type
    # It should be the last one on the list
    if ( $all_types->{ $models->[-1] } )
    {
        my $type = $all_types->{ $models->[-1] };
        $log->debug("Found generic model: $type");
        push( @$models, $type );
    }
    return wantarray ? @$models : $models;
}

########################################
# _invalid_session
# private function
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
    my $log     = Log::Log4perl->get_logger(__PACKAGE__);

    if (not defined $session)
    {
        $log->debug("Invalid Session - FAILURE - Session not defined");
        return TRUE;
    }
    
    if (not ref($session))
    {
        $log->debug("Invalid Session - FAILURE - Session not a reference");
        return TRUE;
    }
    
    if (not ref($session) eq 'Expect')
    {
        $log->debug("Invalid Session - FAILURE - Session not an Expect.pm reference");
        return TRUE;
    }
    else
    {
        $log->debug("Invalid Session - SUCCESS - Valid Session");
        return;
    }
}

########################################
# _eval
# private method
#
# This is used to evaluate strings/expressions at run-time
# and report any errors.  Mainly  used for eval'ing
# expect commands.
#
# Call eval and return the result.
# Log any eval errors.
# Assumes the result will be scalar, i.e. a 
# reference or a string.
########################################
sub _eval {
    my $string = shift;
    my $self   = shift;
    my $log    =  Log::Log4perl->get_logger(__PACKAGE__);
    my $session;

    $log->trace("EVAL - String = '$string'");

    if ($self)
    {
        $session = $self->session;
        if (not $session)
        {
            $log->warn($self->hostname . " - EVAL - ERROR - Session not defined.");
            return;
        }
    }
    else
    {
        undef $self;
        undef $session;
        $log->debug("EVAL - ERROR - \$self not defined");
        $log->debug("EVAL - ERROR - \$session not defined.");
    }

    my $result = eval $string;

    if ($@)
    {
        $log->error("EVAL - ERROR - $@");
        return;
    }
    else
    {
        $log->debug("EVAL - SUCCESS");
    }

    return $result;
}




########################################
# _is_ip_addr
# private method
#
# Test to see if a string is an ip address.
# Returns:
#   True if it is (or looks like it is)
#   False if it is not.
########################################
sub _is_ip_addr {
    my $ip_addr = shift;

    $ip_addr or return FALSE;

    if ($ip_addr =~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/)
    {
        # It slooks like it's valid, let's check and see
        foreach my $octet ($1, $2, $3, $4)
        {
            ($octet > 255) and return FALSE;
            ($octet < 0) and return FALSE;
        }
    }
    else
    {
        return FALSE;
    }

    return TRUE;
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
    return
        wantarray ? @netmask : join(".", @netmask);
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

  %data = (
            hostname => dev1,
            username => user1,
            password => pass1,
            enable_password => enable1,
            snmp_community  => public1,
            snmp_version    => 2c,
          );
  $device = Net::Autoconfig::Device->new(%data);
  $device = Net::Autoconfig::Device->new();

  $device->hostname("device1");
  $device->set('fu' => 'bar');
  $device->set(%data);

  $hostname = $device->hostname
  $hostname = $device->get("hostname");

  %all_device_data = $device->get;

  There are a lot of built-in access/mutator methods.  Beyond
  those values, you can add whatever you want to the
  device object.

=head1 DESCRIPTION

Net::Autoconfig uses the concept of devices.  Each device
contains all relevent information internally.  By default,
the device type/model/vendor is discovered automatically.
If there is a specific module for that paticular vendor/model,
then that module will be used.  If not, then it will use the
default methods contained in this module.

=head1 Methods

=head2 Public Methods

=over

=item new()

Creates a new Net::Autoconfig::Device object.
Additional info can be configured after the object has been created.
Pass an array with ( key1 => value1, key2 => value2, ...) to initialize
the object with those key values.

 Default values:
 auto_discover      = TRUE
 snmp_version       = 2c
 access_method      = ssh
 access_cmd         = /usr/bin/ssh
 invalid_cmd_regex  = '[iI]nvalid command'

=item autodiscover()

Enabled by default.  Can be disabled by setting
C<'auto_discover' = FALSE> (0, "", etc)

Try to discover the vendor and model number of the device.
It uses the following (in order) to determine the device type:
 1. if vendor and model are specified in the device config file
 2. if a snmp community is specified, it will use that (preferred method)
 3. if a session is open to the device, use the CLI (intermittent)

=item get()

Get the value of the specified attribute, or get a hash ref of all of
the attribute => value pairings.  This provides a mechanism for getting
attributes that are either part of the module, or that you have defined.
Returns undef if an attribute does not exist.

=item set()

Set the value of an attribute.  If the attribute does not
yet exist, create it.

This method is used by passing an array to the method.  The
method then adds/overwrites existing key => value pairs
to the object.  You can create or modify any variable inside
the object using this method.

Returns undef for success
Returns TRUE for failure

=item I<accessor/mututaor methods>

If any of these methods are passed C<undef>, then the value
for that variable is returned.  If passed anything that is not
undef, then set the device variable to that.  Some of these
methods do some sanity checking, other allow you to set the
values to whatever you want.

=over

=item model()

The device class in perl module format.

E.g. A cisco device would have "Net::Autoconfig::Device::Cisco"

=item vendor()

The vendor name.

E.g. A hp device would have "HP".  A Cisco device would have "Cisco".

=item hostname()

The hostname of the device.

=item username()

The username to access the device.

=item password()

The password used to access the device.

=item provision()

Whether this device is to be configured via
a console server.

=item admin_status()

TRUE means that admin priviledges have been obtained on the device.

FALSE means that admin priviledges have B<not> been obtained.

=item enable_password()

The password to obtain administrative priviledges on the device.

=item console_username()

The username to connect to the console server.  This is only
to gain access to the console server, not the device attached
to it.  You're welcome to make them the same, but they don't
have to be.  If not specified, it will use the device username.

=item console_password()

The password to connect to the console server.  This is used
in conjuction with console_username to gain access to the
console server.  If not specified, it will use the device password.

=item console_hostname()

The hostname of the console server.  This is
different than the hostname.  The hostname can
be tty5@console1.  console_hostname would be "console1"

=item console_tty()

The tty/interface on the console that the device
connects to.  If the hostname were tty5@console1,
The console_tty would be "tty5".

=item snmp_community()

The snmp version 2 community string.

=item snmp_version()

The snmp version to use.  Currently only supports version 2.

=item session()

Returns a reference to the current session.

=item access_method()

How are we going to connect to the device.

E.g. ssh

=item access_cmd()

What command are we going to use to connect to
the device.

E.g. /usr/bin/ssh

=back

=item disable_paging()

Attempts to disable the pagination of command output.  I.e.
having to hit the spacebar to see the next chunk of the output.
Script don't interact will with paginated data.  This method
tries a compromise, it will not work as well as an overloaded
method in a sub-class.

=item end_session()

Terminates the session.

=item error_end_session($error_message);

Terminates the session and gives an error message that
you specify.

=item lookup_model()

This trys to determine the vendor and  model of the device.  This
is usually called from C<auto_discover()>.  B<If auto_discover is not false,
then this will cause a loop.>

Returns the vendor specific module, or "Net::Autoconfig::Device"
if nothing more specific is found.

=item identify_vendor()

This method actually calls does the heavy lifting of determining the
device type.  It sets the vendor variable of the device.

Returns:
 Success = undef
 Failure = error message

=item identify_model()

This method actually calls does the heavy lifting of determining the
device model(s).  It sets the device model to an array ref containing
all device models that this device matches.  The list goes from
most specific to least specific.

Example:
 [ 'hp2626' 'hp2600' 'hp_switch' ]

Returns:
 Success = undef
 Failure = error message

=item snmp_get_description()

Uses SNMP to get the sysDescr from the device.

Returns:
 success = the output/string from the system description
 failure = undef

=item console_get_description()

Uses the cli (if a session exists) to get some information
about the device.  It parses the data and returns something
useful that the C<identify_vendor> and C<identify_model> methods
can use.

Returns:
 success = a string that can identify the device
 failure = undef

=item connect()

Will try to connect to a device using default methods. This method
should be overloaded by a sub class.  It tries to take into account
the idiosyncrasies of both HP and Cisco switches, but it could fail.

=item console_connect()

Will try to connect to a console server.  Assumes the  hostname is
in the following format:

 terminal_line@console_server_hostname

This procedure works for Avocent Cyclades console servers.
This will connect to the console server using (ssh or telnet):

 ssh -l username:termineal_line console_server_hostname

You should call C<connect()> after using this method.

=item get_admin_rights()

This method tries to gain administrative rights on the device.
(aka enable mode).  It works for both Cisco and HP devices,
but the overridden methods in the sub-classes have a higher
percentage chance of working.

=item configure()

Given a configruration in a template file, execute the
commands on the CLI using Expect.  Using the given command
template, configure the device.

 $template = Net::Autoconfig::Template->new("filename");
 $device->configure( $template->{$device->model} );
 $device->configure( $template->{$device->hostname} );

It will notify you (via the logs) if a specific command
failed to execute correctly.  If a command does not
execute correctly, it disconnects from that device.
If an optional command fails, it notifys you, but continues
execute commands on the device.

Returns:
 success = undef
 failure = TRUE

=item access_method()

If ssh or telnet are passed, then it sets the method to
C<ssh> or C<telnet>.  If anything else is passed, it
sets the method to C<user_defined>.

=item access_cmd()

Checks to see if the passed value is ssh, telnet or
something else that has an absolute path.  If ssh
or telnet are passed, the default locations for these
are used, C</usr/bin/ssh> or C</usr/bin/telnet>.
If the absolute file path is specified, use that instead.

This will also set the access method to ssh, telnet or
user defined.  If a non-standard ssh or telent location
is specified, it will still set the method to ssh or
telnet.  If it is something else, then it will set the
method to user defined.

=back

=head1 Device File Format (Colon Format)

The file format used for describing objects was created by
me, with commentary and input of Stephen Fromm, to be easy
to type and readable.  All "commands" are sandwitched between
colons, ":", hense the name, "colon format".

Devices or default devices begin with "default" or the
name of the device.  The device ends with a C<:end:> statement.
There must be an C<:end:> statement per device/default definition.
Any subsequent device or default statement overrides the previous
one.  I.e. you can start with one default statement, define
some devices, define a new default, and then define some more
devices.  You can manually set the hostname C<hostname = blah>
or it will take the part between the colons and use that as
the hostname.  You decide.

Whitespace is irrelavent if it comes at the beginning or end
of a line.  I.e. if you want to use tabs to make the definitions
look pretty, go ahead.  If you want to line-up the "=" signs,
go ahead.

Example:
 :default:
   netmask            = 255.255.255.0
   username           = some_user
   password           = some_password
   enable_password    = secret_password
   snmp_community     = public
   access_vlan        = 10
   voice_vlan         = 20
   mgmt_vlan          = 30
 :end:

 :cisco_switch_1:
 :end:

 :cisco_switch_1:
 model = c2960
 :end:

 :hp_switch_1:
 some_crazy_variable = some_crazy_value
 :end:

=head1 SEE ALSO

    Net::Autoconfig

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

