use strict;
use warnings;
package RPC::Xmlrpc_c::ClientSimple;


=head1 NAME

RPC::Xmlrpc_c::ClientSimple - Perl extension for XML-RPC For C/C++ client

=head1 SYNOPSIS

 use RPC::Xmlrpc_c::ClientSimple;

 $client = RPC::Xmlrpc_c::ClientSimple->new();

 $client->call(SERVERURL => 'http://localhost:8080/RPC2',
               METHOD    => 'sample.add',
               PARAMS    => [ 5, 7 ],
               RESULT    => \$result,
               ERROR     => \$error);
                       
 print("Sum of 5 and 7 is $result\n");

=head1 DESCRIPTION

This module performs XML-RPC client functions, via the executable libraries
of XML-RPC For C/C++.  I.e. you can write an XML-RPC client program using
this.

This is like C<RPC::Xmlrpc_c::Client>, but less flexible and consequently
easier to use.

It has the same advantages as C<RPC::Xmlrpc_c::Client> over the alternative
Perl XML-RPC facility, C<RPC::XML>.

Here are the things you I<can't> do with C<ClientSimple>.  If you want to
do these things, use C<RPC::Xmlrpc_c::Client> instead and write more
lines of code.


=item *

You can't use an XML transport other than the Xmlrpc-c Curl
transport (which is based on the well known Curl HTTP library).

=item *

You can't supply any carriage parameters other than the server URL.
Carriage parameters are things that tell the XML transport how to
deliver the XML back and forth.  Examples of carriage parameters
you might want to specify are userid/password and SSL certificate
library location.

=item *

You can't find out why client creation failed.  When new() fails,
it simply returns an undefined value.  In contrast,
C<RPC::Xmlrpc_c::Client> gives you an English explanation of the
failure.

=cut

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT;
our @EXPORT_OK;
our $VERSION = "1.01";
use Carp;
use Data::Dumper;



sub new() {

    my ($class) = @_;

    my $retval;

    my $clientSimpleR = {};

    RPC::Xmlrpc_c::Client::Curl->createObject(
        TRANSPORT      => \my $transport,
        TRANSPORTPARMS => {},
        ERROR          => \my $error);

    if (!$error) {
        $clientSimpleR->{transport} = $transport;

        RPC::Xmlrpc_c::Client->createObject(
            TRANSPORT => $transport,
            CLIENT    => \$clientSimpleR->{CLIENT},
            ERROR     => \my $error);

        if (!$error) {
            bless($clientSimpleR, $class);
            $retval = $clientSimpleR;
        }
    }
    return $retval;
}



sub call(%) {

    my ($clientR, %args) = @_;

    my $errorRet;
    my $result;

    if (!defined($args{SERVERURL})) {
        $errorRet = "You must specify a SERVERURL argument";
    } else {
        $clientR->{CLIENT}->call(
            CARRIAGEPARM  => { SERVERURL => $args{SERVERURL} },
            METHOD        => $args{METHOD},
            PARAMS        => $args{PARAMS},
            PARAMS_XMLRPC => $args{PARAMS_XMLRPC},
            RESULT        => $args{RESULT},
            RESULT_XMLRPC => $args{RESULT_XMLRPC},
            ERROR         => \$errorRet
                                      );
    }
    
    if ($args{ERROR}) {
        $ {$args{ERROR}} = $errorRet;
    }
}

push (@EXPORT_OK, 'call');


1;
__END__


