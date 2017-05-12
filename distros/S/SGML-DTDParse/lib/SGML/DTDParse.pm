#
# $Id: DTDParse.pm,v 2.2 2005/07/16 03:21:35 ehood Exp $

package SGML::DTDParse;

$VERSION = "2.00";
sub Version { $VERSION; }

require 5.005;

## General utilities for programs

@SGML::DTDParse::CommonOptions = (
  'help',
  'man',
  'version',
);

sub process_common_options {
  my $opts = shift;
  usage(-verbose => 0, -exitval => 0)  if ($opts->{'version'});
  usage(-verbose => 1, -exitval => 0)  if ($opts->{'help'});
  usage(-verbose => 2, -exitval => 0)  if ($opts->{'man'});
}

sub usage {
  require Pod::Usage;
  require FindBin;
  Pod::Usage::pod2usage( {
    -message => join('', 'Version: ', $FindBin::Script, ' v', $VERSION, "\n"),
    @_
  });
}


1;

__END__

=head1 NAME

SGML::DTDParse - Parse an SGML or XML DTD

=head1 SYNOPSIS

  use SGML::DTDParse;
  print "This is DTDParse v$SGML::DTDParse::VERSION\n";

=head1 DESCRIPTION

The DTDParse collection is a set of Perl modules and scripts for
manipulating SGML an XML Document Type Definitions (DTDs). DTDParse
is designed primarily to aid in the understanding and documentation
of DTDs.

Typical usage of this package is as follows:

=over

=item 1.

Parse the DTD with L<dtdparse|dtdparse>. This produces an XML
representation of the DTD. This representation exposes both the logical
structure of the DTD (the actual meta-structure of its grove) and the
organizational structure of the DTD (the declarations and parameter
entities) that comprise its textual form.

=item 2.

Manipulate the XML document produced by dtdparse to do whatever you
want. DTDParse is shipped with several programs that demonstrate
various capabilities, including B<dtdformat> which can produce HTML
or DocBook L<http://www.oasis-open.org/docbook/> RefEntry pages for
each element and parameter entity in the DTD.

=back

=head1 DTDParse XML DTD

The following is the XML DTD for XML documents created with
L<dtdparse|dtdparse> (the DTD is also provided in the file C<etc/dtd.dtd>
of the DTDParse distribution):

  <!-- This is the DTD for the documents produced by DTDParse.
       The public identifier for this DTD is:

	"-//Norman Walsh//DTD DTDParse V2.0//EN"

    -->

  <!ELEMENT dtd (notation|entity|element|attlist)+>
  <!ATTLIST dtd
	  version		CDATA	#REQUIRED
	  unexpanded	CDATA	#IMPLIED
	  title		CDATA	#IMPLIED
	  namecase-general	CDATA	#IMPLIED
	  namecase-entity	CDATA	#IMPLIED
	  xml		CDATA	#IMPLIED
	  system-id	CDATA	#IMPLIED
	  public-id	CDATA	#IMPLIED
	  declaration	CDATA	#IMPLIED
	  created-by	CDATA	#IMPLIED
	  created-on	CDATA	#IMPLIED
  >

  <!ELEMENT notation EMPTY>
  <!ATTLIST notation
	  name		CDATA	#REQUIRED
	  public		CDATA	#IMPLIED
	  system		CDATA	#IMPLIED
  >

  <!ELEMENT entity (text-expanded?, text?)>
  <!ATTLIST entity
	  name		CDATA	#REQUIRED
	  type		CDATA	#REQUIRED
	  notation	CDATA	#IMPLIED
	  public		CDATA	#IMPLIED
	  system		CDATA	#IMPLIED
  >

  <!ELEMENT text	(#PCDATA)*>
  <!ELEMENT text-expanded	(#PCDATA)*>

  <!ELEMENT element (content-model-expanded, content-model?,
		     inclusions?, exclusions?)>
  <!ATTLIST element
	  name		CDATA	#REQUIRED
	  stagm		CDATA	#IMPLIED
	  etagm		CDATA	#IMPLIED
	  content-type	(element|mixed|cdata|empty|rcdata)	#IMPLIED
  >

  <!ENTITY % cm.mix "sequence-group|or-group|and-group
		     |element-name|parament-name
		     |pcdata|cdata|rcdata|empty">

  <!ELEMENT content-model-expanded (%cm.mix;)>
  <!ELEMENT content-model (%cm.mix;)>
  <!ELEMENT inclusions (%cm.mix;)>
  <!ELEMENT exclusions (%cm.mix;)>

  <!ELEMENT sequence-group (%cm.mix;)*>
  <!ATTLIST sequence-group
	  occurrence	CDATA	#IMPLIED
  >

  <!ELEMENT or-group (%cm.mix;)*>
  <!ATTLIST or-group
	  occurrence	CDATA	#IMPLIED
  >

  <!ELEMENT and-group (%cm.mix;)*>
  <!ATTLIST and-group
	  occurrence	CDATA	#IMPLIED
  >

  <!ELEMENT element-name EMPTY>
  <!ATTLIST element-name
	  name		CDATA	#REQUIRED
	  occurrence	CDATA	#IMPLIED
  >

  <!ELEMENT parament-name EMPTY>
  <!ATTLIST parament-name
	  name		CDATA	#REQUIRED
  >

  <!ELEMENT empty EMPTY>
  <!ELEMENT pcdata EMPTY>
  <!ELEMENT cdata EMPTY>
  <!ELEMENT rcdata EMPTY>

  <!ELEMENT attlist (attdecl, attribute+)>
  <!ATTLIST attlist
	  name	CDATA	#REQUIRED
  >

  <!ELEMENT attdecl (#PCDATA)>

  <!ELEMENT attribute EMPTY>
  <!ATTLIST attribute
	  name		CDATA	#REQUIRED
	  type		CDATA	#REQUIRED
	  enumeration	(yes|no|notation)	#IMPLIED
	  value		CDATA	#REQUIRED
	  default		CDATA	#REQUIRED
  >


=head1 SEE ALSO

L<dtdparse|dtdparse>,
L<dtdformat|dtdformat>,
L<dtddiff|dtddiff>,
L<dtdflatten|dtdflatten>,
L<SGML::DTDParse::DTD|SGML::DTDParse::DTD>

=head1 PREREQUISITES

The prerequisites listed are for all modules and scripts:

B<Getopt::Long>,
B<Text::DelimMatch>,
B<XML::Parser>,
B<XML::DOM>

For prerequisites that apply for a specific script or module,
see the individual scripts' and modules' reference pages.

=head1 AVAILABILITY

E<lt>I<http://dtdparse.sourceforge.net/>E<gt>

=head1 AUTHORS

DTDParse package originally developed by Norman Walsh,
E<lt>ndw@nwalsh.comE<gt>.

Earl Hood, E<lt>earl@earlhood.comE<gt>, picked up support and
maintenance.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 1999-2001, 2003 Norman Walsh
  Copyright (C) 2005, Earl Hood

DTDParse may be copied only under the terms of either the Artistic
License or the GNU General Public License, which may be found in the
DTDParse distribution.
