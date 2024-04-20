# NAME

Net::EPP - a Perl library for the Extensible Provisioning Protocol (EPP).

# DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in
[STD 69](https://www.rfc-editor.org/info/std69)) is an application-layer
client-server protocol for the provisioning and management of objects stored in
a shared central repository. Specified in XML, the protocol defines generic
object management operations and an extensible framework that maps protocol
operations to objects. As of writing, its only well-developed application is the
provisioning of domain names, hosts, and related contact details.

This package offers a number of Perl modules which implement various EPP-
related functions:

- a low-level protocol implementation ([Net::EPP::Protocol](https://metacpan.org/pod/Net%3A%3AEPP%3A%3AProtocol));
- a low-level client ([Net::EPP::Client](https://metacpan.org/pod/Net%3A%3AEPP%3A%3AClient));
- a high(er)-level client ([Net::EPP::Simple](https://metacpan.org/pod/Net%3A%3AEPP%3A%3ASimple));
- an EPP frame builder ([Net::EPP::Frame](https://metacpan.org/pod/Net%3A%3AEPP%3A%3AFrame));
- a utility library to export EPP response codes
([Net::EPP::ResponseCodes](https://metacpan.org/pod/Net%3A%3AEPP%3A%3AResponseCodes)).

# SEE ALSO

- [Net::EPP::Server](https://metacpan.org/pod/Net%3A%3AEPP%3A%3AServer) - an EPP server implementation.
- [App::pepper](https://metacpan.org/pod/App%3A%3Apepper) - a command-line EPP client.

# AUTHORS

This module is maintained by [Gavin Brown](https://metacpan.org/author/GBROWN),
with the assistance of other contributors around the world, including (but not
limited to):

- Rick Jansen
- Mike Kefeder
- Sage Weil
- Eberhard Lisse
- Yulya Shtyryakova
- Ilya Chesnokov
- Simon Cozens
- Patrick Mevzek
- Alexander Biehl
- Christian Maile
- Tony Finch

# COPYRIGHT

This module is (c) 2008 - 2023 CentralNic Ltd and 2024 Gavin Brown. This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
