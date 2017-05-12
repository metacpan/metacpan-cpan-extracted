# This is a Perl interface to the client facilities of XML-RPC for
# C/C++ (aka Xmlrpc-c).

use strict;
use warnings;
package RPC::Xmlrpc_c::Client;

=head1 NAME

RPC::Xmlrpc_c::Client - XML-RPC For C/C++ client

=head1 SYNOPSIS

 use RPC::Xmlrpc_c::Client;
 use RPC::Xmlrpc_c::Client::Curl;

 RPC::Xmlrpc_c::Client::Curl->createObject(TRANSPORT      => \$transport,
                                           TRANSPORTPARMS => {});

 RPC::Xmlrpc_c::Client->createObject(TRANSPORT => $transport,
                                     CLIENT    => \$client,
                                     ERROR     => \$error);

 $addend1 = RPC::Xmlrpc_c::Value->newInt(5);
 $addend2 = RPC::Xmlrpc_c::Value->newInt(7);

 $client->call(CARRIAGEPARM  => {
                   SERVERURL => 'http://localhost:8080/RPC2'
                               },
               METHOD        => 'sample.add',
               PARAMS        => [ $addend1, $addend2 ],
               RESULT_XMLRPC => \$result,
               ERROR         => \$error);
                       
 print("Sum of 5 and 7 is $result->value()\n");

 RPC::Xmlrpc_c::Client::callXml(METHOD => 'sample.add',
                                PARAMS => [ $addend1, $addend2 ],
                                XML    => \$xml,
                                ERROR  => \$error);

 print("XML for call is: $xml\n");


=head1 DESCRIPTION

This module performs XML-RPC client functions, via the executable libraries
of XML-RPC For C/C++.  I.e. you can write an XML-RPC client program using
this.

This differs from another, older facility, C<RPC::XML>, in that
C<RPC::XML> is Perl all the way down to the operating system.  Its
modules call other Perl modules that provide HTTP and XML services,
and those call other Perl modules, etc.  By contrast,
C<RPC::Xmlrpc_c::Client> calls executable (machine language) libraries
which are part of XML-RPC For C/C++.  It requires much less CPU time.

An alternative that requires a little less code and understanding is
C<RPC::Xmlrpc_c::ClientSimple>.  It's less flexible, though.

=cut

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw( );
our @EXPORT_OK;
our $VERSION = "1.03";
use Carp;
#use Data::Dumper;

bootstrap RPC::Xmlrpc_c::Client $VERSION;


RPC::Xmlrpc_c::Client::_client_setup_global_const(\my $error);

if ($error) {
    croak("Failure from executable library: $error");
}


=head2 RPC::Xmlrpc_c::Client->createObject

 RPC::Xmlrpc_c::Client->createObject(TRANSPORT => $transport,
                                     CLIENT    => \$client,
                                     ERROR     => \$error);

This creates a C<RPC::Xmlrpc_c::Client> object, which you can use to
perform XML-RPC RPCs.

Arguments:

=over 4

=item TRANSPORT

This is the XML transport object the client will use to transport
XML to and from the server.  The only XML transport class included
in the B<RPC-Xmlrpc_c> package is C<RPC::Xmlrpc_c::Curl>, which
transports the XML via HTTP using the popular Curl HTTP library.
But in theory, there can be other transport classes, and they don't
even have to use HTTP (But if they don't, then it's not actually
XML-RPC).

This argument is mandatory.

=item CLIENT

This is a reference to a scalar variable that the method sets to
the handle of the new object.

If you do not specify this option, you don't get a handle for the
object, and as no reference is created to the object, it gets destroyed
as soon as it is created.  This is not very useful.

If the method fails to create the object, it sets the variable
arbitrarily.  See C<ERROR>.

=item ERROR

This is a reference to a scalar variable that the method sets to
a text description of why it is unable to create the object.  If
it I<is> able to create the object, it sets it to C<undef>.

If you do not specify this option and creation fails, the method
croaks.

=cut

sub createObject(%) {

    my ($class, %args) = @_;

    my $errorRet;
        # Description of why we can't create the object.  Undefined if
        # we haven't given up yet.

    my $clientR = {};

    my $transportR = $args{TRANSPORT};

    if (!defined($transportR)) {
        $errorRet = "You must specify a TRANSPORT argument";
    } else {
        $clientR->{transport} = $transportR;

        _clientCreate($transportR->{_transportOps}, $transportR->{_transport},
                      \$clientR->{_client}, \$errorRet);

        if (!$errorRet) {
            bless($clientR, $class);
        }
    }

    if ($args{ERROR}) {
        $ {$args{ERROR}} = $errorRet;
    } else {
        if ($errorRet) {
            croak("Failed to create RPC::XML::Client.  $errorRet");
        }
    }
    if ($args{CLIENT}) {
        $ {$args{CLIENT}} = $clientR;
    }
}



#print STDERR Data::Dumper->Dump([ \$clientR ], [ "clientR" ]);


sub DESTROY {
# This, by virtue of its name, is the destructor for a Client object.
# The Perl interpreter calls it when the last reference to the object
# goes away.
    my ($clientR) = @_;

    _clientDestroy($clientR->{_client});
}



sub makeParamArray($$) {

    my ($args, $paramArrayR) = @_;

    my $params = $args->{PARAMS};

    if (defined($params)) {
        if (ref($params) ne 'ARRAY') {
            croak("PARAMS argument " .
                  "must be a reference to an array.");
        } else {
            $$paramArrayR = RPC::Xmlrpc_c::Value->newSimple($params);
        }
    }
}



=head2 RPC::Xmlrpc_c::call


 $addend1 = RPC::Xmlrpc_c::Value->newInt(5);
 $addend2 = RPC::Xmlrpc_c::Value->newInt(7);

 $client->call(CARRIAGEPARM  => {
                   SERVERURL => 'http://localhost:8080/RPC2'
                               },
               METHOD        => 'sample.add',
               PARAMS        => [ $addend1, $addend2 ],
               RESULT_XMLRPC => \$result,
               ERROR         => \$error);
                       
 print("Sum of 5 and 7 is $result->value()\n");

 $client->call(CARRIAGEPARM  => {
                   SERVERURL => 'http://localhost:8080/RPC2'
                               },
               METHOD        => 'system.methodHelp',
               PARAMS        => [ 'sample.add' ],
               RESULT        => \$result,
               ERROR         => \$error);
                       
 print("Help string for sample.add: $result\n");

This method performs an XML-RPC RPC.  It makes the call, waits for the
response, then returns the result.

Arguments:

=over 4

=item CARRIAGEPARM

This is the carriage parameter that tells the XML transport how to 
transport the XML for this call.  Its form and meaning depend on the
transport class.  You chose the transport class when you created the
C<RPC::Xmlrpc_c::Client> object.  See the transport documentation
(e.g. C<RPC::Xmlrpc_c::Client::Curl>) for an explanation of this
value. 

The most typical thing for the carriage parameter to tell is the URL
of the server.

=item METHOD

This is the name of the XML-RPC method you are invoking.  An XML-RPC
server offers various methods, identified by textual names.

=item PARAMS

This is a reference to an array of parameters for the RPC.  An XML-RPC
has an arbitrary number of ordered parameters.  The meaning of the
parameters depends upon the XML-RPC method.

The correspondence between each item in the array and the XML-RPC
value which is the parameter is that documented for
C<RPC::Xmlrpc_c::newSimple()>.  For example, 'hello' would signify
the XML-RPC string value "hello", while [1, 2, 3] would signify an
XML-RPC array value with 3 items, being respectively XML-RPC string
values '1', '2', and '3'.

If you need more precise control over the XML-RPC types and values,
use objects of class C<XML::Xmlrpc_c::Value>.  Example:

    PARAMS => [ XML::Xmlrpc_c::Value(5),
                XML::Xmlrpc_c::Value(7) ]

If you do not specify C<PARAMS>, there are no XML-RPC parameters.

=item RESULT

This is a reference to a scalar variable.  C<call> sets this variable
to the XML-RPC result of the RPC.

The value set is of a basic Perl type.  The correspondence between the
XML-RPC value which is the result and the value of this variable is that
you would get from C<RPC::Xmlrpc_c::Value::ValueSimple()>.

If the RPC fails or the client is unable to execute the RPC (see
C<ERROR>), call() croaks.

If you need more precise analysis of the result, use C<RESULT_XMLRPC>
instead.

You can specify both C<RESULT> and C<RESULT_XMLRPC> to get the same result
in two forms.

If you specify neither C<RESULT> nor C<RESULT_XMLRPC>, you can't know the
result of the RPC.
  
=item RESULT_XMLRPC

This is like C<RESULT> except that C<call> sets the referenced variable to
a C<RPC::Xmlrpc_c::Value> object, which means you have more detail about
the result.

But you also need more code to use it.

tem ERROR

This is a reference to a scalar variable that the method sets to
a text description of why it is unable to execute the RPC or why
the RPC, though fully executed, failed.  (The only way to distinguish
the two is in the English interpretation of the text).

If the RPC completed with success, the method sets this variable to
C<undef>.

If you do not specify this option and C<call> is unable to execute
the RPC or the RPC fails, you can't tell.

When C<call> sets the C<ERROR> variable to a defined value, it makes
the C<RESULT> and C<RESULT_XMLRPC> variables undefined.

=cut

sub call(%) {

    my ($clientR, %args) = @_;

    my $errorRet;
    my $result;

    # We pretend we have the flexible carriage parameter interface, in
    # which the form of the carriage parameter depends upon the
    # transport type, like Xmlrpc-c's C++ interface, but the C
    # interface is still primitive and has the more restrictive
    # server_info interface, so rather than pass CARRIAGEPARM opaquely
    # to the transport, we interpret it and expect it to have a
    # SERVERURL member and nothing else.

    if (!defined($args{CARRIAGEPARM})) {
        $errorRet = "You must specify a CARRIAGEPARM argument";
    } elsif (!defined($args{CARRIAGEPARM}->{SERVERURL})) {
        $errorRet = "CARRIAGEPARM argument does not have a SERVERURL member";
    } elsif (!defined($args{METHOD})) {
        $errorRet = "You must specify a METHOD argument";
    } else {
        makeParamArray(\%args, \my $paramArray);

        _clientCall($clientR->{_client},
                    $args{CARRIAGEPARM}->{SERVERURL},
                    $args{METHOD},
                    $paramArray->{_value},
                    \my $_result, \my $error);

        if ($error) {
            $errorRet = $error;
        } else {
            $result = RPC::Xmlrpc_c::Value->new($_result);
        }
    }
    
    if ($args{ERROR}) {
        $ {$args{ERROR}} = $errorRet;
    } else {
        if ($errorRet) {
            croak("XML-RPC call failed.  $errorRet");
        }
    }

    if ($result) {
        if ($args{RESULT_XMLRPC}) {
            $ {$args{RESULT_XMLRPC}} = $result;
        }
        if ($args{RESULT}) {
            $ {$args{RESULT}} = $result->valueSimple();
        }
    }
}

push (@EXPORT_OK, 'call');



=head2 RPC::Xmlrpc_c::Client::callXml

 RPC::Xmlrpc_c::Client::callXml(METHOD => 'sample.add',
                                PARAMS => [ $addend1, $addend2 ],
                                XML    => \$xml,
                                ERROR  => \$error);

 print("XML for call is: $xml\n");


This computes the XML for the described XML-RPC call.  You could send this to
an XML-RPC server, and get back the XML-RPC response XML, to effect an XML-RPC
RPC.


Arguments:

=over 4

=item METHOD

This is the name of the XML-RPC method you are invoking.

It is analogous to the same-named parameter of C<RPC::Xmlrpc_c::Client::call>.

=item PARAMS

This is a reference to an array of parameters for the RPC.

It is analogous to the same-named parameter of C<RPC::Xmlrpc_c::Client::call>.

=item XML

This is a reference to a scalar variable.  C<callXml> sets this variable
to the XML for the call.

=item ERROR

This is a reference to a scalar variable that the method sets to a text
description of why it is unable to generate the XML.  If it I<is> able to
create the object, it sets it to C<undef>.

If you do not specify this option and creation fails, the method croaks.

=cut

sub callXml(%) {

    my (%args) = @_;

    my $errorRet;
        # Description of why we can't generate the XML.  Undefined if
        # we haven't given up yet.

    if (!defined($args{METHOD})) {
        $errorRet = "You must specify a METHOD argument";
    } else {
        makeParamArray(\%args, \my $paramArray);

        _callXml($args{METHOD},
                 $paramArray->{_value},
                 \my $xml, \my $error);

        if ($error) {
            $errorRet = $error;
        } else {
            if ($args{XML}) {
                $ {$args{XML}} = $xml;
            }
        }

    }
    if ($args{ERROR}) {
        $ {$args{ERROR}} = $errorRet;
    } else {
        if ($errorRet) {
            croak("Failed to generate XML-RPC call XML.  $errorRet");
        }
    }
}

push (@EXPORT_OK, 'callXml');



1;
__END__
