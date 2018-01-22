package RDF::LinkedData::RWHypermedia;

use 5.010001;
use strict;
use warnings;


use Moo;
use Types::Standard qw(Str HashRef);
use RDF::Trine qw(iri statement literal blank);
use RDF::Trine::Parser;
use Try::Tiny;
use Data::Dumper;

extends 'RDF::LinkedData';

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';



=pod

=encoding utf-8

=head1 NAME

RDF::LinkedData::RWHypermedia - Experimental read-write hypermedia support for Linked Data

=head1 SYNOPSIS

This module extends L<RDF::LinkedData>, and you would most likely not
call this module directly, but rather configure it using the tools
that L<RDF::LinkedData> provides.

=head1 DESCRIPTION

This module is an experiment to manipulate Linked Data using human and
machine readable hypermedia descriptions. The intention is to have
messages that are intuitive to newcomers, so that they can get going
using it without much training. For now, it has very basic,
prototypical functionality, but it represents an implementation of an
idea that the author thinks is worth discussing.

To use it, please see the README of L<RDF::LinkedData>. To that configuration, add the two options

    "class" : "RDF::LinkedData::RWHypermedia",
    "writes_enabled" : 1,

Also, hypermedia is on by default, ensure that it isn't turned off.

Then, start the server as you would with L<Plack::App::RDF::LinkedData>.

=head2 Behaviour

In addition to the behaviour documented in
L<Plack::App::RDF::LinkedData>, this module will add a predicate to
any data about a certain resource that tells the user it can check a
certain URI to see if it may edit the resource description. If the
user goes there, they will be challenged to authenticate, and if
authorized (currently, an authenticated user has all privileges), they
will be shown how to edit the resource description.

Extending the examples of L<Plack::App::RDF::LinkedData>,
C<http://host.name/rdf/example/data> points to
C<http://host.name/rdf/example/controls>, which when authorized, shows
the users triples like

  <http://host.name/rdf/example/data> hm:canBe hm:replaced .

thus encouraging the user to replace the data with a new resource
description. The idea is further that C<hm:replaced> can be defined
with protocol-specific semantics, for example that in HTTP, it means
that the user may PUT data in an RDF format to the URL.

=head2 TODO

The idea is also that this approach should be extended to support
different identity (WebID is an obvious candidate) and authorization
regimes (I started implementing the W3C access control lists ontology,
but found it more urgent to get the hypermedia ideas
coded). Eventually, I think this approach should reach parity with the
Linked Data Platform, but without an out-of-band specification.


=head1 METHODS AND ATTRIBUTES

=over

=item C<< response >>

This module wraps L<RDF::LinkedData>s C<response> method, taking
control of write methods and data to be added to the response for
controls and data. The latter is achieved by also wrapping the private
C<_content> method.

=item C<< user >>

Can be read or set to the username of the logged in user.

=item C<< is_logged_in >> 

Indicates whether a user is logged in.

=item C<< log_out >> 

Log out user.

=item C<< add_rw_pointer ($hypermedia_model, $uri) >>

A method that will add a triple to the data page for the given URI to the model building the hypermedia of the response.

=item C<< credentials_ok >>, C<< unauthorized >>, C<< authenticator >>, C<< credentials >>

Methods that deals with authentication and authorization. This part is
really not stable, just for demo purposes at present. The last is
currently a hashref so that a configured username and password can be
passed to the authenticator.



=back

=cut


around 'response' => sub {
  my $orig = shift;
  my $self = shift;
  my @params = @_;
  my $uri = URI->new(shift);
  my $req = $self->request;
  my $response = Plack::Response->new;

  if (defined($req->user)) {
	 $self->user($req->user);
	 $self->log->debug('Setting username: ' . $self->user);
  } else {
	 if ($self->is_logged_in) {
		$self->log->debug('Logging out ' . $self->user);
		$self->log_out;
	 } else {
		$self->log->debug('No username supplied');
	 }
  }
  
  my $node = $self->my_node($uri);
  $self->log->trace("Type passed to " . ref($self) .": '" . $self->type . "'.");
  if ($self->count($node) > 0) { # All resources that can be edited have triples that can be counted, let others be dealt with by orig
  
	 unless (($self->type eq 'data') || $self->does_read_operation) {
		$response->status(405);
		$response->headers->content_type('text/plain');
		$response->body("HTTP 405: Method not allowed.\nWrites can only be done against data information resources, not " . $self->type . ".\nTry getting ./controls\n");
		return $response;
	 }
	 
	 if ($self->type eq 'controls') {
		if ($self->writes_enabled) {
		  $self->log->info("Controls for writes for subject node: " . $node->as_string);
		  $self->log->debug('User is ' . $self->user);
		  $self->credentials_ok;
		  return $self->unauthorized($response) unless ($self->is_logged_in)
		} else {
		  $response->status(403);
		  $response->headers->content_type('text/plain');
		  $response->body("HTTP 403: Forbidden.\nServer is configured without writes.");
		  return $response;
		}
	 }
	 
	 if (($self->type eq 'data') && (! $self->does_read_operation)) {
		$self->log->trace("Attempting write");
		$self->credentials_ok;
		if ($self->is_logged_in) {
		  $self->log->debug('Writing with logged in user: ' . $self->user);
		  if ($req->method eq 'DELETE') {
			 $self->log->debug('Deleting triples with subject ' . $node->as_string);
			 $self->model->remove_statements($node);
			 $response->status(204);
			 return $response;
		  }
		  if (($req->method eq 'POST') or ($req->method eq 'PUT')) {
			 $self->log->debug('Prepare to add triples with media type ' . $req->content_type . ' and subject ' . $node->as_string);
			 my $parser = RDF::Trine::Parser->parser_by_media_type($req->content_type);
			 unless (defined($parser)) {
				$response->status(415);
				$response->headers->content_type('text/plain');
				$response->body("HTTP 415: Unknown format.\nThis host cannot parse the RDF format you supplied, please try a different serialisation");
				return $response;
			 }
			 my $inputmodel = RDF::Trine::Model->temporary_model;
			 $self->log->trace("Got message body:\n". $req->content);
			 try {
				$parser->parse_into_model($self->base_uri, $req->content, $inputmodel);
			 } catch {
				$response->status(400);
				$response->headers->content_type('text/plain');
				$response->body("HTTP 400: Bad Request.\nCouldn't parse your content, got error\n$_");
				return $response;
			 };
			 my $iter = $inputmodel->get_statements($node);
			 unless (defined($iter->peek)) {
				$self->log->debug('Found no triples for subject ' . $node->as_string);
				$response->status(403); # DISCUSS: Error code to send when no triples were added. 409?
				$response->headers->content_type('text/plain');
				$response->body("HTTP 403 Forbidden\nNo triples with the same subject as the resource were found in your request.");
				return $response;
			 }
			 if ($req->method eq 'PUT') {
				$self->log->debug('But first, we delete triples with subject ' . $node->as_string);
				$self->model->remove_statements($node);
			 }
			 my $addcount = 0;
			 # DISCUSS: How should we merge? Just subjects? And objects? Blank nodes, CBD-ish?
			 # DISCUSS: Validation? SHACL? Other validation?
			 while (my $st = $iter->next) {
				$addcount++;
				$self->model->add_statement($st);
			 }
			 my $discarded = $inputmodel->size - $addcount;
			 $self->log->info("Discarded $discarded triples from input data") if ($discarded);
			 
			 # DISCUSS: Nature of response. Purely rely on HTTP semantics and human readable feedback? RDFa+Human readable? No human readable feedback?
			 $response->status(200);
			 $response->headers->content_type('text/plain');
			 my $body = 'HTTP 200: Success.';
			 if ($discarded) {
				$body .= "\nHowever, $discarded triples were discarded from the input\nas they did not have the same subject as the target resources.";
				$response->body($body);
			 }
			 return $response;
		  }
		  $response->status(405);
		  $response->headers->content_type('text/plain');
		  $response->body("HTTP 405: Method not implemented");
		  return $response;
		} else {
		  return $self->unauthorized($response);
		}
	 }
  }
  return $orig->($self, @params);
};


around '_content' => sub {
 	my $orig = shift;
 	my $self = shift;
	my @params = @_;
	my $node = shift;
	my $type = shift;
	
	if ($type eq 'controls') {
		$self->log->debug('We generate a response for RW hypermedia controls');
		if ($self->writes_enabled) {
			my %output;
			my $rwmodel = RDF::Trine::Model->temporary_model;
			my $headers_in = $self->request->headers;
			$self->log->trace('Full headers we respond to: ' . $headers_in->as_string);
			
			my $data_iri = iri($node->uri_value . '/data');
			my $controls_iri = iri($node->uri_value . '/controls');
			$self->add_namespace_mapping(hm => 'http://example.org/hypermedia#');
			$self->guess_namespaces('rdf', 'void', 'rdfs');
			$self->add_namespace_mapping(hydra => 'http://www.w3.org/ns/hydra/core#');
			
			my $hm = $self->namespaces->hm;
			my $rdfs = $self->namespaces->rdfs;
			
			if ($self->is_logged_in) { # Credentials should already have been checked
			  $self->log->debug('Logged in as: ' . $self->user);
			  
			  # TODO: Check ACL
			  $rwmodel->add_statement(statement($controls_iri,
															iri($self->namespaces->rdf->type),
															iri($hm->AffordancesDocument)));
			  $rwmodel->add_statement(statement($controls_iri,
															iri($rdfs->comment),
															literal('This document describes what you can do in terms of write operations on ' . $data_iri->uri_value, 'en')));
			  $rwmodel->add_statement(statement($controls_iri,
															iri($hm->for),
															$data_iri));
			  $rwmodel->add_statement(statement($data_iri,
															iri($hm->canBe),
															iri($hm->mergedInto)));
			  $rwmodel->add_statement(statement($data_iri,
															iri($hm->canBe),
															iri($hm->replaced)));
			  $rwmodel->add_statement(statement($data_iri,
															iri($hm->canBe),
															iri($hm->deleted)));

			  # Add more definitions of state change operations
			  $rwmodel->add_statement(statement(iri($hm->deleted),
															iri($rdfs->comment),
															literal('Delete the resource description with the subject URI.', 'en'))
														  );
			  $rwmodel->add_statement(statement(iri($hm->deleted),
															iri($hm->httpMethod),
															literal('DELETE')));

			  $rwmodel->add_statement(statement(iri($hm->replaced),
															iri($rdfs->comment),
															literal('Replace the resource description with the subject URI with the RDF given in the body of the message.', 'en'))
														  );
			  $rwmodel->add_statement(statement(iri($hm->replaced),
															iri($hm->httpMethod),
															literal('PUT')));

			  $rwmodel->add_statement(statement(iri($hm->mergedInto),
															iri($rdfs->comment),
															literal('Perform an RDF merge of payload into resource', 'en'))
														  );
			  $rwmodel->add_statement(statement(iri($hm->mergedInto),
															iri($hm->httpMethod),
															literal('POST')));
			  $rwmodel->add_statement(statement(iri($hm->mergedInto),
															iri($rdfs->seeAlso),
															blank('rdfmerge')));
			  $rwmodel->add_statement(statement(blank('rdfmerge'),
															iri($rdfs->label),
															literal('RDF Merge')));
			  $rwmodel->add_statement(statement(blank('rdfmerge'),
															iri($rdfs->isDefinedBy),
															iri('http://www.w3.org/TR/rdf-mt/#graphdefs')));


			  my ($ctype, $s) = RDF::Trine::Serializer->negotiate('request_headers' => $headers_in,
																					base => $self->base_uri,
																					namespaces => $self->_namespace_hashref);
			  $output{content_type} = $ctype;
			  $output{body} = $s->serialize_model_to_string ( $rwmodel );
			} else {
			  # Shouldn't get here
			  die 'No user is logged in, probably a bug';
			}
			
			$self->log->trace("Message body is $output{body}" );

			return \%output
		} else {
			$self->log->warn('Controls were on, but not writes. Strange situation');
		}
	}
	return $orig->($self, @params);
};


has user => ( is => 'rw', isa => Str, lazy => 1, 
				  predicate => 'is_logged_in',
				  clearer => 'log_out'
				);


sub add_rw_pointer {
	my $self = shift;
	my $hmmodel = shift;
	my $uri = shift;
	my $exprefix = 'http://example.org/hypermedia#';
	$hmmodel->add_statement(statement(iri($uri->uri_value . '/data'),
												 iri($exprefix .  'toEditGoTo'),
												 iri($uri->uri_value . '/controls')));
}

# some cutnpaste from https://metacpan.org/source/MIYAGAWA/Plack-1.0045/lib/Plack/Middleware/Auth/Basic.pm

sub credentials_ok {
  my $self = shift;
  my $env = $self->request->env;
  my $auth = $env->{HTTP_AUTHORIZATION}
	 or return 0;
  $self->log->trace("Auth information given: $auth");

  # note the 'i' on the regex, as, according to RFC2617 this is a 
  # "case-insensitive token to identify the authentication scheme"
  if ($auth =~ /^Basic (.*)$/i) {
	 my($user, $pass) = split /:/, (MIME::Base64::decode($1) || ":"), 2;
	 $pass = '' unless defined $pass;
	 if ($self->authenticator($user, $pass, $env)) {
		$env->{REMOTE_USER} = $user;
		$self->user($user);
	 } else {
		return 0;
	 }
  }
  return 1;
}

sub unauthorized {
  my $self = shift;
  my $response = shift;
  my $body = 'Authorization required';
  $response->body($body);
  $response->status(401);
  $response->headers([ 'Content-Type' => 'text/plain',
							  'Content-Length' => length $body,
							  'WWW-Authenticate' => 'Basic realm="restricted area"' ]);
  return $response;
}

has credentials => (is => 'ro', isa => HashRef);

sub authenticator {
  my ($self, $user, $pass, $env) = @_;
  my $cred = $self->credentials;
  return ($user eq $cred->{username} && $pass eq $cred->{password});
}


=head1 FEEDBACK

Since this is a prototype, I hope this will spark discussion. There
are some discussion items inline in the code. They include how and
what data should be merged to a given URL, what the responses should
look like.

Apart from comments to my email, the IRC channels
L<irc://irc.perl.org/#perlrdf> and L<irc://irc.freenode.net/#swig> are
good forums for discussing this topic.

I will be blogging about this work at
L<http://kjetil.kjernsmo.net/category/technology/hypermedia/>.


=head2 Bugs

Please report any bugs to
L<https://github.com/kjetilk/p5-rdf-linkeddata-rwhypermedia/issues>.

=head2 Author

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017, 2018 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut 

1;
