=pod

=encoding utf-8

=head1 PURPOSE

Serialize a smiple graph with a few different combinations of options and
check that output is byte-by-byte perfect.

Then check that parsing the serialized graph results in a graph isomorphic
to the input. Graph isomorphism is slow. Sorry.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
	*is_string = eval { require Test::LongString }
		? \&Test::LongString::is_string
		: \&Test::More::is;
};

use Encode qw( encode decode );
use JSON qw( to_json -convert_blessed_universally );
use RDF::Trine;
use Unicode::Normalize qw( NFD );
use match::smart qw(match);

require RDF::Trine::Graph;
require RDF::Trine::Model;
require RDF::Trine::Parser::Turtle;
require RDF::Trine::Serializer::Turtle;
require RDF::TrineX::Serializer::MockTurtleSoup;

require RDF::Prefixes;
plan match("RDF::Prefixes"->VERSION, [qw(0.003 0.004)])
	? (tests => 3)
	: (skip_all => "tests designed for RDF::Prefixes 0.003/0.004");

sub check
{
	my ($input, $opts, $expected) = @_;
	
	my $do_str_test = !!delete($opts->{str_test});
	my $prio = delete($opts->{priorities}) and $opts->{priorities} = 1;
	
	subtest sprintf("testing with opts %s", to_json($opts, {canonical=>1,convert_blessed=>1})), sub
	{
		plan tests => ($do_str_test ? 2 : 1);
		
		my $mts = "RDF::TrineX::Serializer::MockTurtleSoup"->new(%$opts, priorities => $prio);
		my $got = $mts->serialize_model_to_string($input);
		
		is_string(
			NFD(decode("utf8", $got)),
			NFD($expected),
			"serialized string matches",
		) if $do_str_test;
		
		my $model = "RDF::Trine::Model"->new;
		"RDF::Trine::Parser::Turtle"->new->parse_into_model(
			"http://localhost/",
			RDF::Trine->VERSION ge "1.004" ? decode("utf8", $got) : $got,
			$model,
		);
		
		my $g1 = "RDF::Trine::Graph"->new($input);
		my $g2 = "RDF::Trine::Graph"->new($model);
		ok($g1->equals($g2), "graphs are isomorphic");
	};
}

my $model = "RDF::Trine::Model"->new;
"RDF::Trine::Parser::Turtle"->new->parse_file_into_model(
	"http://localhost/",
	\*DATA,
	$model,
);

check($model, { str_test => 1, indent => "   " }, <<'OUTPUT');
@prefix dc:    <http://purl.org/dc/terms/> .
@prefix doap:  <http://usefulinc.com/ns/doap#> .
@prefix foaf:  <http://xmlns.com/foaf/0.1/> .
@prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .

<http://dev.perl.org/licenses/>
   dc:title             "the same terms as the perl 5 programming language system itself".

<http://purl.org/NET/cpan-uri/dist/RDF-TrineX-Serializer-MockTurtleSoup/project>
   a                    doap:Project;
   doap:bug-database    <http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Serializer-MockTurtleSoup>;
   doap:created         "2013-03-15"^^xsd:date;
   doap:developer       <http://purl.org/NET/cpan-uri/person/tobyink>;
   doap:download-page   <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup>;
   doap:homepage        <https://metacpan.org/module/RDF::TrineX::Serializer::MockTurtleSoup>, <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup>;
   doap:license         <http://dev.perl.org/licenses/>;
   doap:maintainer      <http://purl.org/NET/cpan-uri/person/tobyink>;
   doap:name            "RDF-TrineX-Serializer-MockTurtleSoup";
   doap:programming-language "Perl";
   doap:shortdesc       "he's a bit slow, but he's sure good lookin'";
   doap:xxx1            "foo\"bar";
   doap:xxx2            "foo'bar";
   doap:xxx3            "café".

<http://purl.org/NET/cpan-uri/person/tobyink>
   a                    foaf:Person;
   foaf:nick            "TOBYINK";
   foaf:page            <https://metacpan.org/author/TOBYINK>.

OUTPUT

check($model, {
	str_test   => 1,
	indent     => "\t",
	colspace   => 0,
	abbreviate => qr(cpan-uri),
	labelling  => qr((?:title|name)$),
	encoding   => "ascii",
	namespaces => { prj => 'http://purl.org/NET/cpan-uri/dist/RDF-TrineX-Serializer-MockTurtleSoup/' }
}, <<'OUTPUT');
@prefix dc:    <http://purl.org/dc/terms/> .
@prefix doap:  <http://usefulinc.com/ns/doap#> .
@prefix foaf:  <http://xmlns.com/foaf/0.1/> .
@prefix person: <http://purl.org/NET/cpan-uri/person/> .
@prefix prj:   <http://purl.org/NET/cpan-uri/dist/RDF-TrineX-Serializer-MockTurtleSoup/> .
@prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .

<http://dev.perl.org/licenses/>
	dc:title "the same terms as the perl 5 programming language system itself".

prj:project
	a doap:Project;
	doap:name "RDF-TrineX-Serializer-MockTurtleSoup";
	doap:bug-database <http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Serializer-MockTurtleSoup>;
	doap:created "2013-03-15"^^xsd:date;
	doap:developer person:tobyink;
	doap:download-page <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup>;
	doap:homepage <https://metacpan.org/module/RDF::TrineX::Serializer::MockTurtleSoup>, <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup>;
	doap:license <http://dev.perl.org/licenses/>;
	doap:maintainer person:tobyink;
	doap:programming-language "Perl";
	doap:shortdesc "he's a bit slow, but he's sure good lookin'";
	doap:xxx1 "foo\"bar";
	doap:xxx2 "foo'bar";
	doap:xxx3 "caf\u00E9".

person:tobyink
	a foaf:Person;
	foaf:nick "TOBYINK";
	foaf:page <https://metacpan.org/author/TOBYINK>.

OUTPUT

check($model, {
	str_test   => 1,
	indent     => "   ",
	repeats    => 1,
	priorities => sub { return 100 if $_[1] =~ /tobyink/; return; },
}, <<'OUTPUT');
@prefix dc:    <http://purl.org/dc/terms/> .
@prefix doap:  <http://usefulinc.com/ns/doap#> .
@prefix foaf:  <http://xmlns.com/foaf/0.1/> .
@prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .

<http://purl.org/NET/cpan-uri/person/tobyink>
   a                    foaf:Person;
   foaf:nick            "TOBYINK";
   foaf:page            <https://metacpan.org/author/TOBYINK>.

<http://dev.perl.org/licenses/>
   dc:title             "the same terms as the perl 5 programming language system itself".

<http://purl.org/NET/cpan-uri/dist/RDF-TrineX-Serializer-MockTurtleSoup/project>
   a                    doap:Project;
   doap:bug-database    <http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Serializer-MockTurtleSoup>;
   doap:created         "2013-03-15"^^xsd:date;
   doap:developer       <http://purl.org/NET/cpan-uri/person/tobyink>;
   doap:download-page   <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup>;
   doap:homepage        <https://metacpan.org/module/RDF::TrineX::Serializer::MockTurtleSoup>;
   doap:homepage        <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup>;
   doap:license         <http://dev.perl.org/licenses/>;
   doap:maintainer      <http://purl.org/NET/cpan-uri/person/tobyink>;
   doap:name            "RDF-TrineX-Serializer-MockTurtleSoup";
   doap:programming-language "Perl";
   doap:shortdesc       "he's a bit slow, but he's sure good lookin'";
   doap:xxx1            "foo\"bar";
   doap:xxx2            "foo'bar";
   doap:xxx3            "café".

OUTPUT

__DATA__
<http://dev.perl.org/licenses/> <http://purl.org/dc/terms/title> "the same terms as the perl 5 programming language system itself" .
<http://purl.org/NET/cpan-uri/dist/RDF-TrineX-Serializer-MockTurtleSoup/project> <http://usefulinc.com/ns/doap#bug-database> <http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Serializer-MockTurtleSoup> ;
	<http://usefulinc.com/ns/doap#created> "2013-03-15"^^<http://www.w3.org/2001/XMLSchema#date> ;
	<http://usefulinc.com/ns/doap#developer> <http://purl.org/NET/cpan-uri/person/tobyink> ;
	<http://usefulinc.com/ns/doap#download-page> <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup> ;
	<http://usefulinc.com/ns/doap#homepage> <https://metacpan.org/release/RDF-TrineX-Serializer-MockTurtleSoup> ;
	<http://usefulinc.com/ns/doap#homepage> <https://metacpan.org/module/RDF::TrineX::Serializer::MockTurtleSoup> ;
	<http://usefulinc.com/ns/doap#license> <http://dev.perl.org/licenses/> ;
	<http://usefulinc.com/ns/doap#maintainer> <http://purl.org/NET/cpan-uri/person/tobyink> ;
	<http://usefulinc.com/ns/doap#name> "RDF-TrineX-Serializer-MockTurtleSoup" ;
	<http://usefulinc.com/ns/doap#programming-language> "Perl" ;
	<http://usefulinc.com/ns/doap#shortdesc> "he's a bit slow, but he's sure good lookin'" ;
	<http://usefulinc.com/ns/doap#xxx1> "foo\"bar" ;
	<http://usefulinc.com/ns/doap#xxx2> "foo'bar" ;
	<http://usefulinc.com/ns/doap#xxx3> "caf\u00e9" ;
	a <http://usefulinc.com/ns/doap#Project> .
<http://purl.org/NET/cpan-uri/person/tobyink> a <http://xmlns.com/foaf/0.1/Person> ;
	<http://xmlns.com/foaf/0.1/nick> "TOBYINK" ;
	<http://xmlns.com/foaf/0.1/page> <https://metacpan.org/author/TOBYINK> .
