package RPC::XML::Parser::XS;

use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use RPC::XML::Parser::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	parse_rpc_xml
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	parse_rpc_xml
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('RPC::XML::Parser::XS', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

RPC::XML::Parser::XS - Fast XML-RPC parser written in C

=head1 SYNOPSIS

  use RPC::XML::Parser::XS;

  my $req = parse_rpc_xml(qq{
    <methodCall>
      <methodName>foo.bar</methodName>
      <params>
        <param><value><string>Hello, world!</string></value></param>
      </params>
    </methodCall>
  });
  # $req is a RPC::XML::request
  
  my $res = parse_rpc_xml(qq{
    <methodResponse>
      <fault>
        <value>
          <struct>
            <member>
              <name>faultCode</name>
              <value><int>-1</int></value>
            </member>
            <member>
              <name>faultString</name>
              <value><string>No such method: foo.bar</string></value>
            </member>
          </struct>
        </value>
      </fault>
    </methodResponse>
  });
  # $res is a RPC::XML::response
  

=head1 DESCRIPTION

This module provides a single function L</parse_rpc_xml> to parse
XML-RPC request and response.

=over 4

=item parse_rpc_xml

  my $obj = parse_rpc_xml($xml);

Parse an XML-RPC methodCall or methodResponse. Resulting object is a
RPC::XML::request or RPC::XML::response depending on the XML.

B<<< Note that UTF-8 flags aren't turned on in strings in the result
structure. This behavior is different from RPC::XML::Parser. >>>

=back

=head2 EXPORT

L</parse_rpc_xml> is exported by default. If you don't want it to be
exported, just say like this:

 use RPC::XML::Parser::XS ();


=head1 PERFORMANCE

When I compared the performance of RPC::XML::Parser and
RPC::XML::Parser::XS, the latter was nearly 20 times faster than the
former. If you have any suspicion in this, please benchmark it
yourself.


=head1 DEPENDENCY

=over 4

=item Libxml2

This is not a perl module. We don't use XML::LibXML.
See L<http://xmlsoft.org/>.

=item IPC::Run

=item MIME::Base64

=item RPC::XML

=item Test::Exception

=item Test::More

=back


=head1 SEE ALSO

=over 4

=item RPC::XML::Parser

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 YMIRLINK Inc.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself


=cut
