package RDF::RDFa::Parser::InitialContext;

use 5.010;
use strict;
no warnings;

BEGIN {
	$RDF::RDFa::Parser::InitialContext::AUTHORITY = 'cpan:TOBYINK';
	$RDF::RDFa::Parser::InitialContext::VERSION   = '1.097';	
}

my @rdfa_10 = qw(
	alternate appendix bookmark cite chapter contents copyright
	first glossary help icon index last license meta next p3pv1 prev
	role section stylesheet subsection start top up
);

my @std_roles = qw(
	banner complementary contentinfo definition main
	navigation note search
);

my @aria_roles = qw(
	alert alertdialog application article button checkbox
	columnheader combobox dialog directory document grid
	gridcell group heading img link list listbox listitem
	log marquee math menu menubar menuitem menuitemcheckbox
	menuitemradio option presentation progressbar radio
	radiogroup region row rowheader separator slider
	spinbutton status tab tablist tabpanel textbox timer
	toolbar tooltip tree treegrid treeitem
);

our %Known = (

	'tag:buzzword.org.uk,2010:rdfa:profile:rdfa-1.0' => {
		map {;
			"$_\@rel" => "http://www.w3.org/1999/xhtml/vocab#$_",
			"$_\@rev" => "http://www.w3.org/1999/xhtml/vocab#$_",
		}
		@rdfa_10
	},
	

	'http://www.w3.org/2011/rdfa-context/rdfa-1.1' => {
		qw(
			grddl:	http://www.w3.org/2003/g/data-view#
			ma:	http://www.w3.org/ns/ma-ont#
			owl:	http://www.w3.org/2002/07/owl#
			rdf:	http://www.w3.org/1999/02/22-rdf-syntax-ns#
			rdfa:	http://www.w3.org/ns/rdfa#
			rdfs:	http://www.w3.org/2000/01/rdf-schema#
			rif:	http://www.w3.org/2007/rif#
			skos:	http://www.w3.org/2004/02/skos/core#
			skosxl:	http://www.w3.org/2008/05/skos-xl#
			wdr:	http://www.w3.org/2007/05/powder#
			void:	http://rdfs.org/ns/void#
			wdrs:	http://www.w3.org/2007/05/powder-s#
			xhv:	http://www.w3.org/1999/xhtml/vocab#
			xml:	http://www.w3.org/XML/1998/namespace
			xsd:	http://www.w3.org/2001/XMLSchema#
		),
		qw(
			cc:	http://creativecommons.org/ns#
			ctag:	http://commontag.org/ns#
			dc:	http://purl.org/dc/terms/
			dcterms:	http://purl.org/dc/terms/
			foaf:	http://xmlns.com/foaf/0.1/
			gr:	http://purl.org/goodrelations/v1#
			ical:	http://www.w3.org/2002/12/cal/icaltzd#
			og:	http://ogp.me/ns#
			rev:	http://purl.org/stuff/rev#
			sioc:	http://rdfs.org/sioc/ns#
			v:	http://rdf.data-vocabulary.org/#
			vcard:	http://www.w3.org/2006/vcard/ns#
			schema:	http://schema.org/
		),
		describedby   => 'http://www.w3.org/2007/05/powder-s#describedby',
		license       => 'http://www.w3.org/1999/xhtml/vocab#license',
		role          => 'http://www.w3.org/1999/xhtml/vocab#role',
	},
	
	'http://www.w3.org/2011/rdfa-context/xhtml-rdfa-1.1' => {
		map {; $_ => "http://www.w3.org/1999/xhtml/vocab#$_" }
		qw(
			alternate appendix cite bookmark contents chapter copyright
			first glossary help icon index last license meta next prev
			previous section start stylesheet subsection top up p3pv1
		)
	},
	
	'http://www.w3.org/2011/rdfa-context/html-rdfa-1.1' => {},
	
	'tag:buzzword.org.uk,2010:rdfa:profile:xhtml-role' => {
		map {; lc("$_\@role") => "http://www.w3.org/1999/xhtml/vocab#$_" }
		@rdfa_10, 'itsRules', @std_roles, @aria_roles,
	},

	'tag:buzzword.org.uk,2010:rdfa:profile:aria-role' => {
		map {; "$_\@role" => "http://www.w3.org/1999/xhtml/vocab#$_" }
		@std_roles, @aria_roles,
	},

	# perl -MWeb::Magic -E'Web::Magic->new("http://www.iana.org/assignments/link-relations/link-relations.xml")->findnodes("//*[local-name()=\"value\"]")->foreach(sub {say $_->textContent})'
	'tag:buzzword.org.uk,2010:rdfa:profile:ietf' => {
		map {;
			"$_\@rel" => "http://www.iana.org/assignments/relation/$_",
			"$_\@rev" => "http://www.iana.org/assignments/relation/$_",
		}
		qw(
			alternate appendix archives author bookmark canonical
			chapter collection contents copyright current describedby
			disclosure duplicate edit edit-media enclosure first
			glossary help hub icon index item last latest-version
			license lrdd monitor monitor-group next next-archive
			nofollow noreferrer payment predecessor-version prefetch
			prev previous prev-archive related replies search section
			self service start stylesheet subsection
			successor-version tag up version-history via
			working-copy working-copy-of
		)
	},
	
	'http://search.yahoo.com/searchmonkey-profile' => {
		qw(
			abmeta:	http://www.abmeta.org/ns#
			action:	http://search.yahoo.com/searchmonkey/action/
			assert:	http://search.yahoo.com/searchmonkey/assert/
			cc:	http://creativecommons.org/ns#
			commerce:	http://search.yahoo.com/searchmonkey/commerce/
			context:	http://search.yahoo.com/searchmonkey/context/
			country:	http://search.yahoo.com/searchmonkey-datatype/country/
			currency:	http://search.yahoo.com/searchmonkey-datatype/currency/
			dbpedia:	http://dbpedia.org/resource/
			dc:	http://purl.org/dc/terms/
			fb:	http://rdf.freebase.com/
			feed:	http://search.yahoo.com/searchmonkey/feed/
			finance:	http://search.yahoo.com/searchmonkey/finance/
			foaf:	http://xmlns.com/foaf/0.1/
			geo:	http://www.georss.org/georss#
			gr:	http://purl.org/goodrelations/v1#
			job:	http://search.yahoo.com/searchmonkey/job/
			media:	http://search.yahoo.com/searchmonkey/media/
			news:	http://search.yahoo.com/searchmonkey/news/
			owl:	http://www.w3.org/2002/07/owl#
			page:	http://search.yahoo.com/searchmonkey/page/
			product:	http://search.yahoo.com/searchmonkey/product/
			rdf:	http://www.w3.org/1999/02/22-rdf-syntax-ns#
			rdfs:	http://www.w3.org/2000/01/rdf-schema#
			reference:	http://search.yahoo.com/searchmonkey/reference/
			rel:	http://search.yahoo.com/searchmonkey-relation/
			resume:	http://search.yahoo.com/searchmonkey/resume/
			review:	http://purl.org/stuff/rev#
			sioc:	http://rdfs.org/sioc/ns#
			social:	http://search.yahoo.com/searchmonkey/social/
			stag:	http://semantictagging.org/ns#
			tagspace:	http://search.yahoo.com/searchmonkey/tagspace/
			umbel:	http://umbel.org/umbel/sc/
			use:	http://search.yahoo.com/searchmonkey-datatype/use/
			vcal:	http://www.w3.org/2002/12/cal/icaltzd#
			vcard:	http://www.w3.org/2006/vcard/ns#
			xfn:	http://gmpg.org/xfn/11#
			xhtml:	http://www.w3.org/1999/xhtml/vocab#
			xsd:	http://www.w3.org/2001/XMLSchema#
		)
	},
	
	'tag:buzzword.org.uk,2010:rdfa:profile:html32' => {
		map {;
			"$_\@rel" => "http://www.w3.org/1999/xhtml/vocab#$_",
			"$_\@rev" => "http://www.w3.org/1999/xhtml/vocab#$_",
		}
		qw(
			top contents index glossary copyright next previous help
			search chapter made
		)
	},
	
	'tag:buzzword.org.uk,2010:rdfa:profile:html4' => {
		map {;
			"$_\@rel" => "http://www.w3.org/1999/xhtml/vocab#$_",
			"$_\@rev" => "http://www.w3.org/1999/xhtml/vocab#$_",
		}
		map {; lc $_ }
		qw(
			Alternate Stylesheet Start Next Prev Contents Index
			Glossary Copyright Chapter Section Subsection Appendix
			Help Bookmark
		)
	},

	'tag:buzzword.org.uk,2010:rdfa:profile:html5' => {
		map {;
			"$_\@rel" => "http://www.w3.org/1999/xhtml/vocab#$_",
			"$_\@rev" => "http://www.w3.org/1999/xhtml/vocab#$_",
		}
		qw(
			alternate archives author bookmark external feed first
			help icon index last license next nofollow noreferrer
			pingback prefetch prev search stylesheet sidebar tag
			up ALTERNATE-STYLESHEET
		)
	},

	'http://www.w3.org/2003/g/data-view' => {
		map {;
			"$_\@rel" => "http://www.w3.org/2003/g/data-view#$_",
			"$_\@rev" => "http://www.w3.org/2003/g/data-view#$_",
		}
		qw(transformation profileTransformation namespaceTransformation)
	},
	
);

sub new
{
	my $class    = shift;
	my @contexts = map { split /\s+/, $_ } @_;
	
	my %self;
	foreach my $ctx (reverse @contexts)
	{
		my %ctx = %{ $Known{$ctx} // +{} };
		while (my ($k, $v) = each %ctx)
		{
			$self{$k} = $v;
		}
	}
	
	bless(\%self, $class);
}

sub uri_mappings
{
	my $self   = shift;
	+{
		map {
			(my $prefix = $_) =~ s/:$//;
			lc $prefix => $self->{$_}
		}
		grep { /:$/ }
		keys %$self
	}
}

sub term_mappings
{
	my $self   = shift;
	my %return;
	
	my @keys = grep { !/:$/ } keys %$self;
	foreach my $key (@keys)
	{
		my ($term, $attr) = split /\@/, $key;
		$attr //= '*';
		$return{$attr}{lc $term} = $self->{$key};
	}
	
	\%return
}

__PACKAGE__
__END__

=head1 NAME

RDF::RDFa::Parser::InitialContext - initially defined lists of prefixes and terms

=head1 DESCRIPTION

This is fairly internal to RDF::RDFa::Parser, but will nevertheless be
documented in due course.

=head1 SEE ALSO

L<RDF::RDFa::Parser>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
