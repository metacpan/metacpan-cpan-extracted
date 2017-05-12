## This file is Copyright (C) 2002, Paul Prince <princep@charter.net>.
## It is licensed and distributed under the terms of Perl itself.

package Qmail::Control;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

=begin comment
=head1 README

  Qmail/Control      version 0.01
  Qmail/Control/Lock version 0.01
  ===============================

This module is not finished.  Only the methods listed in 
L<"METHODS"> have been implemented, but at least these have been
completed.

This module's interface will change before the next minor release.
Specifically, the current nasty error return scheme will be replaced
with a better one, similar to DBI's.

This version is being uploaded to get feedback.  Version 0.02 will have
a stable interface, support for most of Qmail's control files,
[hopefully] a better and more portable locking system, and should be
ready for production use.

=end comment

=head1 INSTALLATION

Use the following to install this module:

    shell$ perl Makefile.PL
    shell$ make
    shell$ make test
    shell# make install
    
=head1 NAME

Qmail::Control - Perl extension for interfacing with Qmail's control files.

=head1 DESCRIPTION

Qmail::Control provides an interface for reliably modifying Qmail's
control files from your Perl programs.  It only provides an object
oriented interface.

=head1 SYNOPSIS

  use Qmail::Control;

  my $control = Qmail::Control->new();

  # Get a shared lock on the control system.  This is important, because
  # when we're making decisions based on the return values of multiple
  # methods, we don't want to be fooled by a race condition.
  my $lock = $control->lock('shared');

  # Print all hosts which we accept mail for.
  my @rcpthosts = $control->get_rcpthosts();
  foreach (@rcpthosts) {
    print "Found a rcpthost for $_->{'host'}.";
    }

  # Print the list of virtual domains.
  my @virtualdomains = $control->get_virtualdomains();
  foreach (@virtualdomains) {
    print "Found a vdom for $_->{'domain'}, user is $_->{'user'}.";
    }

  # Get our default domain name.
  my $defaultdomain = $control->defaultdomain();

  # Now, we're going to start changing things in the system.  We must
  # get an exclusive lock before we do.
  $control->relock($lock, 'exclusive');

  # Add a rcpthost.
  # Multiple hash references are legal.
  $control->add_rcpthosts( {host => 'domain2.com'} );

  # Add a virtualdomain entry.
  # Multiple hash references are legal.
  $control->add_virtualdomain({
    domain => 'domain2.com',
    user   => 'domain2systemaccount',
    }); 

  # Set our default domain name.
  # Also, this works with defaulthost, and me.
  # Setting this to undef for any control file (except 'me', which is
  # required) will delete that file.  Use '' to clear out a file.
  $control->defaultdomain({ set => 'domain.com' }); 
 
  $control->unlock($lock);

=cut

######################
# METHODS START HERE #
######################

=head1 METHODS

=over 30

=item Qmail::Control->new()

Creates a new Qmail::Control object.

Returns a reference to the newly created object.

Takes no arguments, currently.  This may change, but the argumentless
form will always exist.

=cut

sub new {
#    Do I need this stuff??
#    my $invocant = shift;
#    my $class = ref($invocant) || $invocant;
#    bless($class);

    # Create a new Qmail::Control object.
    my $self = { };
    bless($self);

    # Return a reference to the newly created object.
    return $self;
}

=item $control->lock();

Locks the Qmail control file subsystem.  Note that currently, only
Qmail::Control itself uses this locking system, and that it is entirely
advisory.  You should always lock the control file system before getting
information from more than one Qmail control file.

Returns a Qmail::Control::Lock object.  You must keep track of this.

Takes a single argument, either 'shared' or 'exclusive'.  The
Qmail::Control::Lock object that is returned will be locked in the way
specified.  If no argument is given, the lock object returned will not
be locked at all!

It's ok to use the relock() and unlock() methods provided by the lock
object.

=cut

sub lock {
    my $self = shift;

    # Make a Qmail::Control::Lock object.
    use Qmail::Control::Lock;
    my $lock = Qmail::Control::Lock->new();

    # If we have an argument,
    if (defined $_[0]) {
        # Lock the Qmail control file subsystem, in the way specified.
        ($lock->lock_shared()    or return undef) if ($_[0] eq 'shared'    );
        ($lock->lock_exclusive() or return undef) if ($_[0] eq 'exclusive' );
        if ($_[0] ne 'shared' and $_[0] ne 'exclusive') {
            return undef;
        }
    }
    # Else, we don't want the control file subsystem locked.
    
    # Return the  Qmail::Control::Lock object.
    return $lock;
}

=item $control->get_rcpthosts();

Gets the list of hosts the system is set to accept mail for.

Returns a list of strings, each corresponding to a host that the system
accepts mail for.  If an error occurs, a list will be returned in which
the first element is undef, the second element is a numeric error code,
and the third argument is a detailed text explaining the error.

Takes no arguments at the current time.

The numeric error code is 0 for a system error or 1 for a control file
syntax error.

=cut

sub get_rcpthosts {
    my $self = shift;

    # Open the rcpthosts file for reading.
    open(RCPTHOSTS, '<', '/var/qmail/control/rcpthosts') or
        return(undef, 0, "Unable to open rcpthosts file.");
    
    # Iterate over the file, processing it into the results variable.
    my @results;
    while (<RCPTHOSTS>) {
        chomp;

        # This assumes that a valid hostname is no more than 22
        # characters in length, contains a-z, period (.), and dash (-).
        # They cannot start with period or dash.
        /^[a-z0-9][a-z0-9.-]{0,21}$/ or return(undef, 1,
            "Invalid hostname at $. in rcpthosts file.");
        
        push(@results, $_);
    }

    # If we haven't had any errors, return the results.
    return @results;
}

=item $control->get_virtualdomains();

Gets the list of virtualdomains on this system, and the user associated
with each.

Returns a list, each element representing one virtual domain.  Each
element is also a hash reference, with the keys 'domain' and 'user'.
It can also return an error code, like the one for get_rcpthosts().

Takes no arguments.

=cut

sub get_virtualdomains {
    my $self = shift;

    # Open the virtualdomains file for reading.
    open(VDOMS, '<', '/var/qmail/control/virtualdomains') or
        return(undef, 0, "Unable to open virtualdomains file.");
    
    # Iterate over the file, processing it into the results variable.
    my @results;
    while (<VDOMS>) {
        chomp;

        # Split out the domain and user parts.
        my ($domain, $user) = split(':');
       
        # This assumes that a valid domain name is no more than 22
        # characters in length, contains a-z, 0-9, period (.), and dash (-).
        # They cannot start with period or dash.
        $domain =~ /^[a-z0-9][a-z0-9.-]{0,21}$/ or return(undef, 1,
            "Invalid domain name at line $. in virtualdomains file.");

        # This assumes that a valid username is no more than 32
        # characters in length, contains a-z, 0-9, period (.), and dash (-).
        # They cannot start with period or dash.
        # I need to check DJB's code to make this consistent.
        $user =~ /^[a-z0-9][a-z0-9.-]{0,31}$/ or return(undef, 1,
            "Invalid username at line $. in virtualdomains file.");
        
        push(@results, { domain => $domain, user => $user } );
    }

    # If we haven't had any errors, return the results.
    return @results;
}

=begin _nextversion

=item $control->defaultdomain();

Wazzit do?

Wazzit return?

Wazzit take?

What else do I need to know?

=end _nextversion

=cut

sub defaultdomain {
    my $self = shift;

}

=pod

=back

=head1 AUTHOR

Paul Prince, E<lt>princep@charter.netE<gt>

=head1 SEE ALSO

L<perl>.
L<Qmail::Control::Lock>.

=cut

# End the package.
1;
