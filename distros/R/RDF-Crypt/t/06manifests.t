use 5.010;
use strict;
use lib 'lib';
use lib 't/lib';

use RDF::Crypt;
use RDF::TrineX::Functions -all;
use Test::More;

{
	package Test::HTTP::Server::Request;
	sub test1 {
		shift->{out_headers}{content_type} = 'text/turtle';
		'@prefix ex: <http://www.example.com/> .
		<Alice> ex:name "Alice" .
		'
	}
	sub test2 {
		shift->{out_headers}{content_type} = 'text/turtle';
		'@prefix ex: <http://www.example.com/> .
		<Bob> ex:name "Bob" .
		'
	}
	sub test3 {
		shift->{out_headers}{content_type} = 'application/rdf+xml';
		'<rdf:RDF
				xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
				xmlns:ex="http://www.example.com/">
			<rdf:Description rdf:about="Carol">
				<ex:name>Carol</ex:name>
			</rdf:Description>
		</rdf:RDF>
		'
	}
}

eval { require Test::HTTP::Server; 1; }
        or plan skip_all => "Could not use Test::HTTP::Server: $@";

plan tests => 6;

my $server  = Test::HTTP::Server->new();
my $baseuri = $server->uri;

my $key = Crypt::OpenSSL::RSA->generate_key(1024);
my $V   = RDF::Crypt::Verifier->new_from_string($key->get_public_key_string);
my $S   = RDF::Crypt::Signer->new_from_string($key->get_private_key_string);

my $manifest = $S->generate_manifest(
	'http://www.example.com/signer',
	[map { join q(), $baseuri, 'test', $_ } 1..3],
);

isa_ok $manifest, 'RDF::Trine::Model';
note serialize $manifest, as => 'Turtle';

my @results =
	sort { $a->document cmp $b->document }
	$V->verify_manifest($manifest);
note explain \@results;

ok(
	$_->verification,
	"verified @{[ $_->document ]}"
) for @results;

TAMPERING: {
	$manifest->remove_statements(
		blank('sig1'),
		iri('http://ontologi.es/wotox#signature'),
	); # this should totally disappear from results!
	
	$manifest->remove_statements(
		blank('sig2'),
		iri('http://ontologi.es/wotox#signature'),
	);
	$manifest->add_statement(statement(
		blank('sig2'),
		iri('http://ontologi.es/wotox#signature'),
		literal('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
	));
}
note serialize $manifest, as => 'Turtle';

@results =
	sort { $a->document cmp $b->document }
	$V->verify_manifest($manifest);
note explain \@results;

ok(
	!$_->verification,
	"unverified @{[ $_->document ]}"
) for $results[0];

ok(
	$_->verification,
	"verified @{[ $_->document ]}"
) for $results[1];
