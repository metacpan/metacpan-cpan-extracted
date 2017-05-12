package SOAP;

$VERSION = '0.28';
sub Version { $VERSION; }

require 5.004;
require SOAP::EnvelopeMaker;  # everything you need to build SOAP packets
require SOAP::Parser;         # everything you need to parse SOAP packets
require SOAP::Transport;      # everything you need to send and receive SOAP packets

1;

__END__

=head1 NAME

SOAP - Library for SOAP clients and servers in Perl

=head1 SYNOPSIS

  use SOAP;
  print "This is SOAP/Perl-$SOAP::VERSION\n";


=head1 DESCRIPTION

SOAP/Perl is a collection of Perl modules which provides a simple
and consistent application programming interface (API) to the 
Simple Object Access Protocl (SOAP).

To learn more about SOAP, see the W3C note at
<URL:http://www.w3.org/TR/SOAP>

This library provides tools for you to build SOAP clients and servers.

The library contains modules for high-level use of SOAP, but also modules
for lower-level use in case you need something a bit more customized.

SOAP/Perl uses Perl's object oriented features exclusively. There are
no subroutines exported directly by these modules.

This version of SOAP/Perl supports the SOAP 1.0 specification,
which is an IETF internet draft. See <URL:http://www.ietf.org>
for details.

The main features of the library are:

=over 3

=item *

Contains various reusable components (modules) that can be
used separately or together.

=item *

Provides an object oriented model for serializing/deserializing and
sending/receiving SOAP packets (lovingly referred to in some circles
as SOAP bars). Within this framework we currently support access to SOAP
over HTTP, but we're open to expanding support for SOAP over SMTP and
other transports in the future.

=item *

Provides a fully object oriented interface.

=item *

Supports SOAP 1.1 spec. The current version does not yet handle arrays.

=item *

Supports serializing/deserializing of sophisticated object graphs
which may have cycles (a circular queue would serialize just fine,
for instance).

=item *

Provides full namespace support for SOAP 1.1, which is recommended
by the spec.

=item *

Implements full support for SOAP 1.1 references, including correctly dealing
with shared references between header and body elements.

=item *

Experimental support for extensibility of the serialization/deserialization
architecture has been included; see SOAP::TypeMapper for details, and
SOAP::Struct and SOAP::StructSerializer for a specific example.

=item *

Supports servers using CGI or Apache+mod_perl. Tested with Apache on Linux
as well as IIS on Windows 2000.

=back


=head2 The EnvelopeMaker Object

SOAP::EnvelopeMaker takes as input an array of header objects and a single
body object (currently these "objects" are either Perl hashes, or instances
of SOAP::Struct), and produces as output an XML stream.

=head2 The Parser Object

SOAP::Parser takes as input a string (or a file/file handle) and parses
the content as a SOAP envelope. This results in an array of header objects
and a single body element.

To avoid coupling the SOAP serialization/deserialization code to HTTP,
a set of loadable transports is also provided. See the following modules
for documentation of the transport architecture:

 SOAP::Transport::HTTP::Client
 SOAP::Transport::HTTP::Server
 SOAP::Transport::HTTP::Apache
 SOAP::Transport::HTTP::CGI

=head2 Where to Find Examples

See SOAP::EnvelopeMaker for a client-side example that shows the
serialization of a SOAP request, sending it over HTTP and receiving
a response, and the deserialization of the response.

See SOAP::Transport::HTTP::Apache for a server-side example that shows
how to map incoming HTTP requests to method calls on your own Perl
classes.

=head1 OVERVIEW OF CLASSES AND PACKAGES

This table should give you a quick overview of the classes provided by the
library.

-- High-level classes you should begin with --
 SOAP::Struct          -- Ordered collection often used to
                          hold SOAP requests and responses
 SOAP::TypedPrimitive  -- Adds an explicit xsi:type to stream
 SOAP::EnvelopeMaker   -- Serializes objects into SOAP bars
 SOAP::Parser          -- Deserializes SOAP bars into objects
 SOAP::Transport       -- Description of transport architecture
 SOAP::Transport::HTTP -- Description of HTTP transport
 SOAP::Transport::HTTP::Client -- Client side support for HTTP,
                                  using libwww-perl
 SOAP::Transport::HTTP::Server -- Server side support for HTTP,
                                  decoupled from web server APIs
 SOAP::Transport::HTTP::Apache -- Apache/mod_perl support
 SOAP::Transport::HTTP::CGI    -- Vanilla CGI support

-- Serialization architecture --

 SOAP::Envelope      -- Low level access to SOAP serialization
 SOAP::OutputStream  -- used in conjunction with SOAP::Envelope for
                        Low level access to SOAP serialization
 SOAP::Packager      -- Helps to implement SOAP 1.0 packages,
                        used by SOAP::Envelope and SOAP::OutputStream
 SOAP::GenericHashSerializer    -- Generic serializer for Perl hash references
 SOAP::GenericScalarSerializer  -- Generic serializer for Perl scalars
 SOAP::TypedPrimitiveSerializer -- Specialized serializer
 SOAP::StructSerializer         -- Specialized serializer

-- Deserialization architecture --

 SOAP::GenericInputStream.pm   -- Look here if you are interested in
                                  extending the deserialization framework
                                  to be able to deserialize your own objects
-- Miscellaneous --

 SOAP::TypeMapper    -- An experimental extensibility point for the
                        serialization architecture
 SOAP::Defs          -- Constants used by the other modules


=head1 MORE DOCUMENTATION

All modules contain detailed information on the interfaces they
provide.


=head1 BUGS AND LIMITATIONS

The serialization framework does not yet handle arrays,
and the HTTP transport does not handle M-POST.

=head1 ACKNOWLEDGEMENTS

Keith Brown is the original and current author of this work, but
he worked very closely with Don Box in developing a common design
and implementation architecture (Don was building a Java implementation
side-by-side, and Keith and Don worked together in a kind of XP style
of programming - it was fun). GopalK at Microsoft was tremendously
helpful in ferreting out issues in the SOAP spec. Mike Abercrombie
at DevelopMentor (where Keith and Don work) was very supportive
of the effort as well. Thanks Mike!

=head1 COPYRIGHT

  Copyright 1999-2000, DevelopMentor. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is normally available from CPAN
as well as:

  http://soapl.develop.com/soap_perl_current

The best place to discuss this code is on the SOAP
mailing list at:

 http://discuss.develop.com/soap.html

=cut
