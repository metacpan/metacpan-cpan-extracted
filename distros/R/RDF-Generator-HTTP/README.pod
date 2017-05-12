package RDF::Generator::HTTP;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.003';

use Moo;
use Carp qw(carp);
use RDF::Trine qw(statement blank iri literal);
use URI::NamespaceMap;
use Types::Standard qw(InstanceOf ArrayRef Str);

has message => (is => 'ro', isa => InstanceOf['HTTP::Message'], required => 1);

has blacklist => (is => 'rw', isa => ArrayRef[Str], predicate => 'has_blacklist');

has whitelist => (is => 'rw', isa => ArrayRef[Str], predicate => 'has_whitelist');

has graph => (is => 'rw', isa => InstanceOf['RDF::Trine::Node::Resource'], predicate => 'has_graph');

has request_subject => (is => 'ro',
								isa => InstanceOf['RDF::Trine::Node'],
								default => sub { return blank });

has response_subject => (is => 'ro',
								 isa => InstanceOf['RDF::Trine::Node'],
								 default => sub { return blank });

has ns => (is => 'ro', isa => InstanceOf['URI::NamespaceMap'], lazy => 1, builder => '_build_namespacemap');

sub _build_namespacemap {
	my $self = shift;
	return URI::NamespaceMap->new({ rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	                                http => 'http://www.w3.org/2007/ont/http#',
	                                httph => 'http://www.w3.org/2007/ont/httph#' });
}


sub generate {
	my $self = shift;	
	my $model = shift || RDF::Trine::Model->temporary_model;
	my $reqsubj = $self->request_subject;
	my $ressubj = $self->response_subject;
	my @graph = $self->has_graph ? ($self->graph) : ();
	my $ns = $self->ns;
	if ($self->message->isa('HTTP::Request')) {
		$self->_request_statements($model, $self->message, $reqsubj);
		$self->message->headers->scan(sub {
			                              my ($field, $value) = @_;
			                              if ($self->ok_to_add($field)) {
				                              $model->add_statement(statement($reqsubj, 
				                                                              iri($ns->httph->uri(_fix_headers($field))), 
				                                                              literal($value),
				                                                              @graph));
			                              }
		                              });
	} elsif ($self->message->isa('HTTP::Response')) {
		$model->add_statement(statement($ressubj, 
		                                iri($ns->uri('rdf:type')), 
		                                iri($ns->uri('http:ResponseMessage')),
		                                @graph));
		$model->add_statement(statement($ressubj, 
		                                iri($ns->uri('http:status')), 
		                                literal($self->message->code),
		                                @graph));
		$self->message->headers->scan(sub {
			                              my ($field, $value) = @_;
			                              if ($self->ok_to_add($field)) {
				                              $model->add_statement(statement($ressubj, 
				                                                              iri($ns->httph->uri(_fix_headers($field))), 
				                                                              literal($value),
				                                                              @graph));
			                              }
		                              });
		if ($self->message->request) {
			$model->add_statement(statement($reqsubj, 
			                                iri($ns->uri('http:hasResponse')), 
			                                $ressubj,
			                                @graph));
			$self->_request_statements($model, $self->message->request, $reqsubj);
			$self->message->request->headers->scan(sub {
				                                       my ($field, $value) = @_;
				                                       if ($self->ok_to_add($field)) {
					                                       $model->add_statement(statement($reqsubj, 
						                                         iri($ns->httph->uri(_fix_headers($field))), 
						                                         literal($value),
						                                         @graph));
				                                       }
			                                       });
		}
	} else {
		carp "Don't know what to do with message object of class " . ref($self->message);
	}
	return $model;
}

sub ok_to_add {
	my ($self, $field) = @_;
	unless ($self->has_blacklist or $self->has_whitelist) {
		return 1;
	}
	if ($self->has_blacklist) {
		foreach my $entry (@{$self->blacklist}) {
			if ($entry eq $field) {
				return 0;
			}
		}
		return 1;
	}
	if ($self->has_whitelist) {
		foreach my $entry (@{$self->whitelist}) {
			if ($entry eq $field) {
				return 1;
			}
		}
		return 0;
	}
}


sub _request_statements {
	my ($self, $model, $r, $subj) = @_;
	my $ns = $self->ns;
	my @graph = $self->has_graph ? ($self->graph) : ();
	$model->add_statement(statement($subj, iri($ns->uri('rdf:type')), iri($ns->uri('http:RequestMessage')), @graph));
	$model->add_statement(statement($subj, iri($ns->uri('http:method')), literal('GET'), @graph));
	$model->add_statement(statement($subj, iri($ns->uri('http:requestURI')), iri($r->uri), @graph));
}

sub _fix_headers {
	my $field = shift;
	$field =~ tr/-/_/;
	$field = lc $field;
	return $field;
}


1;
__END__

=pod

=encoding utf-8

=head1 NAME

RDF::Generator::HTTP - Generate RDF from a HTTP message

=head1 SYNOPSIS

  use LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get('http://search.cpan.org/');

  use RDF::Generator::HTTP;
  use RDF::Trine qw(iri);
  my $g = RDF::Generator::HTTP->new(message => $response,
                                    graph => iri('http://example.org/graphname'),
                                    blacklist => ['Last-Modified', 'Accept']);
  my $model = $g->generate;
  print $model->size;
  my $s   = RDF::Trine::Serializer->new('turtle', namespaces =>
                                        { httph => 'http://www.w3.org/2007/ont/httph#',
                                          http => 'http://www.w3.org/2007/ont/http#' } );
  $s->serialize_model_to_file(\*STDOUT, $model);


=head1 DESCRIPTION

This module simply takes a L<HTTP::Message> object, and based on its
content, especially the content the L<HTTP::Header> object(s) it
contains, creates a simple RDF representation of the contents. It is
useful chiefly for recording data when crawling resources on the Web,
but it may also have other uses.


=head2 Constructor

=over

=item C<< new(%attributes) >>

Moose-style constructor function.

=back

=head2 Attributes

These attributes may be passed to the constructor to set them, or
called like methods to get them.

=over

=item C<< message >>

A L<HTTP::Message> (or subclass thereof) object to generate RDF for. Required.

=item C<< blacklist >>

An C<ArrayRef> of header field names that you do not want to see in the output.

=item C<< whitelist >>

An C<ArrayRef> of the only header field names that you want to see in the
output. The whitelist will be ignored if the blacklist is set.

=item C<< graph >>

You may pass an optional graph name to be used for all triples in the
output. This must be an object of L<RDF::Trine::Node::Resource>.

=item C<< ns >>

An L<URI::NamespaceMap> object containing namespace prefixes used in
the module. You should probably not override this even though you can.

=item C<< request_subject >>

An L<RDF::Trine::Node> object containing the subject of any statements
describing requests. If unset, it will default to a blank node.

=item C<< response_subject >>

An L<RDF::Trine::Node> object containing the subject of any statements
describing responses. If unset, it will default to a blank node.

=back

=head2 Methods

The above attributes all have read-accessors by the same
name. C<blacklist>, C<whitelist> and C<graph> also has writers and
predicates, which is used to test if the attribute has been set, by
prefixing C<has_> to the attribute name.

This class has two methods:

=over

=item C<< generate ( [ $model ] ) >>

This method will generate the RDF. It may optionally take an
L<RDF::Trine::Model> as parameter. If it exists, the RDF will be added
to this model, if not, a new Memory model will be created and
returned.

=item C<< ok_to_add ( $field ) >>

This method will look up in the blacklists and whitelists and return
true if the given field and value may be added to the model.

=back

=head1 EXAMPLES

For an example of what the module can be used to create, consider the
example in the L</SYNOPSIS>, which at the time of this writing outputs
the following Turtle:

  @prefix http: <http://www.w3.org/2007/ont/http#> .
  @prefix httph: <http://www.w3.org/2007/ont/httph#> .

  [] a http:RequestMessage ;
        http:hasResponse [
                a http:ResponseMessage ;
                http:status "200" ;
                httph:client_date "Sun, 14 Dec 2014 21:28:21 GMT" ;
                httph:client_peer "207.171.7.59:80" ;
                httph:client_response_num "1" ;
                httph:connection "close" ;
                httph:content_length "3643" ;
                httph:content_type "text/html" ;
                httph:date "Sun, 14 Dec 2014 21:28:21 GMT" ;
                httph:link "<http://search.cpan.org/uploads.rdf>; rel=\"alternate\"; title=\"RSS 1.0\"; type=\"application/rss+xml\"", "<http://st.pimg.net/tucs/opensearch.xml>; rel=\"search\"; title=\"SearchCPAN\"; type=\"application/opensearchdescription+xml\"", "<http://st.pimg.net/tucs/print.css>; media=\"print\"; rel=\"stylesheet\"; type=\"text/css\"", "<http://st.pimg.net/tucs/style.css?3>; rel=\"stylesheet\"; type=\"text/css\"" ;
                httph:server "Plack/Starman (Perl)" ;
                httph:title "The CPAN Search Site - search.cpan.org" ;
                httph:x_proxy "proxy2"
        ] ;
        http:method "GET" ;
        http:requestURI <http://search.cpan.org/> ;
        httph:user_agent "libwww-perl/6.05" .



=head1 NOTES

=head2 HTTP Vocabularies


There have been many efforts to create HTTP vocabularies (or ontologies), 
where the most elaborate and complete is the 
L<HTTP Vocabulary in RDF 1.0|http://www.w3.org/TR/HTTP-in-RDF/>. 
Nevertheless, I decided not to support this, but rather support an older 
and much less complete vocabulary that has been in the 
L<Tabulator|https://github.com/linkeddata/tabulator-firefox> project, 
with the namespace prefixes L<http://www.w3.org/2007/ont/http#> and 
L<http://www.w3.org/2007/ont/httph#>. The problem of modelling HTTP 
is that headers modify each other, so if you want to record the HTTP 
headers so that they can be used in an actual HTTP dialogue afterwards, 
they have to be in a container so that the order can be reconstructed. 
Moreover, there is a lot of microstructure in the values, and that 
also adds complexity if you want to translate all that to RDF. That's 
what the former vocabulary does. However, for now, all the author wants 
to do is to record them, and then neither of these concerns are important. 
Therefore, I opted to go for a much simpler vocabulary, where each field 
is a simple predicate. That is not to say that the former approach isn't valid, 
it is just not something I need now.

=head1 BUGS

This is a very early release, but it works for the author.

Please report any bugs to
L<https://github.com/kjetilk/p5-rdf-generator-http/issues>.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

