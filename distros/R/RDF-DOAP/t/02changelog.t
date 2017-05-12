=pod

=encoding utf-8

=head1 PURPOSE

Parse some Turtle and create a changelog file.

On the surface this seems to just be testing a few methods, but under
the hood, an awful lot of stuff is getting done, and has to all come
together perfectly to produce the result.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::LongString;

use RDF::DOAP;
use RDF::Trine;

my $model = 'RDF::Trine::Model'->temporary_model;
'RDF::Trine::Parser::Turtle'->new->parse_file_into_model('http://localhost/', \*DATA, $model);
my $proj = 'RDF::DOAP'->from_model($model)->project;

is_string($proj->changelog, <<'OUTPUT', 'changelog as expected'); done_testing;
MooX-ClassAttribute
===================

Created:      2012-12-27
Home page:    <https://metacpan.org/release/MooX-ClassAttribute>
Bug tracker:  <http://rt.cpan.org/Dist/Display.html?Queue=MooX-ClassAttribute>
Maintainer:   Toby Inkster (TOBYINK) <tobyink@cpan.org>

0.008	2013-07-10

 [ Bug Fixes ]
 - Support non-coderef defaults.
   Fixes RT#87638.
   Rob Bloodgood++
   <https://rt.cpan.org/Ticket/Display.html?id=87638>

 [ Packaging ]
 - Switch to Dist::Inkt.

0.007	2013-07-10

 [ Bug Fixes ]
 - Fixed error: Can't call method "isa" on an undefined value at
   MooX/CaptainHook.pm line 27.
   Fixes RT#86828.
   Dinis Rebolo++
   <https://rt.cpan.org/Ticket/Display.html?id=86828>

 [ Documentation ]
 - Note incompatibility with Moo 1.001000.

0.006	2013-01-11

 [ Bug Fixes ]
 - Avoid triggering an 'in cleanup' error on some older versions of Perl.

0.005	2013-01-05

 - Avoid triggering Sub::Exporter::Progressive's dependency on
   Sub::Exporter.

0.004	2013-01-03

 [ Bug Fixes ]
 - Fix MooX::CaptainHook on_inflation fragility when Moose is loaded early.

0.003	2013-01-03

 [ Bug Fixes ]
 - Prevent MooX::CaptainHook from inadvertantly loading Moose.

0.002	2013-01-01

 [ Packaging ]
 - List dependencies.

0.001	2013-01-01	Initial release
OUTPUT
__DATA__

@prefix dc:    <http://purl.org/dc/terms/> .
@prefix doap:  <http://usefulinc.com/ns/doap#> .
@prefix doap-bugs: <http://ontologi.es/doap-bugs#> .
@prefix doap-changeset: <http://ontologi.es/doap-changeset#> .
@prefix doap-deps: <http://ontologi.es/doap-deps#> .
@prefix foaf:  <http://xmlns.com/foaf/0.1/> .
@prefix nfo:   <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .

<http://dev.perl.org/licenses/>
	dc:title             "the same terms as the perl 5 programming language system itself".

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/project>
	a                    doap:Project;
	dc:contributor       <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap-deps:develop-requirement [
		doap-deps:on "MooseX::ClassAttribute"^^doap-deps:CpanId;
	];
	doap-deps:runtime-recommendation [
		doap-deps:on "MooseX::ClassAttribute"^^doap-deps:CpanId;
	];
	doap-deps:runtime-requirement [ doap-deps:on "Moo 1.000000"^^doap-deps:CpanId ], [
		doap-deps:on "Role::Tiny 1.000000"^^doap-deps:CpanId;
	], [
		doap-deps:on "Sub::Exporter::Progressive"^^doap-deps:CpanId;
	];
	doap:bug-database    <http://rt.cpan.org/Dist/Display.html?Queue=MooX-ClassAttribute>;
	doap:created         "2012-12-27"^^xsd:date;
	doap:developer       <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:download-page   <https://metacpan.org/release/MooX-ClassAttribute>;
	doap:homepage        <https://metacpan.org/release/MooX-ClassAttribute>;
	doap:license         <http://dev.perl.org/licenses/>;
	doap:maintainer      <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:name            "MooX-ClassAttribute";
	doap:programming-language "Perl";
	doap:release         <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-001>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-002>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-003>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-004>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-005>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-006>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-007>, <http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-008>;
	doap:repository      [
		a doap:GitRepository;
		doap:browse <https://github.com/tobyink/p5-moox-classattribute>;
	];
	doap:shortdesc       "declare class attributes Moose-style... but without Moose".

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-001>
	a                    doap:Version;
	rdfs:label           "Initial release";
	dc:identifier        "MooX-ClassAttribute-0.001"^^xsd:string;
	dc:issued            "2013-01-01"^^xsd:date;
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.001.tar.gz>;
	doap:revision        "0.001"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-002>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.002"^^xsd:string;
	dc:issued            "2013-01-01"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			a doap-changeset:Packaging;
			rdfs:label "List dependencies.";
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.002.tar.gz>;
	doap:revision        "0.002"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-003>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.003"^^xsd:string;
	dc:issued            "2013-01-03"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			a doap-changeset:Bugfix;
			rdfs:label "Prevent MooX::CaptainHook from inadvertantly loading Moose.";
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.003.tar.gz>;
	doap:revision        "0.003"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-004>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.004"^^xsd:string;
	dc:issued            "2013-01-03"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			a doap-changeset:Bugfix;
			rdfs:label "Fix MooX::CaptainHook on_inflation fragility when Moose is loaded early.";
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.004.tar.gz>;
	doap:revision        "0.004"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-005>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.005"^^xsd:string;
	dc:issued            "2013-01-05"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			rdfs:label "Avoid triggering Sub::Exporter::Progressive's dependency on Sub::Exporter.";
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.005.tar.gz>;
	doap:revision        "0.005"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-006>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.006"^^xsd:string;
	dc:issued            "2013-01-11"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			a doap-changeset:Bugfix;
			rdfs:label "Avoid triggering an 'in cleanup' error on some older versions of Perl.";
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.006.tar.gz>;
	doap:revision        "0.006"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-007>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.007"^^xsd:string;
	dc:issued            "2013-07-10"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			a doap-changeset:Bugfix;
			rdfs:label "Fixed error: Can't call method \"isa\" on an undefined value at MooX/CaptainHook.pm line 27.";
			doap-changeset:blame <http://purl.org/NET/cpan-uri/person/drebolo>;
			doap-changeset:fixes <http://purl.org/NET/cpan-uri/rt/ticket/86828>;
		], [
			a doap-changeset:Documentation;
			rdfs:label "Note incompatibility with Moo 1.001000.";
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.007.tar.gz>;
	doap:revision        "0.007"^^xsd:string.

<http://purl.org/NET/cpan-uri/dist/MooX-ClassAttribute/v_0-008>
	a                    doap:Version;
	dc:identifier        "MooX-ClassAttribute-0.008"^^xsd:string;
	dc:issued            "2013-07-10"^^xsd:date;
	doap-changeset:changeset [
		doap-changeset:item [
			a doap-changeset:Packaging;
			rdfs:label "Switch to Dist::Inkt.";
		], [
			a doap-changeset:Bugfix;
			rdfs:label "Support non-coderef defaults.";
			doap-changeset:fixes <http://purl.org/NET/cpan-uri/rt/ticket/87638>;
			doap-changeset:thanks [
				a foaf:Person;
				foaf:mbox <mailto:rob@exitexchange.com>;
				foaf:name "Rob Bloodgood";
			];
		];
	];
	doap-changeset:released-by <http://purl.org/NET/cpan-uri/person/tobyink>;
	doap:file-release    <http://backpan.cpan.org/authors/id/T/TO/TOBYINK/MooX-ClassAttribute-0.008.tar.gz>;
	doap:revision        "0.008"^^xsd:string.

<http://purl.org/NET/cpan-uri/person/drebolo>
	a                    foaf:Person;
	foaf:name            "Dinis Rebolo";
	foaf:nick            "DREBOLO";
	foaf:page            <https://metacpan.org/author/DREBOLO>.

<http://purl.org/NET/cpan-uri/person/mauke>
	a                    foaf:Person;
	foaf:name            "Lukas Mai";
	foaf:nick            "MAUKE";
	foaf:page            <https://metacpan.org/author/MAUKE>.

<http://purl.org/NET/cpan-uri/person/tobyink>
	a                    foaf:Person;
	foaf:mbox            <mailto:tobyink@cpan.org>;
	foaf:name            "Toby Inkster";
	foaf:nick            "TOBYINK";
	foaf:page            <https://metacpan.org/author/TOBYINK>.

<http://purl.org/NET/cpan-uri/rt/ticket/86828>
	a                    doap-bugs:Issue;
	doap-bugs:id         "86828"^^xsd:string;
	doap-bugs:page       <https://rt.cpan.org/Ticket/Display.html?id=86828>;
	doap-bugs:reporter   <http://purl.org/NET/cpan-uri/person/mauke>.

<http://purl.org/NET/cpan-uri/rt/ticket/87638>
	a                    doap-bugs:Issue;
	doap-bugs:id         "87638"^^xsd:string;
	doap-bugs:page       <https://rt.cpan.org/Ticket/Display.html?id=87638>.

[]
	a                    nfo:FileDataObject;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	nfo:fileName         "meta/people.pret".

[]
	a                    nfo:FileDataObject, nfo:TextDocument;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	dc:source            [
		a nfo:FileDataObject, nfo:SourceCode;
		rdfs:label "MooX::ClassAttribute";
		nfo:fileName "lib/MooX/ClassAttribute.pm";
		nfo:programmingLanguage "Perl";
	];
	nfo:fileName         "README".

[]
	a                    nfo:FileDataObject, nfo:TextDocument;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	dc:source            [
		a nfo:FileDataObject;
		nfo:fileName "meta/changes.pret";
	];
	nfo:fileName         "Changes".

[]
	a                    nfo:FileDataObject, nfo:SourceCode;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	nfo:fileName         "Makefile.PL";
	nfo:programmingLanguage "Perl".

[]
	a                    nfo:FileDataObject;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	nfo:fileName         "meta/changes.pret".

[]
	a                    nfo:FileDataObject;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	nfo:fileName         "meta/copyright.pret".

[]
	a                    nfo:FileDataObject;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	nfo:fileName         "meta/doap.pret".

[]
	a                    nfo:FileDataObject;
	dc:license           <http://dev.perl.org/licenses/>;
	dc:rightsHolder      <http://purl.org/NET/cpan-uri/person/tobyink>;
	nfo:fileName         "meta/makefile.pret".
