package Nagios::Plugin::SNMP;

=pod

=head1 NAME

Nagios::Plugin::SNMP - Helper module to make writing SNMP-based plugins for Nagios easier.

=head1 SYNOPSIS

 This module requires Net::SNMP for its' SNMP functionality; it 
 subclasses Nagios::Plugin.

 It includes routines to do the following:

=head2 Parse and process common SNMP arguments:

 * --warning|-w: Warning threshold [optional]
 * --critical|-c: Warning threshold  [optional]
 * --hostname|-H: SNMP device to query
 * --alt-host|--ah: Additional SNMP devices to query
 * --port|-p: Port on remote device to connect to [default 161]
 * --snmp-local-ip: Local IP to bind to for outgoing requests
 * --snmp-version: SNMP version (1, 2c, 3)
 * --snmp-timeout: Connect timeout in seconds [default 0]
 * --snmp-debug: Turn on Net::SNMP debugging
 * --snmp-max-msg-size N: Set maximum SNMP message size in bytes
 * --rocommunity: Read-only community string for SNMP 1/v2c
 * --auth-username: Auth username for SNMP v3
 * --auth-password: Auth password for SNMP v3
 * --auth-protocol: Auth protocol for SNMP v3 (defaults to md5)
 * Connect to an SNMP device
 * Perform a get() or walk() request, each method does 'the right
   thing' based on the version of SNMP selected by the user.

=head2 noSuchObject and noSuchInstance behavior

You can configure your plugin to automatically exit with UNKNOWN if
OIDs you query for on the remote agent do not exist on the agent by
setting 'error_on_no_such' to 1 in new().  If you set it to 0 or
do not specify the option at all, then results from get() and walk()
will have the string tokens noSuchObject or noSuchInstance as values
for OIDs that the agent does not support.

This option exists as some scripts will query agents for MIBs that have
*some* tables or scalars that may or may not be supported depending on the
remote agent version, operating system, etc.  In this case
it is nice to just parse the returns from get() and walk() to programatically
determine if support exists.  

In other cases the script may be querying a
clustered application with multiple agents where only one agent will respond
with the OIDs queried; the others will return noSuch* values .. for this case
having the script exit with error if *none* of the agents return valid values
makes sense at least one agent MUST have the OIDs for the check to
succeed and all agents are known to respond to the OIDs in question
(set error_on_no_such to 1).

 my $plugin = Nagios::Plugin::SNMP->new(
     'error_on_no_such' => 1
 );

=head2 Handle deltas for counters

 my $plugin = Nagios::Plugin::SNMP->new(
     'process_deltas' => { 
         'cache' => { 'type' => 'memcache' },
         'default_interval' => 300, # seconds 
         'delta_compute_function' => \&my_delta_function
     }
 );

 Will use any Cache::Cache compliant data cache to store counter 
 values and return deltas between counters to the end user.  In order 
 to do this, Nagios::Plugin::SNMP must be passed in a cache class name.  
 Each cache type will cause Nagios::Plugin::SNMP to add required 
 arguments for the cache type in question.  Additionally, enabling 
 counter delta code causes the script to require an interval for 
 time between checks.  From the command line this can be specified 
 with --check-interval.  The developer can pass in a default using 
 the 'default_interval' parameter.

 * cache => { 'type' => 'memcache' }

 Causes Nagios::Plugin::SNMP to use Cache::Memcached for 
 data persistence; also makes the following arguments to the plugin 
 available to the user.  Defaults for both can be provided in the 
 memcache option hash as memcache_addr and memcache_port.
 * --memcache-addr - IP address of Memcache instance
 * --memcache-port - TCP port number memcache is listening on

 my $plugin = Nagios::Plugin::SNMP->new(
     'process_deltas' => { 
         'cache' => {
             'type' => 'memcache',
             'options => { 'memcache_port' => 11211, 
                           'memcache_addr' => 127.0.0.1 
         },
         'default_interval' => 300, # seconds 
         'delta_compute_function' => \&my_delta_function
     }
 );

 Currently ONLY Cache::Memcached is supported.

 * 'process_deltas' => { 'delta_compute_function' => \&my_delta_function }

 Callback to allow user to pass in a function that will compute a
 smarter delta :).  The default function purely does the following:
 * If previous value does not exist, it stores the current value
   and returns -0
 * If previous value exists and is > 0, stores the current value and
   returns the delta between the current value and previous value
 * If delta between the two values is < 0, returns -0 as counter 
   has wrapped.

 sub my_delta_function {
     my ($self, $args) = @_;
     
     my $previous_value = $args->{'previous_value'};
     my $current_value = $args->{'current_value'};
     my $interval = $args->{'interval'};
     my $previous_run_at = $args->{'previous_run_at'};

     my ($value_to_store, $delta) = ();
    
     # Processing code

     return ($value_to_store, $delta);
 }
 
=head3 get_deltas(@oids)

Will query the agent for values associated with the SCALAR OIDs passed
in and return a hash with the results of the query; the value for each
oid will be the delta, massaged as needed by the built in delta-computation
function or your own function.

=head3 get_delta_for_value($key, $value);

Will perform delta computation on the passed in value; using 
the key passed in in place of the OID that would be used in 
get_deltas as the hash key.  This routine can be used by the end 
user for metrics that are created by the plugin developer as opposed to 
counters retrieved by the SNMP agent.

=head2 Other methods 

=cut

use strict;

require Exporter;
use base qw(Exporter Nagios::Plugin);

use Net::SNMP;

#  Have to copy, inheritence doesn't work for these
use constant OK         => 0;
use constant WARNING    => 1;
use constant CRITICAL   => 2;
use constant UNKNOWN    => 3;
use constant DEPENDENT  => 4;

our @EXPORT = qw(OK WARNING CRITICAL UNKNOWN DEPENDENT);

our $VERSION = '1.2';

our $SNMP_USAGE = <<EOF;
       --hostname|-H HOST --port|-p INT --snmp-version 1|2c|3 \\
       [--snmp-timeout INT] \\
       [--snmp-local-ip IP] \\
       [--warning|-w STRING] [--critical|-c STRING] \\
       [--snmp-debug] \\
       [--snmp-max-msg-size N] \\
       [--alt-host HOST_1 ... --alt-host HOST_N] \\
       { 
           [--rocommunity S] | \\
           [--auth-username S --auth-password S [--auth-protocol S]] 
       }
EOF

our %OS_TYPES = qw(
   .1.3.6.1.4.1.8072.3.2.1   hpux
   .1.3.6.1.4.1.8072.3.2.2   sunos4
   .1.3.6.1.4.1.8072.3.2.3   solaris
   .1.3.6.1.4.1.8072.3.2.4   osf
   .1.3.6.1.4.1.8072.3.2.5   ultrix
   .1.3.6.1.4.1.8072.3.2.6   hpux10
   .1.3.6.1.4.1.8072.3.2.7   netbsd1
   .1.3.6.1.4.1.8072.3.2.8   freebsd
   .1.3.6.1.4.1.8072.3.2.9   irix
   .1.3.6.1.4.1.8072.3.2.10  linux
   .1.3.6.1.4.1.8072.3.2.11  bsdi
   .1.3.6.1.4.1.8072.3.2.12  openbsd
   .1.3.6.1.4.1.8072.3.2.13  win32
   .1.3.6.1.4.1.8072.3.2.14  hpux11
   .1.3.6.1.4.1.8072.3.2.255 unknown
);

sub new {

    my $class = shift;
    my %args = (@_);

    $args{'usage'} .= $SNMP_USAGE;

    my $process_delta_opts = undef;

    #  have to do this before SUPER call
    if (exists $args{'process_deltas'}) {
        $process_delta_opts = $args{'process_deltas'};
        $args{'usage'} .= "       --check-interval seconds\n";

        if ((exists $process_delta_opts->{'cache'}) &&
            (exists $process_delta_opts->{'cache'}->{'type'})) {

            my $ct = lc($process_delta_opts->{'cache'}->{'type'});

            if ($ct eq 'memcache') {
                $args{'usage'} .= <<EOF;
       --memcache-addr listening hostname or IP
       --memcache-port listening port
EOF
            }

        }
        delete $args{'process_deltas'};
    }

    #  For multiple host checks, developer might want script to
    #  exit with error if OID does not exist on any host checked;
    #  this will cause a check for noSuchObject and noSuchInstance
    #  to happen for every result returned by the remote agent ..
    #  with this set to 1 the agent will exit with error if noSuch*
    #  errors are found in result sets for all hosts.

    my $die_on_no_such = 0;

    if (exists $args{'error_on_no_such'}) {
        $die_on_no_such = $args{'error_on_no_such'};
    }
    delete $args{'error_on_no_such'};

    my $self = $class->SUPER::new(%args);

    if (defined $process_delta_opts) {
        $self->_setup_delta_cache_options($process_delta_opts);
    }

    #  Add standard SNMP options to the plugin
    $self->_snmp_add_options();

    #  Hold the SNMP sessions we are using.  Multiple
    #  potential hosts can be specified using one or more
    #  --alt-host arguments in addition to the single 
    #  --hostname argument given on the command line.
    $self->{'_SNMP_SESSIONS'} = [];

    $self->{'_SNMP_DIE_ON_NO_SUCH'} = $die_on_no_such;

    #  Hold the name of the host used for polling when multiple
    #  potential hosts are specified using --hostname and
    #  one or more --alt-host options on the command line
    $self->{'_SNMP_POLLED_HOST'} = '';

    return $self;
}

sub start_timer {
    my $self = shift;

    if ( (defined $self->opts->get('timeout')) &&
         ($self->opts->get('timeout') > 0) ) {
         alarm($self->opts->get('timeout'));
    }
}

#  Add Nagios::Plugin options related to SNMP to the plugin

sub _snmp_add_options {

    my $self = shift;

    $self->add_arg(
        'spec' => 'snmp-version=s',
        'help' => '--snmp-version 1|2c|3 [default 3]',
        'required' => 1,
        'default' => '3'
    );

    $self->add_arg(
        'spec' => 'rocommunity=s',
        'help' => "--rocommunity NAME\n   Community name: SNMP 1|2c ONLY",
        'required' => 0,
        'default' => ''
    );

    $self->add_arg(
        'spec' => 'auth-username=s',
        'help' => "--auth-username USER\n   Auth username: SNMP 3 only",
        'required' => 0,
        'default' => ''
    );

    $self->add_arg(
        'spec' => 'auth-password=s',
        'help' => "--auth-password PASS\n   Auth password: SNMP 3 only",
        'required' => 0,
        'default' => ''
    );

    $self->add_arg(
        'spec' => 'auth-protocol=s',
        'help' => "--auth-protocol PROTO\n" .
                  "   Auth protocol: SNMP 3 only [default md5]",
        'required' => 0,
        'default' => 'md5'
    );

    $self->add_arg(
        'spec' => 'port|p=s',
        'help' => "--port INT\n   SNMP agent port [default 161]",
        'required' => 0,
        'default' => '161'
    );

    $self->add_arg(
        'spec' => 'hostname|H=s',
        'help' => "-H, --hostname\n   Host to check NAME|IP",
        'required' => 1
    );

    $self->add_arg(
        'spec' => 'alt-host|ah|A=s@',
        'help' => <<EOF,
-A, --ah, --alt-host NAME|IP
   Additional hosts to attempt to connect to in addition to the host given
   with the --hostname option, pass in one host per --alt-host option .  
   Use if you want to check a cluster of hosts in which only *ONE* has an 
   active agent that will respond to a query properly.  Each host will be 
   tried in turn for each get() or walk() request until either a valid 
   response is received or all hosts fail to respond or return noSuchObject 
   or noSuchInstance.  An error will only be thrown by the plugin if none 
   of the hosts passed in with --hostname and --alt-host return a valid 
   response.
EOF
        'required' => 0,
        'default'  => []
    );

    $self->add_arg(
        'spec' => 'snmp-timeout=i',
        'help' => "--snmp-timeout INT\n" .
                  "   Timeout for SNMP queries [default - none]",
        'default' => 0
    );

    $self->add_arg(
        'spec' => 'snmp-debug',
        'help' => "--snmp-debug [default off]",
        'default' => 0
    );

    $self->add_arg(
        'spec' => 'warning|w=s',
        'help' => "-w, --warning STRING [optional]",
        'required' => 0
    );

    $self->add_arg(
        'spec' => 'critical|c=s',
        'help' => "-c, --critical STRING",
        'required' => 0
    );

    $self->add_arg(
        'spec' => 'snmp-local-ip=s',
        'help' => "--snmp-local-ip IP-ADDRESS\n" .
                  "   Local IP address to send traffic on [optional]",
        'default' => ''
    );

    $self->add_arg(
        'spec' => 'snmp-max-msg-size=i',
        'help' => "--snmp-max-msg-size BYTES\n" .
                  "   Specify SNMP maximum messages size [default 1470]",
        'default' => '1470'
    );

}

=pod

=head3 _setup_delta_cache_options

This method adds arguments to the Nagios::Plugin instance based on 
the type of cache along with making --check-interval required 
as a plugin needs to know the interval between plugin calls in 
order to calculate deltas and delta variance properly.

 'process_deltas' => { 
     'cache' => {
          'type' => 'memcache',
          'options => { 'memcache_port' => 11211, 
                        'memcache_addr' => 127.0.0.1 
          },
          'default_interval' => 300, # seconds 
          'delta_compute_function' => \&my_delta_function
      }
 }

=cut

sub _setup_delta_cache_options {

    my ($self, $opts) = @_;

    if (! exists $opts->{'cache'}) {
        $self->die(q{'process_deltas' specified but required hash key}
                   . q{'cache' does not exist!});
    }

    if (! ref($opts->{'cache'}) eq 'HASH') {
        $self->die(q{'process_deltas' specified but key 'cache' does not}
                 . q{contain a hash reference of options for cache type!});
    }

    if (! exists $opts->{'cache'}->{'type'}) {
        $self->die(q{'process_deltas' specified but hash ref 'cache' does }
                 . q{not specify a cache type with key 'type'!});
    }

    # Add the --check-interval option - required for any delta checks

    my $default_check_interval = 300;

    if (exists $opts->{'default_interval'}) {
        $default_check_interval = $opts->{'default_interval'};
    }

    $self->add_arg(
        'spec' => 'check-interval=i',
        'help' =>  q{--check-interval interval between checks in seconds}
                . qq{ [default interval $default_check_interval seconds]},
        'required' => 0,
        'default' => $default_check_interval,
    );

    $self->{'_SNMP_PROCESS_DELTAS'} = {};

    #  Cache specific options

    my $cache_type = lc($opts->{'cache'}->{'type'});

    if ($cache_type eq 'memcache') {

        eval "use Cache::Memcached";

        if ($@) {
            $self->die(q{Delta caching with Memcache requested }
                    . qq{but can't use Cache::Memcached: $@});
        }

        my $default_memcache_addr = undef;
        my $addr_required = 1;
        my $addr_default = "";

        if (exists $opts->{'cache'}->{'options'}->{'memcache_addr'}) {
            $addr_required = 0;
            $default_memcache_addr = 
                $opts->{'cache'}->{'options'}->{'memcache_addr'};
            $addr_default = qq{ (default $default_memcache_addr)};
        }

        my $default_memcache_port = undef;
        my $port_required = 1;
        my $port_default = "";

        if (exists $opts->{'cache'}->{'options'}->{'memcache_port'}) {
            $port_required = 0;
            $default_memcache_port = 
                $opts->{'cache'}->{'options'}->{'memcache_port'};
            $port_default = qq{ (default $default_memcache_port)};
        }

        $self->add_arg(
            'spec'     => 'memcache-addr|ma=s',
            'required' => $addr_required,
            'help'     => "--ma, --memcache-addr\n"
                . qq( Host memcache runs on${addr_default}.  Cache is)
                .  q{ required to store deltas for counters for this script.  },
            'default' => $default_memcache_addr
        );

        if ($addr_required == 1) {
            $self->{'usage'} .= q{ --memcache-addr memcache IP or hostname};
        }

        if ($port_required == 1) {
            $self->{'usage'} .= q{ --memcache-port memcache port number}
        }

        $self->add_arg(
            'spec'     => 'memcache-port|mp=i',
            'required' => $port_required,
            'help'     => "--mp, --memcache-port\n"
                . qq( Port number memcache runs on${port_default}.  Cache is)
                .  q{ required to store deltas for counters for this script. },
            'default' => $default_memcache_port
        );

    }
    else {
        $self->die(qq{Unsupported cache type '$cache_type'});
    }

    $self->{'_SNMP_PROCESS_DELTAS'}->{'cache_type'} = $cache_type;

    if (exists $opts->{'delta_compute_function'}) {
        my $callback = $opts->{'delta_compute_function'};
        
        if (! ref($callback) eq 'CODE') {
            $self->die(q{'process_deltas' option 'delta_compute_function'}
                     . q{ is not a reference to a function!});
        }

        #  Create the callback key here, if the key does not exist
        #  we are using the built-in compute delta function.
        $self->{'_SNMP_PROCESS_DELTAS'}->{'callback'} =
            $opts->{'delta_compute_function'};
    }

}

=pod

=head3 _initialize_delta_cache() 
    
Initialize cache for processing deltas.  All validation of cache 
options is done in _setup_delta_cache_options.

=cut

sub _initialize_delta_cache {

    my $self = shift;
    
    my $opts = $self->{'_SNMP_PROCESS_DELTAS'};

    my $cache_type = $opts->{'cache_type'};

    if ($cache_type eq 'memcache') {

        my $addr = $self->opts->get('memcache-addr');
        my $port = $self->opts->get('memcache-port');

        eval <<EOF;
use Cache::Memcached;

\$self->{'_SNMP_PROCESS_DELTAS'}->{'cache'} =
    Cache::Memcached->new({'servers' => [ "${addr}:${port}" ] });
EOF

        my $error = $@;

        $self->die("Cannot instantiate memcached instance: $error")
            if $error;
    }

}

=pod

=head2 _get_cache()

Return cache instance after ensuring it exists and is valid.  Exit with
error if it is not.

=cut

sub _get_cache {

    my $self = shift;

    if (! exists $self->{'_SNMP_PROCESS_DELTAS'}) {
        $self->die("Cache requested but delta processing not requested!");
    }

    my $spd = $self->{'_SNMP_PROCESS_DELTAS'};

    if ((! exists $spd->{'cache'}) || 
        (! ref($self->{'cache'}) =~ m/^Cache::/)) {
        $self->die("Cache requested but never initialized!");
    }

    return $spd->{'cache'};
}

=pod

=head2 _get_from_cache($key)

Return the value associated with $key from the cache; if value does
not exist, returns undef.  If cache is invalid, will exit with
error.

=cut

sub _get_from_cache {
    my ($self, $key) = @_;
    my $cache = $self->_get_cache();
    my $tv_ref = $cache->get($key);
    $tv_ref = { 'timestamp' => 0, 'value' => undef } if ! defined $tv_ref;

    if ($self->opts->get('snmp-debug') == 1) {
        my $ts = 'NOT DEFINED';
        $ts = $tv_ref->{'timestamp'} if defined $tv_ref->{'timestamp'};
        my $v = 'NOT DEFINED';
        $v = $tv_ref->{'value'} if defined $tv_ref->{'value'};
        $self->debug(qq{_get_from_cache: $cache->get($key) returns }
                   . qq{timestamp:$ts value:$v});
    }
    return ( $tv_ref->{'timestamp'}, $tv_ref->{'value'} );
}

=pod

=head2 _store_in_cache($key, $value) 

Store a value in the cache using the passed in key.

=cut

sub _store_in_cache {

    my ($self, $key, $value) = @_;


    my $cache = $self->_get_cache();
    my $now = time();
    my $complex_value = { 'value' => $value, 'timestamp' => $now };
    my $result = $cache->set($key, $complex_value);

    $self->debug("_store_in_cache: set($key, $value / $now) returns $result");

    $self->die(qq{Unable to store ($key -> $value / $now) in cache, please}
             . qq{ check cache configuration parameters!}) if $result == 0;

    return $value;
}

=pod

=head2  get_cache_key_for($key)

Returns a unique key that can be used to retrieve a value from the cache;
feel free to override this with a different unique key algorithm if the
default does not suit you (by subclassing Nagios::Plugin::SNMP).  By 
default, the unique key will be made by concatenating the following 
values, separated by colons:
 * hostname of the host being checked
 * port of the host being checked
 * user provided key (in the case of get_delta_for_value) or OID of
   the scalar requested (in the case of get_deltas().

=cut

sub get_cache_key_for {

    my ($self, $key) = @_;

    my $hostname = $self->opts->get('hostname');
    my $port = (defined $self->opts->get('port')) 
                   ? $self->opts->get('port') : 0;

    my $cache_key = join(q{:}, $hostname, $port, $key);

    $self->debug("get_cache_key_for: $key -> $cache_key");

    return $cache_key;
}

=pod

=head3 _snmp_validate_opts() - Validate passed in SNMP options

This method validates that any options passed to the plugin using
this library make sense.  Rules:

=over 4

 * If SNMP is version 1 or 2c, rocommunity must be set
 * If SNMP is version 3, auth-username and auth-password must be set

=back

=cut

sub _snmp_validate_opts {

    my $self = shift;

    my $opts = $self->opts;

    if ($opts->get('snmp-version') eq '3') {

        my @errors;

        for my $p (qw(auth-username auth-password auth-protocol)) {
            push(@errors, $p) if $opts->get($p) eq '';
        }

        die "SNMP parameter validation failed.  Missing: " .
            join(', ', @errors) if scalar(@errors) > 0;

    } else {

        die "SNMP parameter validation failed. Missing rocommunity!" 
            if $opts->get('rocommunity') eq '';

    }

    if ($opts->get('snmp-local-ip') ne '') {
        my $ip = $opts->get('snmp-local-ip');
        die "SNMP local bind IP address is invalid!"
            unless $ip =~ m/^(?:[0-9]{1,3}){4}$/;
    }

    return 1;

}

=pod

=head3 connect() - Establish SNMP session

 Attempts to connect to the remote system specified in the 
 command-line arguments; will die() with an error message if the 
 session creation fails.

=cut

sub connect {
    
    my $self = shift;

    $self->_snmp_validate_opts();

    my $opts = $self->opts;

    my @args;

    my $version = $opts->get('snmp-version');

    my @hosts = ($opts->get('hostname'));

    push(@hosts, @{$opts->get('alt-host')})
        if (scalar(@{$opts->get('alt-host')}) > 0);
    
    my @sessions = ();
    my @errors = ();

    for my $host (@hosts) {
        push(@args, '-version' => $opts->get('snmp-version'));
        push(@args, '-hostname' => $host);
        push(@args, '-port' => $opts->get('port'));
        push(@args, '-timeout' => $opts->get('snmp-timeout'))
            if ($opts->get('snmp-timeout') > 0);
        push(@args, '-debug' => $opts->get('snmp-debug'));

        if ($version eq '3') {
            push(@args, '-username' => $opts->get('auth-username'));
            push(@args, '-authpassword' => $opts->get('auth-password'));
            push(@args, '-authprotocol' => $opts->get('auth-protocol'));
        } else {
            push(@args, '-community' => $opts->get('rocommunity'));
        }

        push(@args, '-localaddr' => $opts->get('snmp-local-ip'))
            if $opts->get('snmp-local-ip') ne '';

        push(@args, '-maxMsgSize' => $opts->get('snmp-max-msg-size'))
            if $opts->get('snmp-max-msg-size') ne '';

        my ($session, $error) = Net::SNMP->session(@args);

        if ($error ne '') {
            push(@errors, "$host - $error");
        }
        else {
            push(@sessions, $session);
        }

    }

    if ( (scalar(@errors) > 0) && (scalar(@errors) == scalar(@sessions)) ) {
        $self->die(qq{Net-SNMP session creation failed for all hosts: } 
                   . join(', ', @errors));
    }

    $self->{'_SNMP_SESSIONS'} = \@sessions;

    return $self;

}

=pod

=head3 get(@oids) - Perform an SNMP get request

Performs an SNMP get request on each passed in OID; returns results
as a hash reference where keys are the passed in OIDs and the values are
the values returned from the Net::SNMP get() calls.

=cut

sub get {

    my $self = shift;
    my @oids = @_;

    die "Missing OIDs to get!" unless scalar(@oids) > 0;

    $self->_snmp_ensure_is_connected();

    my @sessions = @{$self->{'_SNMP_SESSIONS'}};
    my @errors = ();

    my $results = undef;

    #  Attempt SNMP GET on each host listed .. first one that responds
    #  properly wins .. if none respond, throw an error.

SNMP_GET_AGENT:
    for my $s (@sessions) {

        #  Ensure agent actually responded .. do not throw other errors
        #  for now as invalid OIDs will throw errors and we do not want
        #  the end user to have to catch those in parent code .. easy 
        #  enough to look for the string constants that represent a
        #  missing OID condition - noSuchObject or noSuchInstance

        my $host = $s->hostname();
        $self->debug("$host - attempting get_request()");

        $results = $s->get_request('-varbindlist' => \@oids);

        if (! defined $results) {

            my $error = $s->error();

            if ($error =~ /No response from/i) {
                push(@errors, qq{$host - no response - } . join(', ', @oids)
                            . qq{ - $error});
                $self->debug("$host - get_request failed - $error");
            }
            else {

                #  If we have multiple hosts to potentially check,
                #  any error is recorded.

                if (scalar(@sessions) > 1) {
                    push(@errors, qq{$host - } . join(', ', @oids)
                                . qq{ - $error});
                    $self->debug("get_request() - $error");
                }
            }

        }
        else {

            $self->{'_SNMP_POLLED_HOST'} = $host;
            $self->debug("$host - get_request succeeded!");

            if ($self->{'_SNMP_DIE_ON_NO_SUCH'} == 1) {
                my $nosuch = _ensure_defined_results($host, $results);
                if (defined $nosuch) {
                    push(@errors, $nosuch);
                    $self->debug(
                           "$host - get_request returned noSuch* errors");
                    #  Skip to next agent as we found an unsupported OID
                    next SNMP_GET_AGENT;
                }
            }

            last SNMP_GET_AGENT;

        }

    }

    if ( (scalar(@errors) > 0) && (scalar(@errors) == scalar(@sessions)) ) {
        $self->nagios_exit(UNKNOWN, q{Net::SNMP get_request() failed: } 
                                    . join(', ', @errors));
    }

    return $results;

}

=pod

=head3 walk(@baseoids) - Perform an SNMP walk request

 Performs an SNMP walk on each passed in OID; uses the Net-SNMP
 get_table() method for each base OID to ensure that the method will
 work regardless of SNMP version in use.  Returns results as
 a hash reference where keys are the passed in base OIDs and the values are
 references to the results of the Net::SNMP get_table calls.

=cut

sub walk {

    my $self = shift;
    my @baseoids = @_;

    $self->_snmp_ensure_is_connected();

    my @sessions = @{$self->{'_SNMP_SESSIONS'}};

    my %results;
    my @errors = ();

    #  Attempt a walk on all sessions; first successful walk wins,
    #  throw an error if all sessions fail.

SNMP_AGENT:
    for my $s (@sessions) {

        my $successes = 0;

        my $host = $s->hostname();
        $self->debug("$host - attempting get_table()");

GET_TABLE:
        for my $baseoid (@baseoids) {

            #  Ensure agent actually responded .. do not throw other errors
            #  for now as invalid OIDs will throw errors and we do not want
            #  the end user to have to catch those in parent code .. easy 
            #  enough to look for the string constants that represent a
            #  missing OID condition - noSuchObject or noSuchInstance

            my $result = $s->get_table($baseoid);

            if (! defined $result) {

                my $error = $s->error();

                if ($error =~ /No response from/i) {
                    push(@errors, qq{$host - $error});
                    $self->debug("get_table() - $baseoid - $error");
                    %results = ();
                }
                else {

                    #  If we have multiple hosts to potentially check,
                    #  any error is recorded.

                    use Data::Dumper;
                    $self->debug(Dumper($result));

                    if (scalar(@sessions) > 1) {
                        push(@errors, qq{$host - $baseoid - $error});
                        $self->debug("get_table() - $baseoid - $error");
                    }

                }

                next SNMP_AGENT;
            }
            else {
                $self->debug("$host - get_table() succeeded for $baseoid");

                if ($self->{'_SNMP_DIE_ON_NO_SUCH'} == 1) {
                    my $error = _ensure_defined_results($host, $result);
                    if (defined $error) {
                        push(@errors, $error);
                        $self->debug(
                               "$host - get_table returned noSuch* errors");
                        #  Skip to next agent as we found an unsupported OID
                        next SNMP_AGENT;
                    } 

                }

                $results{$baseoid} = $result;
                $successes++;

            }

        }

        if ($successes == scalar(@baseoids)) {
            $self->debug("$host - walk succeeded for all OIDs");
            last SNMP_AGENT;
        }

    }

    if ( (scalar(@errors) > 0) && (scalar(@errors) == scalar(@sessions)) ) {
        $self->nagios_exit(UNKNOWN, q{Net::SNMP get_table() failed: } 
                                    . join(', ', @errors));
    }


    return \%results;
}

sub get_deltas {
    my ($self, @oids) = @_;

    my $results = $self->get(@oids);

    for my $oid (keys %$results) {
        my $value = $results->{$oid};
        $self->debug("get_deltas(): get_value_for(value($oid, $value)");
        $results->{$oid} = $self->get_delta_for_value($oid, $value);
    }

    return $results;

}

sub get_delta_for_value {
    my ($self, $key, $current_value) = @_;

    my $cache_id = $self->get_cache_key_for($key);
    my ($previous_run_at, $cached_value) = $self->_get_from_cache($cache_id);

    my $interval = $self->opts->get('check-interval');

    my $delta_function_args = { 'previous_value'  => $cached_value,
                                'current_value'   => $current_value,
                                'interval'        => $interval,
                                'previous_run_at' => $previous_run_at,
                                'cache_id'        => $cache_id,
                                'key'             => $key };

    if ($self->opts->get('snmp-debug') == 1) {
        $self-> debug("get_delta_for_value($self, $delta_function_args");
        for my $v (keys %{ $delta_function_args }) {
            my $dv = '';
            $dv = $delta_function_args->{$v}
                      if defined $delta_function_args->{$v};
            $self->debug(qq{get_delta_for_value: $v => '$dv'});
        }
    }

    # Call delta function; could be built in, could be user-provided
    my $cdf = $self->_get_compute_delta_function();

    my ( $new_cache_value, $delta ) = &{ $cdf }($self, $delta_function_args);

    $self->debug(qq{get_delta_for_value: }
               . qq{new_cache_value:$new_cache_value delta:$delta});

    $self->_store_in_cache($cache_id, $new_cache_value);

    return $delta;

}

=pod

=head3 delta_compute_function

Default delta computation function; used if user does not provide a
delta compute function.  This function will do the following:
 * If no value was in the cache previous to this call, it will return
   -0.
 * If the current value is less than the cached value, the function will
   return -0 and treat the case as a counter wrap.
 * If neither of the above are true, the function will return the difference
   between the current and previous values and store the current value in
   the cache.

Is this overly-simplistic?  Yes :), and it is designed to be replaced by
your function that does a delta in a much more intelligent way.  

To replace this function with yours, subclass Nagios::Plugin::SNMP's 
default delta_compute_function method OR pass in a reference to a function
via  the 'process_deltas' hash passed to new(), e.g.

 my $plugin = Nagios::Plugin::SNMP->new({ 
     'delta_compute_function' => \&my_delta_function,
     ...
 });

The delta computation function you create must accept the following 
arguments:
 * Reference to plugin instance (commonly called $self within a method)
 * Hash reference with the following key value pairs:
     * previous_value:  Previous value (from the cache)
     * current_value:   Current value (from the user or the remote 
                        SNMP agent)
     * interval:        How long check interval is in seconds
     * previous_run_at: Unix timestamp representing the previous 
                        time a value was stored
     * key:             Unique sub-key associated with this data, e.g.
                        the OID for the data.

The function must return (as a 2-element list):
 * Value to store in the cache
 * Delta between the two values passed to the function

Note that this means your function can put any additional information 
in the value (and therefore cache) it would like as the function has 
total control over computing the delta between the previous and current 
values and control over what gets stored in the cache between runs of 
the plugin.

Example:

 sub my_better_function {
     my ($self, $args_ref) = @_;
     
     my $previous_value = $args->{'previous_value'};
     my $current_value = $args->{'current_value'};
     my $interval = $args->{'interval'};
     my $previous_run_at = $args->{'previous_run_at'};
     my $key = $args->{'key'};

     my ($value_to_store, $delta_value) = ();

     # ... code to compute ...

     return ($value_to_store, $delta_value);
 }

 my $plugin = Nagios::Plugin::SNMP->new(
     'shortname' => 'FOO',
     'usage'     => $usage,
     'process_deltas' => {
         'cache' => {
             'type' => 'memcache',
             ...
         }
         'delta_compute_function' => \&my_delta_function
     }
 );

=cut

sub delta_compute_function {
    my ($self, $args) = @_;

    my $previous_value = $args->{'previous_value'};
    my $current_value = $args->{'current_value'};
    my $interval = $args->{'interval'};
    my $previous_run_at = $args->{'previous_run_at'};
    my $key = $args->{'key'};

    return ($current_value, q{-0}) if ! defined $previous_value;
    return (q{-0}, q{-0}) if $current_value < $previous_value;
    return ($current_value, ($current_value - $previous_value));

}

=pod

=head2 _get_compute_delta_function()

Return user provided delta function reference if passed in or default
delta compute function.  Validation of function is done in new().

=cut

sub _get_compute_delta_function {

    my $self = shift;

    if (exists $self->{'_SNMP_PROCESS_DELTAS'}->{'callback'}) {
        $self->debug("Using custom delta compute function");
        return $self->{'_SNMP_PROCESS_DELTAS'}->{'callback'};
    }
    else {
        $self->debug("Using built-in delta compute function");
        return \&delta_compute_function;
    }

}

sub _snmp_ensure_is_connected {

    my $self = shift;

    if ( (! defined( $self->{'_SNMP_SESSIONS'}) ) ||
         ( scalar(@{$self->{'_SNMP_SESSIONS'}}) == 0 ) ) {

        $self->connect();

    }

}

sub close {

    my $self = shift;

    if (defined $self->{'_SNMP_SESSIONS'}) {

        my @sessions = @{$self->{'_SNMP_SESSIONS'}};

        for my $s (@sessions) {
            $s->close();
        }

        #  Ensure we release Net::SNMP memory
        $self->{'_SNMP_SESSIONS'} = [];

    }

    return 1;

}

#  Overloaded methods

sub getopts {

    my $self = shift;

    $self->SUPER::getopts();

    #  Now validate our options
    $self->_snmp_validate_opts();

    #  If user requested delta processing to be done ('process_deltas' hash 
    # ref passed to new()), start a cache instance.  All validation of cache 
    # options is done in new via _setup_delta_cache_options.
    $self->_initialize_delta_cache() 
        if exists $self->{'_SNMP_PROCESS_DELTAS'};

    #  Have to show this debug message here, can't do it in new() as
    #  we haven't triggered Nagios::Plugin to do option processing yet.
    if (defined $self->{'_SNMP_PROCESS_DELTAS'}) {

        my $co = $self->{'_SNMP_PROCESS_DELTAS'};

    }

    #  Start a plugin-level timer if we have one;
    #  we will silently ignore the request if the 
    #  timeout option is not specified by the user.
    $self->start_timer();

}

=pod

=head3 get_sys_info()

    my ($descr, $object_id) = $plugin->get_sys_info();

    Returns the sysDescr.0 and sysObjectId.0 OIDs from the remote
    agent, the sysObjectId.0 OID is translated to an OS family; string
    returned will be one of:

    *  hpux
    *  sunos4
    *  solaris
    *  osf
    *  ultrix
    *  hpux10
    *  netbsd1
    *  freebsd
    *  irix
    *  linux
    *  bsdi
    *  openbsd
    *  win32
    *  hpux11
    *  unknown

    sysDescr.0 is a free-text description containing more specific
    information on the OS being queried.

=cut

sub get_sys_info {

    my $self = shift;

    my %oids = qw(
        sysdescr    .1.3.6.1.2.1.1.1.0
        sysobjectid .1.3.6.1.2.1.1.2.0
    );

    my $result = $self->get(values %oids);

    return ($OS_TYPES{$result->{$oids{'sysobjectid'}}},
            $result->{$oids{'sysdescr'}});

}

sub _ensure_defined_results {
    my ($host, $results_hash_ref) = @_;

    my @errors = ();

    for my $oid (sort keys %{$results_hash_ref}) {
        my $value = $results_hash_ref->{$oid};
        if ($value =~ m/nosuch/msi) {
            push(@errors, "${host}:${oid} $value");
        }
    }

    return (scalar(@errors) == 0) ? undef : join(', ', @errors);

}

sub debug {
    my $self = shift;
    return unless $self->opts->get('snmp-debug') == 1;

    my $msg = shift;
    print STDERR scalar(localtime()) . qq{: $msg\n};

}

=pod

=head1 AUTHORS

 * Max Schubert  (maxschube@cpan.org)
 * Ryan Richins 
 * Shaofeng Yang

=head1 Special Thanks

Special thanks to my teammates Ryan Richins and Shaofeng Yang at Comcast
for their significant contributions to this module and to my managers 
Jason Livingood and Mike Fischer at Comcast for allowing our team to 
contribute code we have created or modified at work back to the open 
source community.  If you live in the northern Virginia area and are 
a talented developer / systems administrator, Comcast is hiring :).

=cut

1;
