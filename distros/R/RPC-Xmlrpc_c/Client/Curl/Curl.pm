# This is a Perl interface to the Curl client XML transport of XML-RPC for
# C/C++ (aka Xmlrpc-c).

use strict;
use warnings;
package RPC::Xmlrpc_c::Client::Curl;




=head1 NAME

RPC::Xmlrpc_c::Client::Curl - Curl XML transport for RPC::Xmlrpc_c::Client

=head1 SYNOPSIS

 use RPC::Xmlrpc_c::Client::Curl qw(:all);

 RPC::Xmlrpc_c::Client::Curl->createObject(TRANSPORT      => \my $transport,
                                           TRANSPORTPARMS => {},
                                           ERROR          => \my $error1);

 RPC::Xmlrpc_c::Client->createObject(TRANSPORT => $transport,
                                     CLIENT    => \my $client,
                                     ERROR     => \my $error2);

=cut

=head1 DESCRIPTION

This module provides client XML transport functions for use with a
RPC::Xmlrpc-c::Client XML-RPC client object.  In particular, it provides
functions based on HTTP using the Curl HTTP library.  It uses
XML-RPC For C/C++'s Curl transport.

Probably the only reason you would be interested in this class is that you
need something like it to use C<RPC::Xmlrpc_c::Client>, as seen in the
example above.

=cut

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw( createObject call );
our $VERSION = "1.05";
use Carp;
use Data::Dumper;

bootstrap RPC::Xmlrpc_c::Client::Curl $VERSION;


RPC::Xmlrpc_c::Client::_client_setup_global_const(\my $error);

if ($error) {
    croak("RPC::Xmlrpc_c::Client::_client_setup_global_const failed.  $error");
}


=head2 RPC::Xmlrpc_c::Client::Curl->createObject

 RPC::Xmlrpc_c::Client::Curl->createObject(
    TRANSPORT      => \my $transport,
    TRANSPORTPARMS => {},
    ERROR          => \my $error1);

This creates a C<RPC::Xmlrpc_c::Client::Curl> object.

Arguments:

=over 2

C<TRANSPORT>

=over 2

This is a reference to a scalar variable that the method sets to
the handle of the new object.

If you do not specify this option, you don't get a handle for the
object, and as no reference is created to the object, it gets destroyed
as soon as it is created.  This is not very useful.

If the method fails to create the object, it sets the variable
arbitrarily.  See C<ERROR>.

=back

C<TRANSPORTPARMS>

=over 2

This is a reference to a hash of named transport parameters.

Example:

   { network_interface  => 'eth0',
     no_ssl_verify_peer => 1,
     timeout => 5
   }

The names (hash keys) are the names of the members of
C<struct xmlrpc_curl_xportparms> in Xmlrpc-c.  This subroutine recognizes
only the parameters up through C<timeout>.

Any transport parameter you don't specify defaults to the Xmlrpc-c
default.  If you specify a key that is not a valid transport
parameter name, createObject() ignores it.

=back

C<ERROR>

=over 2

This is a reference to a scalar variable that the method sets to
a text description of why it is unable to create the object.  If
it I<is> able to create the object, it sets it to C<undef>.

If you do not specify this option and creation fails, the method
croaks.

=back

=back
 
=cut

sub createObject {

    my ($class, %args) = @_;

    my $errorRet;
        # Description of why we can't create the object.  Undefined if
        # we haven't given up yet.

    my $transportR = {};

    my $transportParms = $args{TRANSPORTPARMS} || {};

    _transportCreate($transportParms,
                     \$transportR->{_transport},
                     \$transportR->{_transportOps},
                     \$errorRet);
 
    if (!$errorRet) {
        bless($transportR, $class);
    }

    if ($args{ERROR}) {
        $ {$args{ERROR}} = $errorRet;
    } else {
        if ($errorRet) {
            croak("Failed to create RPC::XML::Client::Curl.  $errorRet");
        }
    }
    if ($args{TRANSPORT}) {
        $ {$args{TRANSPORT}} = $transportR;
    }
}



sub DESTROY {
# This, by virtue of its name, is the destructor for a Curl object.
# The Perl interpreter calls it when the last reference to the object
# goes away.
    my ($transportR) = @_;

    _transportDestroy($transportR->{_transport});
}



1;
__END__
