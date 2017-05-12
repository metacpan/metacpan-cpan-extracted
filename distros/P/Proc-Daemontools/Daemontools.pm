#
# Daemontools.pm  -  Perl interface for the functionalities of Daemontools
# Author: Bruno Negrao G. Zica - bnegrao@engepel.com.br
#

package Proc::Daemontools;
use 5.008;
use strict;
use warnings;
use Carp;
use vars qw($VERSION);

$VERSION = "1.06";

#########################################################
# ENVIRONMENTAL CONFIGURATION VARIABLES (default values)
#########################################################
#
# These values are the default values for these variables.
# All of them can be overwritten by arguments passed to the new() method.
#
# Path to directory containing the daemontools executables 
# (supervise, svc, svok, svstat, etc):
my $DAEMONTOOLS_DIR = "/usr/local/bin";

# Path to directory monitored by supervise
my $SERVICE_DIR = "/service";

# The default daemon
my $DAEMON = undef;

# Required executables - without them we can´t work
my @REQ_EXECS = qw ( svc svok svstat );

sub new {
    # the code bellow add support for object cloning.
    # See Perl Cookbook, 13.6. Cloning Objects
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;
    my %options = @_;
    my $self  = { };
    bless($self, $class);
    # Set the atribute values:
    if ($parent) {
        # Inherit these values from the father
        $self->{"DAEMONTOOLS_DIR"} = $parent->{"DAEMONTOOLS_DIR"};
        $self->{"SERVICE_DIR"} = $parent->{"SERVICE_DIR"};
        $self->{"DAEMON"} = $parent->{"DAEMON"};
    } else {
        # Set the default values
        $self->{"DAEMONTOOLS_DIR"} = $DAEMONTOOLS_DIR;
        $self->{"SERVICE_DIR"} = $SERVICE_DIR;
        $self->{"DAEMON"} = $DAEMON;
    }
    # now, override these values with those received by
    # the user: (ignoring misspelled options passed, if any)
    my $key;
    foreach $key (keys %options) {
        if ( exists $self->{$key} ) {
            # the regex bellow remove any trailing / from the end of 
            # the directory name 
            $options{$key} =~ s|/$||;
            $self->{$key} = $options{$key};
        }
    }
    # the function bellow tests if every system tool needed can be found
    $self->_checkEnv(); # this function will croak if something went wrong
    
    # declare the complete path to the required executables
    my $dir = $self->{"DAEMONTOOLS_DIR"};
    foreach (@REQ_EXECS) {
        $self->{$_} = "$dir/$_";
    }
    return $self;
} 

# _checkEnv() Checks for the presence of the required executables
sub _checkEnv { # returns: void
    my $self = shift;
    my $dir = $self->{"DAEMONTOOLS_DIR"};
    my @execs = @REQ_EXECS;
    foreach (@execs) {
        unless ( -e "$dir/$_" ) {
            croak "ERROR: the file $_ cannot be found on directory $dir. " .
                  "Verify if you set the DAEMONTOOLS_DIR parameter correctly";
        }
        unless ( -x "$dir/$_" ) {
            croak "ERROR: the file $_ is not executable by this user.";
        }
    }
    
    my $dir2 = $self->{"SERVICE_DIR"};
    unless ( -e $dir2 ) {
        croak "ERROR: the directory $dir2 doesn´t exist. ".
              "Verify if you set the SERVICE_DIR parameter correctly.";
    }
    unless ( -x $dir2 ) {
        croak "ERROR: the directory $dir2 is not executable by this user.";
    }
    
    if ( $self->{"DAEMON"} ) {
        my $daemon = "$dir2/" . $self->{"DAEMON"};
        unless ( -e $daemon ) {
            croak "ERROR: can´t find the daemon $daemon. Verify if you set ".
                  "the DAEMON parameter correctly.";
        }
        unless (-x $daemon ) {
            croak "ERROR: the directory $daemon is not executable by this user.";
        }
    }
}

# Acessor method daemon(): to get/set the DAEMON atribute
sub daemon() { # returns: string
    my $self = shift;
    if (@_) { $self->{"DAEMON"} = shift; } 
    return $self->{"DAEMON"};
}            
    
sub up () { # returns: boolean
    my $self = shift;
    return $self->doSvc(@_); #returns the boolean returned by doSvc()
}

sub down () { # returns: boolean
    my $self = shift;
    return $self->doSvc(@_); #returns the boolean returned by doSvc()
}

# doSvc() uses the svc executable. It only returns true when the svc command really
# performed what it was suposed to do.
# This method cannot be run directly, instead it have to be called from methods with
# special names, as up() and down()
# Ex:
# To start qmail-send(within the up() method): $self->doSvc("qmail-send");
# To start the default daemon(within the up() method): $self->doSvc();
# To stop qmail-smtpd(within the down() method): $self->doSvc("qmail-smtpd");
sub doSvc() { # returns: boolean
    my $self = shift;
    my $daemon = $_[0] ? $_[0] : $self->daemon();
    (caller(1))[3] =~ /::(\w+)$/;
    my $caller = $1;  # this variable will define what option svc will receive
    my $daemon_dir = $self->{"SERVICE_DIR"} . "/" . $daemon;
    croak "ERROR: directory $daemon_dir doesn´t exist or is not " .
        "accessible. " unless ( -x $daemon_dir );
    my $svc = $self->{"svc"};
    my $svok = $self->{"svok"};
    my $opt;    # option to svc (-u, -d, -t, etc)
    # defining $opt
    if ( $caller =~ /up/ ) {
        $opt = "-u";
    } elsif ( $caller =~ /down/ ) {
        $opt = "-d";
    }
    # svok returns 0 for success and non-zero for failure. Also, it only 
    # issues an output when there was an error
    open (FH, "$svok $daemon_dir 2>&1|") or 
        croak "ERROR: cannot run svok: $!";
    my $output = <FH>;
    close FH;
    my $ERROR;
    if ($? != 0) { # there was an error
        $ERROR = "ERROR: svok said that supervise is not running successfully on " .
        " directory $daemon_dir.";
        if ($output) { $ERROR .= " svok said: "; }
        croak $ERROR;
    }
    # svc always return 0 even if it encountered an error. Also, it only outputs
    # anything when something bad occured, hence we need to check its stderr:
    $output = `$svc $opt $daemon_dir 2>&1`;
    croak "ERROR: $svc failed. It said: $output" if $output;

    # Now we gonna check if doSvc() actually did what it tried to do.
    $self->_isDaemon($daemon, $caller) ?
        return 1    :
        return 0;
}

# _isDaemon() - An interface to svstat
# Synopsis: $self->("daemon" [,state]);
# Tells if the daemon is in a determined state. States are: up, down.
# If it doesn´t receive an state string, it will return a string containing the output
# of svstat about the required daemon.
# To know if qmail-send is stopped:
#     my $boolean = $self->_isDaemon("qmail-send", "down");
# To know if qmail-smtpd is started:
#     my $boolean = $self->_isDaemon("qmail-smtpd", "up");
sub _isDaemon (@) { # returns: boolean or string.
    my $self = shift;
    my $daemon = shift;
    my $state = @_ ? shift    : "Print-Output";
    my $daemon_dir = $self->{"SERVICE_DIR"} . "/" . $daemon;
    croak "ERROR: directory $daemon_dir doesn´t exist or is not " .
        "accessible. " unless ( -x $daemon_dir );
    my $svstat = $self->{"svstat"}; # the svstat executable
    my $boolean = undef;    # what will be returned by this method 
    # svstat always return 0 and always outputs to stdout even when there´s an error
    open (FH, "$svstat $daemon_dir|" ) or 
        croak "ERROR: can´t execute the command \'$svstat $daemon_dir\': $!";
    my $output = <FH>;
    close FH;
    if ($state =~ /Print-Output/ ) {
        $boolean = $output; # output of svstat will be printed
    } elsif ($state =~ /up/) {
        $boolean = $output =~ /^$daemon_dir: up/;
    } elsif ($state =~ /down/) {
        $boolean = $output =~ /^$daemon_dir: down/;
    }
    return $boolean;
}

# Ex: if ( $self->is_up("qmail-smtpd") ) { print "SMTPD IS UP";}
# or: if ( $self->is_up() ) { print "$self->daemon() IS UP";}
sub is_up () { # returns: boolean
    my $self = shift;
    my $daemon = $_[0] ? $_[0] : $self->daemon();
    return $self->_isDaemon($daemon, "up");
}

sub status () { # returns: string
    my $self = shift;
    my $daemon = $_[0] ? $_[0] : $self->daemon();
    return $self->_isDaemon($daemon);
}

1;
__END__
#
# DOCUMENTATION
#

=head1 NAME

Proc::Daemontools - Perl interface for the functionalities 
                    of Daemontools

=head1 SYNOPSIS

 use Proc::Daemontools;

 my $svc = new Proc::Daemontools;    # default directories assumed
                                     
     or
	
 my $svc = new Proc::Daemontools ( 
             DAEMONTOOLS_DIR => "/some-non-default-dir",
             SERVICE_DIR    => "/some-non-default-dir",
             DAEMON  => "daemon-name"    # optional: a default daemon     
           );
    
 if ( $svc->is_up() ) {
     print $svc->daemon(), " IS UP!\n";
 }
    
 my $daemon="qmail-send";
 # We want to stop $daemon instead of the default daemon
 if ( $svc->is_up($daemon) ) { 
     if ( $svc->down($daemon) ) { 
         print "OK, $daemon stopped. \n";
     } else {
         print "Ops, $daemon didn´t stop yet. Maybe it is waiting" .
               " for some child to exit. Perhaps you want to kill" .
               " that child by yourself... \n";
     }
 }
 
 # Now we want it to start
 if ( $svc->up($daemon) ) {
     print "OK, $daemon started. \n".
 }
    
 # Let´s set the default daemon to be qmail-smtpd
 $svc->daemon("qmail-smtpd");
    
 # Let´s see what svstat says about it:
 print "The current status of "   . $svc->daemon() .  " " .
       "reported by svstat is: "  . $svc->status() .  "\n";

=head1 ABSTRACT

This module is a Perl interface for Daemontools package.
Daemontools was written by Dan Bernstein and is intended to control Unix/Linux
daemons. 

=head1 DESCRIPTION

Proc::Daemontools requires that the Daemontools package be installed on your
machine in order to function. It won´t even instantiate its object if it can´t 
find the Daemontools executables.

It assumes 2 default directories:

    /usr/local/bin 
	the directory containing svc, svstat, supervise, etc

    /service
	the directory monitored by supervise to start/stop 
	the daemons

If you´re not using these default directories you can specify them explicilty
within the new() function.

The main goal of Proc::Daemontools is to start/stop the daemons managed by
Daemontools, what is done internally with the "svc" command using the options
"-u" and "-d". 

The other functionalities provided by Daemontools can be implemented later
if people require it.

=head1 METHODS

=head2	new()

Instantiate a Proc::Daemontools object. Without arguments it assumes its default values for the important directories. Also no default daemon is set.

I<Returns>: B<object>: A Proc::Daemontools object.

Atributes:

    SERVICE_DIR		: path to service dir
    DAEMONTOOLS_DIR	: path to executables dir
    DAEMON		: a the default daemon

To set your directories:

    my $svc = new Proc::Daemontools (
        SERVICE_DIR => "/my_path",
        DAEMONTOOLS_DIR => "/my_path/bin"
    );
        
To clone an existing object:

    my $svc2 = $svc->new(); # $svc2 has the same atributes of $svc
    
To set a default daemon:

    my $send = $svc2->new( DAEMON => "qmail-send" );

=head2	daemon()        

Set/get the default daemon.

I<Returns>: B<string>: containing the default daemon or B<undef> if none was set.

=head2	up()

Starts the default daemon. It not only issues a "svc -u" on the daemon, but it also checks with svstat to see if the daemon really was brought up. So you don´t want to check it again by yourself, ok?

If you pass it a daemon name as an argument it will start the passed daemon instead of the default one.

I<Returns>: B<boolean>: 1 if the daemon is up, 0 otherwise.

=head2 down()

Works just like up() but issues a "svc -d" to stop the daemon.

I<Returns>: B<boolean>: 1 if the daemon is down, 0 otherwise.

=head2	status()

Prints the output of svstat for the default daemon. It also accepts the name of a daemon as an argument.

I<Returns>: B<string>: the same output of svstat

=head2 is_up()

Returns if the default daemon is up. It also accepts the name of a daemon as an argument.

I<Returns>: B<boolean>: 1 if the daemon is up, 0 otherwise.

=head1 SEE ALSO

Daemontools web site: http://cr.yp.to/daemontools.html

=head1 AUTHOR

Bruno Negrao,  B<bnegrao@engepel.com.br>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bruno Negrao

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
