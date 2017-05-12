=pod

=encoding utf-8

=head1 PURPOSE

Test that Syntax::Highlight::RDF compiles.

Also check HTML output for a few syntaxes:

=over

=item *

Turtle

=item *

Pretdsl

=item *

JSON

=item *

XML

=back

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

use_ok("Syntax::Highlight::RDF");

sub check
{
	my ($syntax, $in, $expected) = @_;
	my $got = "Syntax::Highlight::RDF"->highlighter($syntax)->highlight(\$in);
	is_string($got, $expected, "$syntax highlighting");
}

check("Turtle", <<'IN', <<'OUT');
@base <http://www.example.org/> .
@prefix foo: <http://example.com/foo#> .
@prefix quux: <quux#>.

<xyz>
   foo:bar 123;
   foo:baz "Yeah\"Baby\"Yeah";
   foo:bum quux:quuux.
IN
<span class="rdf_atrule">@base</span> <span class="rdf_uriref" data-rdf-uri="http://www.example.org/">&lt;http://www.example.org/&gt;</span> <span class="rdf_punctuation">.</span>
<span class="rdf_prefixdefinition_start" data-rdf-prefix="foo" data-rdf-uri="http://example.com/foo#"><span class="rdf_atrule">@prefix</span> <span class="rdf_curie" data-rdf-prefix="foo" data-rdf-uri="http://example.com/foo#">foo:</span> <span class="rdf_uriref" data-rdf-uri="http://example.com/foo#">&lt;http://example.com/foo#&gt;</span> <span class="rdf_punctuation">.</span></span>
<span class="rdf_prefixdefinition_start" data-rdf-prefix="quux" data-rdf-uri="http://www.example.org/quux#"><span class="rdf_atrule">@prefix</span> <span class="rdf_curie" data-rdf-prefix="quux" data-rdf-uri="http://www.example.org/quux#">quux:</span> <span class="rdf_uriref" data-rdf-uri="http://www.example.org/quux#">&lt;quux#&gt;</span><span class="rdf_punctuation">.</span></span>

<span class="rdf_uriref" data-rdf-uri="http://www.example.org/xyz">&lt;xyz&gt;</span>
   <span class="rdf_curie" data-rdf-prefix="foo" data-rdf-suffix="bar" data-rdf-uri="http://example.com/foo#bar">foo:bar</span> <span class="rdf_number_integer">123</span><span class="rdf_punctuation">;</span>
   <span class="rdf_curie" data-rdf-prefix="foo" data-rdf-suffix="baz" data-rdf-uri="http://example.com/foo#baz">foo:baz</span> <span class="rdf_shortstring">&quot;Yeah\&quot;Baby\&quot;Yeah&quot;</span><span class="rdf_punctuation">;</span>
   <span class="rdf_curie" data-rdf-prefix="foo" data-rdf-suffix="bum" data-rdf-uri="http://example.com/foo#bum">foo:bum</span> <span class="rdf_curie" data-rdf-prefix="quux" data-rdf-suffix="quuux" data-rdf-uri="http://www.example.org/quux#quuux">quux:quuux</span><span class="rdf_punctuation">.</span>
OUT

check("Pretdsl", <<'IN', <<'OUT');
@base <http://www.example.org/> .
@prefix foo: <http://example.com/foo#> .
@prefix quux: <quux#>.

`Foo-Bar`
   label      "Yee-hah!";
   dc:creator cpan:TOBYINK.

`Foo-Bar 0.001`
   issued     2012-02-01.
IN
<span class="rdf_atrule">@base</span> <span class="rdf_uriref" data-rdf-uri="http://www.example.org/">&lt;http://www.example.org/&gt;</span> <span class="rdf_punctuation">.</span>
<span class="rdf_prefixdefinition_start" data-rdf-prefix="foo" data-rdf-uri="http://example.com/foo#"><span class="rdf_atrule">@prefix</span> <span class="rdf_curie" data-rdf-prefix="foo" data-rdf-uri="http://example.com/foo#">foo:</span> <span class="rdf_uriref" data-rdf-uri="http://example.com/foo#">&lt;http://example.com/foo#&gt;</span> <span class="rdf_punctuation">.</span></span>
<span class="rdf_prefixdefinition_start" data-rdf-prefix="quux" data-rdf-uri="http://www.example.org/quux#"><span class="rdf_atrule">@prefix</span> <span class="rdf_curie" data-rdf-prefix="quux" data-rdf-uri="http://www.example.org/quux#">quux:</span> <span class="rdf_uriref" data-rdf-uri="http://www.example.org/quux#">&lt;quux#&gt;</span><span class="rdf_punctuation">.</span></span>

<span class="rdf_pretdsl_perl_dist">`Foo-Bar`</span>
   <span class="rdf_pretdsl_keyword" data-rdf-uri="http://www.w3.org/2000/01/rdf-schema#label">label</span>      <span class="rdf_shortstring">&quot;Yee-hah!&quot;</span><span class="rdf_punctuation">;</span>
   <span class="rdf_curie" data-rdf-prefix="dc" data-rdf-suffix="creator" data-rdf-uri="http://purl.org/dc/terms/creator">dc:creator</span> <span class="rdf_pretdsl_cpanid">cpan:TOBYINK</span><span class="rdf_punctuation">.</span>

<span class="rdf_pretdsl_perl_release">`Foo-Bar 0.001`</span>
   <span class="rdf_pretdsl_keyword" data-rdf-uri="http://purl.org/NET/dc/terms/issued">issued</span>     <span class="rdf_pretdsl_date">2012-02-01</span><span class="rdf_punctuation">.</span>
OUT

check("JSON", <<'IN', <<'OUT');
{
   "http://example.org/about": 
   {
      "http://purl.org/dc/elements/1.1/title":
      [
         { "type": "literal" , "value": "Anna's Homepage" },
         { "type": null, "value": 123.45 }
      ]
   }
}
IN
<span class="json_brace">{</span>
   <span class="json_string">&quot;http://example.org/about&quot;</span><span class="json_punctuation">:</span> 
   <span class="json_brace">{</span>
      <span class="json_string">&quot;http://purl.org/dc/elements/1.1/title&quot;</span><span class="json_punctuation">:</span>
      <span class="json_bracket">[</span>
         <span class="json_brace">{</span> <span class="json_string">&quot;type&quot;</span><span class="json_punctuation">:</span> <span class="json_string">&quot;literal&quot;</span> <span class="json_punctuation">,</span> <span class="json_string">&quot;value&quot;</span><span class="json_punctuation">:</span> <span class="json_string">&quot;Anna&#x27;s Homepage&quot;</span> <span class="json_brace">}</span><span class="json_punctuation">,</span>
         <span class="json_brace">{</span> <span class="json_string">&quot;type&quot;</span><span class="json_punctuation">:</span> <span class="json_keyword">null</span><span class="json_punctuation">,</span> <span class="json_string">&quot;value&quot;</span><span class="json_punctuation">:</span> <span class="json_number_decimal">123.45</span> <span class="json_brace">}</span>
      <span class="json_bracket">]</span>
   <span class="json_brace">}</span>
<span class="json_brace">}</span>
OUT

check("XML", <<'IN', <<'OUT');
<?xml version="1.0"?>
<!DOCTYPE rdf:RDF PUBLIC "-//DUBLIN CORE//DCMES DTD 2002/07/31//EN"
    "http://dublincore.org/documents/2002/07/31/dcmes-xml/dcmes-xml-dtd.dtd">
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:dc="http://purl.org/dc/elements/1.1/">
  <rdf:Description rdf:about="http://www.ilrt.bristol.ac.uk/people/cmdjb/">
    <dc:title>Dave Beckett's Home Page</dc:title>
    <dc:creator>Dave Beckett</dc:creator>
    <dc:publisher>ILRT, University of Bristol</dc:publisher>
    <dc:date>2002-07-31</dc:date>
  </rdf:Description>
</rdf:RDF>
IN
<span class="xml_tag_start xml_tag_is_pi xml_tag_is_opening" data-xml-name="xml"><span class="xml_pointy">&lt;?</span><span class="xml_tagname">xml</span> <span class="xml_attributename">version</span><span class="xml_equals">=</span><span class="xml_attributevalue">&quot;1.0&quot;</span><span class="xml_pointy">?&gt;</span></span>
<span class="xml_tag_start xml_tag_is_doctype xml_tag_is_opening" data-xml-name="DOCTYPE"><span class="xml_pointy">&lt;!</span><span class="xml_tagname">DOCTYPE</span> <span class="xml_attributename">rdf:RDF</span> <span class="xml_attributename">PUBLIC</span> <span class="xml_attributevalue">&quot;-//DUBLIN CORE//DCMES DTD 2002/07/31//EN&quot;</span>
    <span class="xml_attributevalue">&quot;http://dublincore.org/documents/2002/07/31/dcmes-xml/dcmes-xml-dtd.dtd&quot;</span><span class="xml_pointy">&gt;</span></span>
<span class="xml_tag_start xml_tag_is_opening" data-xml-name="rdf:RDF"><span class="xml_pointy">&lt;</span><span class="xml_tagname">rdf:RDF</span> <span class="xml_attribute_start xml_attribute_is_xmlns" data-xml-name="xmlns:rdf"><span class="xml_attributename">xmlns:rdf</span><span class="xml_equals">=</span><span class="xml_attributevalue">&quot;http://www.w3.org/1999/02/22-rdf-syntax-ns#&quot;</span></span>
         <span class="xml_attribute_start xml_attribute_is_xmlns" data-xml-name="xmlns:dc"><span class="xml_attributename">xmlns:dc</span><span class="xml_equals">=</span><span class="xml_attributevalue">&quot;http://purl.org/dc/elements/1.1/&quot;</span></span><span class="xml_pointy">&gt;</span></span>
  <span class="xml_tag_start xml_tag_is_opening" data-xml-name="rdf:Description"><span class="xml_pointy">&lt;</span><span class="xml_tagname">rdf:Description</span> <span class="xml_attribute_start" data-xml-name="rdf:about"><span class="xml_attributename">rdf:about</span><span class="xml_equals">=</span><span class="xml_attributevalue">&quot;http://www.ilrt.bristol.ac.uk/people/cmdjb/&quot;</span></span><span class="xml_pointy">&gt;</span></span>
    <span class="xml_tag_start xml_tag_is_opening" data-xml-name="dc:title"><span class="xml_pointy">&lt;</span><span class="xml_tagname">dc:title</span><span class="xml_pointy">&gt;</span></span><span class="xml_data">Dave Beckett&#x27;s Home Page</span><span class="xml_tag_start xml_tag_is_closing" data-xml-name="dc:title"><span class="xml_pointy">&lt;</span><span class="xml_slash">/</span><span class="xml_tagname">dc:title</span><span class="xml_pointy">&gt;</span></span>
    <span class="xml_tag_start xml_tag_is_opening" data-xml-name="dc:creator"><span class="xml_pointy">&lt;</span><span class="xml_tagname">dc:creator</span><span class="xml_pointy">&gt;</span></span><span class="xml_data">Dave Beckett</span><span class="xml_tag_start xml_tag_is_closing" data-xml-name="dc:creator"><span class="xml_pointy">&lt;</span><span class="xml_slash">/</span><span class="xml_tagname">dc:creator</span><span class="xml_pointy">&gt;</span></span>
    <span class="xml_tag_start xml_tag_is_opening" data-xml-name="dc:publisher"><span class="xml_pointy">&lt;</span><span class="xml_tagname">dc:publisher</span><span class="xml_pointy">&gt;</span></span><span class="xml_data">ILRT, University of Bristol</span><span class="xml_tag_start xml_tag_is_closing" data-xml-name="dc:publisher"><span class="xml_pointy">&lt;</span><span class="xml_slash">/</span><span class="xml_tagname">dc:publisher</span><span class="xml_pointy">&gt;</span></span>
    <span class="xml_tag_start xml_tag_is_opening" data-xml-name="dc:date"><span class="xml_pointy">&lt;</span><span class="xml_tagname">dc:date</span><span class="xml_pointy">&gt;</span></span><span class="xml_data">2002-07-31</span><span class="xml_tag_start xml_tag_is_closing" data-xml-name="dc:date"><span class="xml_pointy">&lt;</span><span class="xml_slash">/</span><span class="xml_tagname">dc:date</span><span class="xml_pointy">&gt;</span></span>
  <span class="xml_tag_start xml_tag_is_closing" data-xml-name="rdf:Description"><span class="xml_pointy">&lt;</span><span class="xml_slash">/</span><span class="xml_tagname">rdf:Description</span><span class="xml_pointy">&gt;</span></span>
<span class="xml_tag_start xml_tag_is_closing" data-xml-name="rdf:RDF"><span class="xml_pointy">&lt;</span><span class="xml_slash">/</span><span class="xml_tagname">rdf:RDF</span><span class="xml_pointy">&gt;</span></span>
OUT

done_testing;

