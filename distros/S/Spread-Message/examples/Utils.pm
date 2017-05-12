#!/usr/bin/perl

package Utils;

our $VERSION = 0.1;

BEGIN {
	sub logit (@);
};

require Exporter;
@ISA         = qw(Exporter);
@EXPORT      = qw/getlock read_config_file forkit clone logit
				$Program_Name $Command
				/;

=head1 NAME

Utils - A general set of perl functions to be included

=head1 SYNOPSIS

use Utils;

=head1 DESCRIPTION

Utils is used for aquiring locks, date functions and error reporting.

Following are a set of utility functions that are used often in the
genloader code. Each function or set of functions is described below.

It is used by the examples OK!

=cut

=pod

 
   Variables Defined and exported are:
 
        $Program_Name  = the basename of the program running
        $Command       = the complete command use to run proggy
 

=cut

our($Program_Name, $Command);
$Command = "$0 @ARGV";
@_ = split(/\/+/, $0);
$Program_Name = pop(@_);


=pod

 
  Subroutine getlock 
       
        Args: $file to use as lock file
 
        Rtns: true/false
   create a lock file for application synchronisation in an atomic
   manner.


=cut

sub getlock
{
    my $file = shift;
    my $pid = '';

    if( -f $file )
    {
        chomp($pid = `head -1 $file`);

        # Make sure the PID is valid
        if( $pid !~ /^\d+$/ )
        {
            warn "Invalid PID $pid read from lockfile $file\n";
            return 0;
        }

        # Return true if the PID is our pid, This is used to indicate
        # getlock() being called more than once
        return 2 if "$pid" eq "$$";

        # let's check to see if the process is still running
        if( kill(0,$pid) )
        {
            warn "Process $pid is still running\n";
            return 0;
        }


        # OK we have checked the PID and it isn't ours and there isn't a
        # process with that same PID
    }

    # We want to create our lock file
    # First create a temp file with out PID in it then rename(2) it to
    # the lock file name for Atomicity
    unless( open(TMP,">$file..TMP") )
    {
        warn "Can't create TMP lock file $file..TMP";
        return 0;
    }

    print TMP "$$\n";
    close TMP;

    # get the lock
    unless (rename("$file..TMP", $file) )
    {
        warn "Can't rename TMP lock file to $file";
        return 0;
    }


    # make sure the new file is infact a reference to ourselves
    return 1 if getlock($file) == 2;

    # Else
    warn "Can't confirm we got the lock in $file for PID $$";
    return 0;
}

=pod

 
  Subroutine read_config_file
        
        Args: config file to read in
 
        Rtns: nothing but sets variables in the Settings:: package
 
  Description:
        Read in the config file and set all the variables into the
        Settings:: package.
        
        An example config file is:
               $hosts = ['x', 'a', 'b' ];
        

=cut

sub read_config_file
{
    my $configfile = shift;  # The config file to read
    my $return = 1;

    #warn("Reading config file $configfile");
    if( -r $configfile )
    {
        package Settings;        # Flip to a different name space

        # Now read in the configuration info
        unless ($return = do $configfile )
        {
            warn "couldn't parse $configfile: $@" if $@;
            warn "couldn't do $configfile: $!"    unless defined $return;
            warn "couldn't run $configfile"       unless $return;

            $return = 0;   # To indicate failure
        }
    }
    else
    {
        warn "can't read $configfile\n";
        $return = 0;
    }

    return $return;

}


=pod

 
  Subroutine  forkit
 
        Args: none
 
        Rtns: none
 
  Description: forks into daemon mode or dies on error.
 

=cut

use POSIX qw(setsid);     # For setsid()

sub forkit
{
    my($pid) = fork;        # fork child
    if ($pid)       # exit if parent
    {
        #warn("Parent: $$ forked child: $pid");
        exit;
    }
    die "Couldn't fork: $!\n" unless defined($pid);

    # Child code from here
    # Become our own session leader
    POSIX::setsid() ||
        die "Can't start new session: $!\n";

	# Set output to LogFile if defined in the config
	my $file = $Settings::state{'LogFile'} || '/dev/null';
    open(STDIN, '/dev/null');
    open(STDOUT, ">> $file");
	my $oldfh;
	$oldfh = select(STDOUT); $| = 1; select($oldfh);
    open(STDERR, ">>&STDOUT");
	$oldfh = select(STDERR); $| = 1; select($oldfh);

	my $cwd = $Settings::state{'CWD'} || '/';
    chdir($cwd) ||
        die "Can't cd to $cwd : $!\n";
}

=pod

 
  Subroutine  clone
 
        Args: none
 
        Rtns: none
 
  Description: forks and execs another child process that looks just
  like us :-). Parent isn't affected
 

=cut

sub clone
{
    my($pid) = fork;        # fork child
    if ($pid)       # return if parent
    {
        #warn("Parent: $$ forked child: $pid");
        return;
    }
    die "Couldn't fork: $!\n" unless defined($pid);

    # Child code from here
    # Become our own session leader
    POSIX::setsid() ||
        die "Can't start new session: $!\n";

	# Exec ourselves from scratch
	#warn("Cloning - $Command");
	exec "$Command";   # Just rerun ourselves
}

=pod

 
  Subroutine  log
 
        Args: the message to print
 
        Rtns: none
 
  Description: prints a formatted response to stdout with time stamp
  added. This could easily be extended to other things
 

=cut

sub logit (@)
{
	print scalar(localtime),":[$$] ",@_;
}

=head1 AUTHOR

       Mark Pfeiffer <markpf@mlp-consulting.com.au>

=head1 COPYRIGHT

       Copyright (c) 2003 Mark Pfeiffer. All rights reserved.
       This program is free software; you can redistribute it
       and/or modify it under the same terms as Perl itself.

=cut

1;

