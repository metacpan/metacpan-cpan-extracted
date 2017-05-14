###########################################################################
#                                                                         #
# Nagios::Cmd                                                             #
# Written by Albert Tobey <tobeya@cpan.org>                               #
# Copyright 2003, Albert P Tobey                                          #
#                                                                         #
# This program is free software; you can redistribute it and/or modify it #
# under the terms of the GNU General Public License as published by the   #
# Free Software Foundation; either version 2, or (at your option) any     #
# later version.                                                          #
#                                                                         #
# This program is distributed in the hope that it will be useful, but     #
# WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       #
# General Public License for more details.                                #
#                                                                         #
###########################################################################
package Nagios::Cmd;
use vars qw( $AUTOLOAD $debug %commands );
use Fcntl qw( :flock SEEK_END O_WRONLY );
use Symbol;
use Carp;
$debug = undef;

%commands = (
    ADD_HOST_COMMENT => [qw(host persistent author comment)],
    ADD_SVC_COMMENT => [qw(host service persistent author comment)],
    DEL_HOST_COMMENT => [qw(comment_id)],
    DEL_ALL_HOST_COMMENTS => [qw(host)],
    DEL_SVC_COMMENT => [qw(comment_id)],
    DEL_ALL_SVC_COMMENTS => [qw(host service)],
    DELAY_HOST_NOTIFICATION => [qw(host next_notification_time)],
    DELAY_SVC_NOTIFICATION => [qw(host service next_check_time)],
    SCHEDULE_HOST_SVC_CHECKS => [qw(host next_check_time)],
    ENABLE_SVC_CHECKS => [qw(host service)],
    DISABLE_SVC_CHECKS => [qw(host service)],
    ENABLE_SVC_NOTIFICATIONS => [qw(host service)],
    DISABLE_SVC_NOTIFICATIONS => [qw(host service)],
    ENABLE_HOST_SVC_NOTIFICATIONS => [qw(host)],
    DISABLE_HOST_SVC_NOTIFICATIONS => [qw(host)],
    ENABLE_HOST_SVC_CHECKS => [qw(host)],
    DISABLE_HOST_SVC_CHECKS => [qw(host)],
    ENABLE_HOST_NOTIFICATIONS => [qw(host)],
    DISABLE_HOST_NOTIFICATIONS => [qw(host)],
    ENABLE_ALL_NOTIFICATIONS_BEYOND_HOST  => [qw(host)],
    DISABLE_ALL_NOTIFICATIONS_BEYOND_HOST => [qw(host)],
    ENABLE_NOTIFICATIONS => [qw(time)],
    DISABLE_NOTIFICATIONS => [qw(time)],
    SHUTDOWN_PROGRAM => [qw(time)],
    RESTART_PROGRAM => [qw(time)],
    PROCESS_SERVICE_CHECK_RESULT => [qw(host service return_code plugin_output)],
    PROCESS_HOST_CHECK_RESULT => [qw(host return_code plugin_output)],
    SAVE_STATE_INFORMATION => [qw(time)],
    READ_STATE_INFORMATION => [qw(time)],
    START_EXECUTING_SVC_CHECKS => undef,
    STOP_EXECUTING_SVC_CHECKS => undef,
    START_ACCEPTING_PASSIVE_SVC_CHECKS => undef,
    STOP_ACCEPTING_PASSIVE_SVC_CHECKS => undef,
    ENABLE_PASSIVE_SVC_CHECKS => [qw(host service)],
    DISABLE_PASSIVE_SV_CHECKS => [qw(host service)],
    ACKNOWLEDGE_SVC_PROBLEM => [qw(host service persistent comment)],
    ACKNOWLEDGE_HOST_PROBLEM => [qw(host persistent comment)]
);

sub nagios_cmd {
    my( $self, $cmd ) = @_;

    # there can be only one "\n" and this function is used for passing through
    # custom commands, too
    chomp( $cmd ); 

    my $fh = gensym;
    # cannot open in append mode, since that causes a seek
    sysopen( $fh, $$self, O_WRONLY )
        || croak "could not sysopen $$self for writing: $!";
    
    flock $fh, LOCK_EX;
    # only seek to end of file on regular files
    seek( $fh, 0, SEEK_END ) if ( -f $$self );
    print $fh "$cmd\n";
    flock $fh, LOCK_UN;
    close $fh;
}
    
sub new {
    my( $type, $cmdfile ) = @_;
    croak "$cmdfile does not exist!" unless ( -e $cmdfile );
    croak "$cmdfile is not a pipe!"  unless ( -p $cmdfile );
    return bless \$cmdfile, $type;
}

# allow use of any file instead of a fifo (great for testing)
sub new_anyfile {
    my( $type, $cmdfile ) = @_;
    return bless \$cmdfile, $type;
}

# host service return_code plugin_output
sub service_check {
    shift->nagios_cmd( "[".time()."] ". join(";", process_args('PROCESS_SERVICE_CHECK_RESULT',@_)) );
}

# host return_code plugin_output
sub host_check {
    shift->nagios_cmd( "[".time()."] ". join(";", process_args('PROCESS_HOST_CHECK_RESULT',@_)) );
}

sub DESTROY { 1 }

sub AUTOLOAD {
    my $self = shift;

    $AUTOLOAD =~ m/Nagios::Cmd::(\w+)$/;
    my $method = $1;

    print "method $method called with arguments: '", join(', ', @_), "'\n"
        if ( $debug );

    confess "invalid method call '$method'"
        unless ( exists($commands{$method}) );

    # process method arguments to allow hash, hashref, or list
    my @command = process_args( $method, @_ );

    # get the current time for the command's timestamp
    my $time = '[' . time() . '] ';

    print "writing '", $time, join(';', @command), "' to command file ...\n"
        if ( $debug );

    # write to the command pipe
    $self->nagios_cmd( $time . join(';', @command) );
}

sub process_args {
    my( $method, @input ) = @_;
    my @command = ();

    # a few commands take no arguments, so skip this block of code in that case
    if ( defined($commands{$method}) ) {
        # get the list of expected argument keys
        my @parts = @{ $commands{$method} };

        # call to method used named parameters - put them into a hashref
        # and use the hashref parsing to do the rest
        if ( @input > @parts && @input % 2 == 0 ) {
            my %tmp = @input;
            @input = ( \%tmp );
        }

	    # process hashed arguments
	    if ( ref($input[0]) eq 'HASH' ) {
	        my $args = shift(@input);
	        for ( my $i=0; $i<=$#parts; $i++ ) {
	            if ( !exists($args->{$parts[$i]}) ) {
	                croak "insufficient arguments to $method - '$parts[$i]' argument is missing";
                }
	            else {
	                $command[$i + 1] = $args->{$parts[$i]};
	            }
	        }
	    }

	    # user sent us a list (presumably) already in the right order
	    else {
            splice( @command, @command, 0, @input );
	    }
    }

    # run through and resolve Nagios::Object objects into their textual names
    # name() is a Nagios::Object specific method for doing polymorphic stuff
    # like this
    foreach ( @command ) {
        if ( ref $_ =~ /^Nagios::/ && $_->can('name') ) {
            $_ = $_->name;
        }
    }

    unshift( @command, $method );
    return @command;
}

sub Help {
    my $func = shift;

    if ( !$func ) {
        foreach my $cmd ( keys(%commands) ) {
            print "$cmd(", join(', ', @{$commands{$cmd}}), ")\n";
        }
    }
    else {
        print "$func(", join(', ', @{$commands{$func}}), ")\n";
    }
}

sub Commands {
    return \%commands;
}

1;

__END__

=head1 NAME

Nagios::Cmd

=head1 DESCRIPTION

Nagios::Cmd is a module to take care of the logistics involved in submitting a command to Nagios's command pipe.  flock(2) is used to insure that parallel calls to this module don't corrupt each other (unlikely in any case).

=head1 SYNOPSIS

To turn on this module's debugging, set $Nagios::Cmd::debug  to a value greater than 0 before calling any methods:
 $Nagios::Cmd::debug = 1;

To get a list of valid commands and their arguments, run the following command:
 perl -MNagios::Cmd -e 'Nagios::Cmd::Help'
 perl -MNagios::Cmd -e 'Nagios::Cmd::Help(ADD_HOST_COMMENT)'

You might need to specify an include path for Nagios::Cmd since it most likely won't be in your standard perl include directories:
 perl -I/opt/nagios/libexec -MNagios::Cmd -e 'Nagios::Cmd::Help'

=head1 EXAMPLE

 use lib '/opt/nagios/libexec';
 use Nagios::Cmd;
 my $cmd = Nagios::Cmd->new( "/var/opt/nagios/rw/nagios.cmd" );
 # -- OR --
 $cmd = Nagios::Cmd->new_anyfile( "/var/tmp/test_file.txt" );

 my $cmd_args = {
    host => $host,
    persistent => 1,
    author => "Al Tobey",
    comment => "This host is very stable."
 };
 $cmd->ADD_HOST_COMMENT( $cmd_args );

 $cmd->ADD_HOST_COMMENT(
    host => $host,
    persistent => 1,
    author => "Al Tobey",
    comment => "This host is very stable."
 );

 $cmd->ADD_HOST_COMMENT( $host, 1, "Al Tobey", "This host is very stable." );

 # -- OR --

 use lib '/opt/nagios/libexec';
 use Nagios::Cmd;
 my $time = CORE::time(); # use CORE:: if you have Time::HiRes overriding time()

 # submit a custom command to the pipe
 $cmd->nagios_cmd( "[$time] DEL_ALL_HOST_COMMENTS;localhost" );

=head1 METHODS

=over 4

=item new()

Initiate a Nagios::Cmd object.  It takes ony one argument, the full path to the
nagios command file.  If you want to test this module out, without submitting
all kinds of noise to Nagios, set $Nagios::Cmd::debug = 1, which will allow the
command file to be a regular file instead of a pipe.   You can also create a
test command file with the mknod(1) command.

 mknod -m 600 /var/tmp/nagios_cmd p

The cat(1) command works well as a reader on a fifo.

 my $cmd = Nagios::Cmd->new( "/usr/local/nagios/var/rw/cmd.pipe" );

=item new_anyfile()

Same thing as new, but does not check to see if the target file is a fifo.

 my $cmd = Nagios::Cmd->new_anyfile( "/dev/null" );
 my $cmd = Nagios::Cmd->new_anyfile( "/tmp/commands.txt" );

=item service_check(), host_check()

These are (essentially) hard-coded aliases for PROCESS_SERVICE_CHECK_RESULT and PROCESS_HOST_CHECK_RESULT.

Passive host checks don't work with Nagios 1.0, but should be available for 2.0, so keep that in mind if you're thinking about using host_check.  **WARNING** It's mainly here to play with.  Your code may need twiddling with to work with future releases of this module.

 $cmd->service_check( "PING", "localhost", 1, "PING CRITICAL - Packet loss = 100%" );
 $cmd->host_check( "localhost", 1, "CRITICAL - Host Down!" );

=item nagios_cmd()

Use this method if you need to use a command that is not defined in
this module.  Adding commands to this module is pretty trivial, so you
may want to look at the %commands hash at the top of the Cmd.pm file.

 $cmd->nagios_cmd( "[".time()."] " . join(";", $COMMAND_NAME, @ARGS) );
 $cmd->nagios_cmd( "[1063919882] DISABLE_HOST_SVC_NOTIFICATIONS;localhost" );

=back

=head1 LICENSE

GPL

=head1 AUTHOR

Albert P Tobey <albert.tobey@priority-health.com>

=cut
