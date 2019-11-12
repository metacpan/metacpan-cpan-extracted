package Sys::RunAlways;

# version info
$VERSION= '0.06';

# be as strict and verbose as possible
use strict;
use warnings;

# make sure we know how to lock
use Fcntl ':flock';

# process local storage
my $silent;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl functionality
#
#-------------------------------------------------------------------------------
# import
#
#  IN: 1 class (not used)
#      2 .. N options (default: none)

sub import {
    my ( undef, %args )= @_;

    # obtain parameters
    $silent= delete $args{silent};

    # sanity check
    if ( my @huh= sort keys %args ) {
        die "Don't know what to do with: @huh";
    }

    return;
} #import

#-------------------------------------------------------------------------------

INIT {
    # no warnings here
    no warnings;

    # no data handle, we're screwed
    print( STDERR "Add __END__ to end of script '$0' to be able use the features of Sys::RunAlways\n" ),exit 2
     if tell( *main::DATA ) == -1;

    # we're still running
    exit 0 if !flock main::DATA,LOCK_EX | LOCK_NB;

    # tell the world if necessary
    printf STDERR "'%s' has been started at %s\n", $0, scalar time
      if !$silent;
} #INIT

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Sys::RunAlways - make sure there is always one invocation of a script active

=head1 SYNOPSIS

 use Sys::RunAlways;
 # code of which there must always be on instance running on system

 use Sys::RunAlways silent => 1;  # don't tell the world we're starting
 # code of which there must always be on instance running on system

=head1 DESCRIPTION

Provide a simple way to make sure the script from which this module is
loaded, is always running on the server.

=head1 VERSION

This documentation describes version 0.06.

=head1 METHODS

There are no methods.

=head1 THEORY OF OPERATION

The functionality of this module depends on the availability of the DATA
handle in the script from which this module is called (more specifically:
in the "main" namespace).

At INIT time, it is checked whethere there is a DATA handle: if not, it
exits with an error message on STDERR and an exit value of 2.

If the DATA handle is available, and it cannot be C<flock>ed, it exits
silently with an exit value of 0.

If there is a DATA handle, and it could be C<flock>ed, a message is put on
STDERR and execution continues without any further interference.  Optionally,
the message on STDERR can be prevented by specifying the "silent" parameter
in the C<use> statement with a true value, like:

  use Sys::RunAlways silent => 1;

=head1 REQUIRED MODULES

 Fcntl (any)

=head1 CAVEATS

=head2 symlinks

Execution of scripts that are (sym)linked to another script, will all be seen
as execution of the same script, even though the error message will only show
the specified script name.  This could be considered a bug or a feature.

=head2 changing a running script

If you change the script while it is running, the script will effectively
lose its lock on the file.  Causing any subsequent run of the same script
to be successful, causing two instances of the same script to run at the
same time (which is what you wanted to prevent by using Sys::RunAlone in
the first place).  Therefore, make sure that no instances of the script are
running (and won't be started by cronjobs while making changes) if you really
want to be 100% sure that only one instance of the script is running at the
same time.

=head1 ACKNOWLEDGEMENTS

Inspired by Randal Schwartz's mention of using the DATA handle as a semaphore
on the London PM mailing list.

=head1 SEE ALSO

L<Sys::RunAlone>.

=head1 AUTHOR

 Elizabeth Mattijsen

maintained by LNATION, <thisusedtobeanemail@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2005, 2006, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
