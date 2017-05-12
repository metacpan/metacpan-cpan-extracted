use 5.008004;
use strict;
use warnings;
use utf8;

package RDF::DOAP::Lite;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use CPAN::Meta    2.110320  qw();
use Scalar::Util  1.24      qw( openhandle );

# ============= helper functions =============

sub parse_person
{
	$_[0] =~ m{ \A \s*
		(\S.+)
		(?:
			\s+ \((\w+)\)
		)
		(?:
			\s+ <(?:mailto\:)?(.+)>
		)
	\s* \z }ix and return ($1, $2, $3);
	
	$_[0] =~ m{ \A \s*
		(\S.+)
		(?:
			\s+ <(?:mailto\:)?(.+)>
		)
	\s* \z }ix and return ($1, undef, $2);
	
	return $_[0];
}

{
	my %TURTLE = ( "\t" => "\\t", "\n" => "\\n", "\r" => "\\r", "\"" => "\\\"", "\\" => "\\\\" );
	sub turtle_literal
	{
		no warnings 'uninitialized';
		local $_ = $_[0];
		return q[""] if $_ eq '';
		s{([\t\n\r\"\\])}{$TURTLE{$1}}sg;
		qq("$_");
	}
}

sub turtle_person
{
	my ($name, $nick, $mbox) = parse_person @_;

	unless (defined $nick or defined $mbox)
	{
		return '[ a foaf:Person ]' unless defined $name;
		return sprintf('[ a foaf:Person; rdfs:label %s ]', turtle_literal $name);
	}

	my $person = '[ a foaf:Person';
	$person .= sprintf('; foaf:name %s', turtle_literal $name) if defined $name;
	$person .= sprintf('; foaf:nick %s', turtle_literal $nick) if defined $nick;
	$person .= sprintf('; foaf:mbox <mailto:%s>', $mbox) if defined $mbox;
	$person .= ' ]';
}

{
	my %XML = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;');
	sub xml_literal
	{
		local $_ = shift;
		s{([&"<>])}{$XML{$1}}sg;
		return $_;
	}
}

sub xml_person
{
	my ($name, $nick, $mbox) = parse_person @_;
	
	unless (defined $nick or defined $mbox)
	{
		return '<foaf:Person />' unless defined $name;
		return sprintf('<foaf:Person rdfs:label="%s" />', xml_literal $name);
	}
	
	my $person = "<foaf:Person>\n";
	$person .= sprintf("      <foaf:name>%s</foaf:name>\n", xml_literal $name) if defined $name;
	$person .= sprintf("      <foaf:nick>%s</foaf:nick>\n", xml_literal $nick) if defined $nick;
	$person .= sprintf("      <foaf:mbox rdf:resource=\"mailto:%s\" />\n", xml_literal $mbox) if defined $mbox;
	$person .= "    </foaf:Person>";
	
	return $person;
}

sub rdf_datetype
{
	($_[0] =~ m{ \A [0-9]{4} - [0-9]{2} - [0-9]{2} \z }x) ? 'date' : 'dateTime';
}

# ============= class definition =============

sub new     { my $c = shift; bless { @_==1 ? %{$_[0]} : @_ }, $c }
sub meta    { $_[0]{meta} }
sub changes { $_[0]{changes} }

my %LICENSE = qw(
	agpl_3          http://www.gnu.org/licenses/agpl-3.0.txt
	apache_1_1      http://www.apache.org/licenses/LICENSE-1.1
	apache_2_0      http://www.apache.org/licenses/LICENSE-2.0.txt
	artistic_1      http://www.perlfoundation.org/artistic_license_1_0
	artistic_2      http://www.perlfoundation.org/artistic_license_2_0
	bsd             http://www.opensource.org/licenses/bsd-license.php
	freebsd         http://www.freebsd.org/copyright/freebsd-license.html
	gfdl_1_2        http://www.gnu.org/licenses/fdl-1.2.html
	gfdl_1_3        http://www.gnu.org/licenses/fdl-1.3.html
	gpl_1           http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt
	gpl_2           http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
	gpl_3           http://www.gnu.org/licenses/gpl-3.0.txt
	lgpl_2_1        http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt
	lgpl_3_0        http://www.gnu.org/licenses/lgpl-3.0.txt
	mit             http://www.opensource.org/licenses/mit-license.php
	mozilla_1_0     http://www.mozilla.org/MPL/MPL-1.0.txt
	mozilla_1_1     http://www.mozilla.org/MPL/MPL-1.1.txt
	openssl         http://www.openssl.org/source/license.html
	perl            http://dev.perl.org/licenses/
	perl_5          http://dev.perl.org/licenses/
	qpl_1_0         http://trolltech.com/products/qt/licenses/licensing/qpl
	ssleay          http://h71000.www7.hp.com/doc/83final/BA554_90007/apcs02.html
	sun             http://www.openoffice.org/licenses/sissl_license.html
	zlib            http://www.zlib.net/zlib_license.html
);

my %REPO = qw(
	cvs      CVS
	git      Git
	hg       Hg
	svn      SVN
);

sub doap_ttl
{
	my $self = shift;
	my $fh = openhandle($_[0])
		? $_[0]
		: do { open my $fh, '>', $_[0] or die("Could not open $_[0]: $!"); $fh };
	
	print {$fh} <<'	HEADER', "\n";
@prefix :     <http://usefulinc.com/ns/doap#>.
@prefix dc:   <http://purl.org/dc/terms/>.
@prefix foaf: <http://xmlns.com/foaf/0.1/>.
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#>.
	HEADER
	
	my $meta = $self->meta or die("no meta!");
	my $res  = $meta->resources;
	my $uri  = $res->{X_identifier} ? "<$res->{X_identifier}>" : '[]';
	
	printf {$fh} "$uri\n";
	printf {$fh} "  a :Project;\n";
	printf {$fh} "  :name %s;\n", turtle_literal($_) for grep defined, $meta->name;
	printf {$fh} "  :shortdesc %s;\n", turtle_literal($_) for grep defined, $meta->abstract;
	printf {$fh} "  :description %s;\n", turtle_literal($_) for grep defined, $meta->description;
	printf {$fh} "  :category [ rdfs:label %s ];\n", turtle_literal($_) for grep defined, $meta->keywords;
	printf {$fh} "  :developer %s;\n", turtle_person($_) for grep defined, $meta->authors;
	printf {$fh} "  :helper %s;\n", turtle_person($_) for grep defined, @{ $meta->{x_contributors} || [] };
	printf {$fh} "  :license <%s>;\n", $_ for map { $LICENSE{$_} || ()  } $meta->licenses;
	printf {$fh} "  :homepage <%s>;\n", $_ for grep defined, $res->{homepage};
	printf {$fh} "  :bug-database <%s>;\n", $_ for grep defined, $res->{bugtracker}{web};
	if (my $repo = $res->{repository})
	{
		printf {$fh} "  :repository [\n";
		printf {$fh} "    a :%sRepository;\n", $_ for map { $REPO{$_} || '' } $repo->{type};
		printf {$fh} "    :browse <%s>;\n", $_ for grep defined, $repo->{web};
		printf {$fh} "    :location <%s>;\n", $_ for grep defined, $repo->{url};
		printf {$fh} "  ];\n";
	}
	for my $r (map $_->releases, grep defined, $self->changes)
	{
		$r->date
			? printf {$fh} "  :release [ a :Version; :revision %s^^xsd:string; dc:issued %s^^xsd:%s ];\n", turtle_literal($r->version), turtle_literal($r->date), rdf_datetype($r->date)
			: printf {$fh} "  :release [ a :Version; :revision %s^^xsd:string ];\n", turtle_literal($r->version)
	}
	printf {$fh} "  :programming-language %s.\n", turtle_literal("Perl");
}

sub doap_xml
{
	my $self = shift;	
	my $fh = openhandle($_[0])
		? $_[0]
		: do { open my $fh, '>', $_[0] or die("Could not open $_[0]: $!"); $fh };
	
	print {$fh} <<'	HEADER';
<?xml version="1.0" encoding="UTF-8" ?>
<Project
  xmlns="http://usefulinc.com/ns/doap#"
  xmlns:dc="http://purl.org/dc/terms/"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	HEADER
	
	my $meta = $self->meta or die("no meta!");
	my $res  = $meta->resources;
	
	if ($res->{X_identifier})
	{
		printf {$fh} "  rdf:about=\"%s\">\n", xml_literal($res->{X_identifier});
	}
	else
	{
		printf {$fh} "  >\n";
	}
	
	printf {$fh} "  <name>%s</name>\n", xml_literal($_) for grep defined, $meta->name;
	printf {$fh} "  <shortdesc>%s</shortdesc>\n", xml_literal($_) for grep defined, $meta->abstract;
	printf {$fh} "  <description>%s</description>\n", xml_literal($_) for grep defined, $meta->description;
	printf {$fh} "  <category rdfs:label=\"%s\" />\n", xml_literal($_) for grep defined, $meta->keywords;
	printf {$fh} "  <developer>\n    %s\n  </developer>\n", xml_person($_) for grep defined, $meta->authors;
	printf {$fh} "  <helper>\n    %s\n  </helper>\n", xml_person($_) for grep defined, @{ $meta->{x_contributors} || [] };
	printf {$fh} "  <license rdf:resource=\"%s\" />\n", xml_literal($_) for map { $LICENSE{$_} || ()  } $meta->licenses;
	printf {$fh} "  <homepage rdf:resource=\"%s\" />\n", xml_literal($_) for grep defined, $res->{homepage};
	printf {$fh} "  <bug-database rdf:resource=\"%s\" />\n", xml_literal($_) for grep defined, $res->{bugtracker}{web};
	if (my $repo = $res->{repository})
	{
		printf {$fh} "  <repository>\n";
		printf {$fh} "    <%sRepository>\n", $_ for map { $REPO{$_} || '' } $repo->{type};
		printf {$fh} "      <browse rdf:resource=\"%s\" />\n", xml_literal($_) for grep defined, $repo->{web};
		printf {$fh} "      <location rdf:resource=\"%s\" />\n", xml_literal($_) for grep defined, $repo->{url};
		printf {$fh} "    </%sRepository>\n", $_ for map { $REPO{$_} || '' } $repo->{type};
		printf {$fh} "  </repository>\n";
	}
	for my $r (map $_->releases, grep defined, $self->changes)
	{
		$r->date
			? printf {$fh} "  <release>\n    <Version>\n      <revision rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">%s</revision>\n      <dc:issued rdf:datatype=\"http://www.w3.org/2001/XMLSchema#%s\">%s</dc:issued>\n    </Version>\n  </release>\n", xml_literal($r->version), rdf_datetype($r->date), xml_literal($r->date)
			: printf {$fh} "  <release>\n    <Version>\n      <revision rdf:datatype=\"http://www.w3.org/2001/XMLSchema#string\">%s</revision>\n    </Version>\n  </release>\n", xml_literal($r->version)
	}
	printf {$fh} "  <programming-language>%s</programming-language>\n", xml_literal("Perl");
	printf {$fh} "</Project>\n";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

RDF::DOAP::Lite - write DOAP data quickly and easily

=head1 SYNOPSIS

   use CPAN::Changes;
   use CPAN::Meta;
   use RDF::DOAP::Lite;
   
   my $changes = CPAN::Changes->load('Changes');
   my $meta    = CPAN::Meta->load_file('META.json');
   my $doap    = RDF::DOAP::Lite->new(meta => $meta, changes => $changes);
   
   $doap->doap_ttl('doap.ttl');
   $doap->doap_xml('doap.xml');

=head1 DESCRIPTION

This is a small companion module to L<RDF::DOAP>, enabling you to
output DOAP data easily from standard CPAN distribution files.

=head2 The Straight DOAP

So what is DOAP? This explanation is lifted from
L<Wikipedia|http://en.wikipedia.org/wiki/DOAP>.

I<< DOAP (Description of a Project) is an RDF Schema and XML vocabulary
to describe software projects, in particular free and open source
software. >>

I<< It was created and initially developed by Edd Dumbill to convey
semantic information associated with open source software projects. >>

I<< It is currently used in the Mozilla Foundation's project page and
in several other software repositories, notably the Python Package
Index. >>

=head2 Constructor

=over

=item C<< new(%attributes) >>

Moose-style constructor (though this module does not use L<Moose>).

=back

=head2 Attributes

=over

=item C<< meta >>

This is a required attribute; a L<CPAN::Meta> object.

=item C<< changes >>

This is an optional attribute; a L<CPAN::Changes> object.

=back

=head2 Methods

=over

=item C<< doap_ttl($file) >>

Writes DOAP data in the Turtle serialization to the file. The file may
be provided as a filename (string) or a file handle.

=item C<< doap_xml($file) >>

Writes DOAP data in the RDF/XML serialization to the file. The file may
be provided as a filename (string) or a file handle.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-DOAP-Lite>.

=head1 SEE ALSO

This module comes with a bundled command-line tool, L<cpan2doap>.

For parsing DOAP data, see L<RDF::DOAP>.

For general RDF processing, use L<RDF::Trine> and L<RDF::Query>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

