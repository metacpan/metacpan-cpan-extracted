package Mobile::Executive;

# Executive.pm - the mobile agent client support code.
#
# Author: Paul Barry, paul.barry@itcarlow.ie
# Create: October 2002.
# Update: April 2003 - version 1.x series supports relocation.
#         May 2003 - version 2.x adds support for authentication and
#             encryption using Crypt::RSA.

require Exporter;

our $VERSION      = 2.03;

our @ISA          = qw( Exporter );

# We export all the symbols declared in this module by default.

our @EXPORT       = qw( 
                         relocate
                         $absolute_fn
                         $public_key
                         $private_key
                      );

our @EXPORT_OK    = qw(
                      );
                      
our %EXPORT_TAGS = (
                   );                         
                      
use constant KEY_ID    => 'Mobile::Executive ID';
use constant KEY_SIZE  => 1024;
use constant KEY_PASS  => 'Mobile::Executive PASS';

use constant TRUE      => 1;
use constant FALSE     => 0;


BEGIN {

    # This BEGIN block is executed as soon as the module is "used".
    # We determine the absolute path and filename of the program using
    # this module.  This is important, as the Devel::Scooby.pm module needs
    # this information during a relocate.  Note the use of 'our'.
    # We also generate a PK+ and PK- for "users" of this module.

    use Crypt::RSA;  # Provides authentication and encryption services.
    use File::Spec;  # Provides filename and path services.

    our $absolute_fn = File::Spec->rel2abs( File::Spec->curdir ) . '/' . $0;

    my $rsa = new Crypt::RSA;

    our ( $public_key, $private_key ) = 
            $rsa->keygen(
                Identity  => KEY_ID . "$$" . "$0",
                Size      => KEY_SIZE,
                Password  => KEY_PASS . "$0" . "$$",
                Verbosity => FALSE
            ) or die $rsa->errstr, "\n";
}

sub relocate {

    # The relocate subroutine.
    #
    # IN:  The IP name/address and protocol port number of a Location to
    #      relocate to.
    #
    # OUT: nothing.

    my $ip_address    = shift;
    my $protocol_port = shift;

    # Does nothing - just a place holder.  The Devel::Scooby module
    # runs its own relocate code as part of its "sub" invocation.  That is,
    # a call to this relocate results in the Devel::Scooby running its own
    # version of "relocate".

    return;
}

1;  # As it is required by Perl.

##########################################################################
# Documentation starts here.
##########################################################################

=pod

=head1 NAME

"Mobile::Executive" - used to signal the intention to relocate a Scooby mobile agent from the current Location to some other (possibly remote) Location.

=head1 VERSION

2.03 (version 1.0x never released).

=head1 SYNOPSIS

use Mobile::Executive;

   ...

relocate( $remote_location, $remote_port );

=head1 DESCRIPTION

Part of the Scooby mobile agent machinery, the B<Mobile::Executive> module provides a means to signal the agents intention to relocate to another Location.  Typical usage is as shown in the B<SYNOPSIS> section above.  Assuming an instance of B<Mobile::Location> is executing on B<$remote_location> at protocol port number B<$remote_port>, the agent stops executing on the current Location, relocates to the remote Location, then continues to execute from the statement immediately AFTER the B<relocate> statement.

Note: a functioning keyserver is required.

=head1 Overview

The only subroutine provided to programs that use this module is:

=over 4

relocate

=back

and it takes two parameters: a IP address (or name) of the remote Location, and the protocol port number that the Location is listening on.

=head1 Internal methods/subroutines

A Perl B<BEGIN> block determines the absolute path to the mobile agents source code file, and puts it into the B<$absolute_fn> scalar (which is automatically exported).  This block also generates a PK+/PK- pairing (in B<$public_key> and B<$private_key>) and exports both values (as they are used by B<Devel::Scooby>). 

=head1 RULES FOR WRITING MOBILE AGENTS

There used to be loads, but now there is only one.  Read the B<Scooby Guide>, available on-line at: B<http://glasnost.itcarlow.ie/~scooby/guide.html>.

=head1 SEE ALSO

The B<Mobile::Location> class (for creating Locations), and the B<Devel::Scooby> module (for running mobile agents).

The Scooby Website: B<http://glasnost.itcarlow.ie/~scooby/>.

=head1 AUTHOR

Paul Barry, Institute of Technology, Carlow in Ireland, B<paul.barry@itcarlow.ie>, B<http://glasnost.itcarlow.ie/~barryp/>.

=head1 COPYRIGHT

Copyright (c) 2003, Paul Barry.  All Rights Reserved.

This module is free software.  It may be used, redistributed and/or modified under the same terms as Perl itself.

