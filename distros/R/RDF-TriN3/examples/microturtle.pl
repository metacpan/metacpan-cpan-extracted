#!/usr/bin/perl
# -*- coding: utf-8 -*-

use 5.010;
use utf8;
use RDF::TriN3;
use RDF::Trine qw[iri blank literal statement];
use RDF::Trine::Namespace qw[rdf rdfs owl xsd];
my $foaf = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
my $tags = RDF::Trine::Namespace->new('http://www.holygoat.co.uk/owl/redwood/0.1/tags/');

my $n3 = <<'NOTATION3';

<> tagged #bar .

##foo gist #baz .

@tai says "Phooey" ; ❤ @alci  ; :born 1980-06-01 .

NOTATION3

{
	my (%person, %hashtag);
	
	sub cb_person
	{
		my ($lit, $cb) = @_;
		
		if ($lit->literal_value =~ /^\@(.+)$/)
		{
			my $nick = literal($1);
			unless (defined $person{$1})
			{
				$person{$1} = blank();
				$cb->(statement($person{$1}, $rdf->type, $foaf->Person));
				$cb->(statement($person{$1}, $foaf->nick, $nick));
			}
			return $person{$1};
		}
		
		return;
	}
	
	sub cb_hashtag
	{
		my ($lit, $cb) = @_;
		
		if ($lit->literal_value =~ /^\#(.+)$/)
		{
			my $label = literal($1);
			unless (defined $hashtag{$1})
			{
				$hashtag{$1} = blank();
				$cb->(statement($hashtag{$1}, $rdf->type, $tags->Tag));
				$cb->(statement($hashtag{$1}, $tags->name, $label));
			}
			return $hashtag{$1};
		}
		
		return;
	}
}

my $parser = RDF::Trine::Parser::ShorthandRDF->new(
	profile     => '@import <http://buzzword.org.uk/2009/microturtle/profile.n3x> .',
	datatype_callback => {
		'http://buzzword.org.uk/2009/microturtle/person'  => \&cb_person,
		'http://buzzword.org.uk/2009/microturtle/hashtag' => \&cb_hashtag,
		});

$parser->parse('http://example.org/', $n3, sub {say $_[0]->sse});
