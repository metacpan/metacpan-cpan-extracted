package RPC::XML::Deparser::XS;

use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use RPC::XML::Deparser::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	deparse_rpc_xml
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	deparse_rpc_xml
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('RPC::XML::Deparser::XS', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

RPC::XML::Deparser::XS - Fast XML-RPC deparser written in C

=head1 SYNOPSIS

  use RPC::XML;
  use RPC::XML::Deparser::XS;

  my $req = RPC::XML::request->new( foo => RPC::XML::int->new(123) );
  my $xml = deparse_rpc_xml($req);

  # $xml ==> <?xml version="1.0"?>
  #          <methodCall>
  #            <methodName>foo</methodName>
  #            <params>
  #              <param><value><int>123</int></value></param>
  #            </params>
  #          </methodCall>

=head1 DESCRIPTION

This module provides a single function L</deparse_rpc_xml> to deparse
(serialize) XML-RPC requests and responses.

=over 4

=item deparse_rpc_xml

  my $xml = deparse_rpc_xml($obj);

Deparse an object of either RPC::XML::request or RPC::XML::response.

B<<< Note that UTF-8 flags must not be turned on in strings in the
argument structure. >>>

=back

=head2 EXPORT

L</deparse_rpc_xml> is exported by default. If you don't want it to be
exported, just say like this:

 use RPC::XML::Deparser::XS ();


=head1 PERFORMANCE

L</deparse_rpc_xml> is about 3.5 times faster than C<<
$obj->as_string() >>.


=head1 DEPENDENCY

=over 4

=item glib2

This is not a perl module. See L<http://www.gnome.org/>.

=item IPC::Run

=item RPC::XML

=item Test::Exception

=item Test::More

=back


=head1 SEE ALSO

=over 4

=item RPC::XML

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 YMIRLINK Inc.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself


=cut
