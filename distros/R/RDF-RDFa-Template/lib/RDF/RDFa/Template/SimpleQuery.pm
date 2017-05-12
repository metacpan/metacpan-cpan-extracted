package RDF::RDFa::Template::SimpleQuery;

use warnings;
use strict;

=head1 NAME

RDF::RDFa::Template::SimpleQuery - Module to run a RAT Template Query very easily

=head1 DESCRIPTION

This module intends to be simple interface to do most of the tasks
that most users of RDF::RDFa::Template would want to do.

=head1 SYNOPSIS

  my ($f)   = File::Util->new();
  my ($rat) = $f->load_file('dbpedia-comment/input.xhtml');
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat,
						    filename => 'dbpedia-comment/input.ttl',
						    syntax => 'turtle');
  $query->execute;
  my $output = $query->rdfa_xhtml;
  $output->toStringC14N;

or

  my ($f)   = File::Util->new();
  my ($rat) = $f->load_file('dbpedia-comment/input.xhtml');
  my ($rdf) = $f->load_file('dbpedia-comment/input.ttl');
  my $rdfparser = RDF::Trine::Parser->new( 'turtle' );
  my $storage = RDF::Trine::Store::Memory->temporary_store;
  my $model = RDF::Trine::Model->new($storage);
  $rdfparser->parse_into_model ( "http://example.org/", $rdf, $model );
  my $query = RDF::RDFa::Template::SimpleQuery->new(rat => $rat, model => $model);
  $query->execute;
  my $output = $query->rdfa_xhtml;
  $output->toStringC14N;

=head1 METHODS

=cut

use RDF::RDFa::Template::Unit;
use RDF::RDFa::Template::Document;
use RDF::RDFa::Template::SAXFilter;
use RDF::Trine::Model;
use RDF::Trine::Statement;
use RDF::Trine::Node::Variable;
use RDF::Trine::Pattern;
use RDF::RDFa::Parser;
use RDF::Query::Client;
use XML::LibXML;
use XML::LibXML::SAX::Parser;
use XML::LibXML::SAX::Builder;
use File::Util;

use Data::Dumper;
use Carp;

=head2 new

The constructor. This takes a number of named arguments.

=over

=item C<rat>

The RDFa Template XHTML text to be parsed.

=item C<baseuri>

The base URI to resolve any relative URIs. This is optional,
"http://example.org/" is used if this is not given.

=back

The following arguments are all used to give the module the data it
shall query to fill the variables.

=over

=item C<model>

May be an L<RDF::Trine::Model> object with the data to be queried. If
given, it takes presedence over any other arguments.

=item C<filename>

The full path of a file containing some RDF to be queried.

=item C<rdf>

A string with some RDF to be queried.


=item C<syntax>

A string giving the syntax to be parsed. Syntaxes supported by
L<RDF::Trine::Parser> are supported, e.g. C<turtle>, C<rdfxml>,
etc. This parameter is required if C<filename> or C<rdf> is used.

=back

=cut


sub new {
  my ($class, %args) = @_;
  my $self;
  $self->{RAT} = $args{rat};
  if ($args{model}) {
    if ($args{model}->isa('RDF::Trine::Model')) {
      # We got a model
      $self->{MODEL} = $args{model};
      bless ($self, $class);
      return $self;
    } else {
      croak 'model argument is not a RDF::Trine::Model';
    }
  }

  if ($args{filename}) {
    if (-f $args{filename}) {
      # We have a file
      my($f) = File::Util->new();
      my ($rdf) = $f->load_file($args{filename});
      $self->{MODEL} = _init_model($args{syntax}, $rdf, $args{baseuri});
    } else {
      croak "Cannot open $args{filename}";
    }
  } elsif ($args{rdf}) {
    $self->{MODEL} = _init_model($args{syntax}, $args{rdf}, $args{baseuri});
  }




  bless ($self, $class);
  return $self;
}

sub _init_model {
  my ($syntax, $rdf, $baseuri) = @_;
  my $rdfparser = RDF::Trine::Parser->new( $syntax );
  my $storage = RDF::Trine::Store::Memory->temporary_store;
  my $model = RDF::Trine::Model->new($storage);
  $baseuri ||= "http://example.org/";
  $rdfparser->parse_into_model ($baseuri, $rdf, $model);
  return $model;
}



=head2 execute

Now, really run it. This does the heavylifting, and therefore you
should run this method manually in your application to control when it
does happen. Returns the number of queries generated.

=cut

sub execute {
  my $self = shift;
  my $parser = RDF::RDFa::Parser->new($self->{RAT}, 'http://example.org/foo/', 
				      {
				       use_rtnlx => 1,
				       graph => 1,
				       graph_type => 'about',
				       graph_attr => '{http://example.org/graph#}graph',
				      });
  $parser->consume;
  $self->{DOC} = RDF::RDFa::Template::Document->new($parser);
  $self->{DOC}->extract;

  my $return = 0;
#  die Dumper($doc->units);
  foreach my $unit ($self->{DOC}->units) {
    my $query = 'SELECT * WHERE { ' . $unit->pattern->as_sparql . ' }';
    my $model = $self->{MODEL};
    my $client;
    if ($unit->endpoint) {
      $client = RDF::Query::Client->new($query);
      $model = $unit->endpoint;
    } elsif ($self->{MODEL} && ($self->{MODEL}->isa('RDF::Trine::Model'))) {
      $client = RDF::Query->new($query);
    } else {
      croak "Need either an endpoint or an RDF::Trine::Model";
    }
    my $iterator = $client->execute( $model );

    $unit->results($iterator);
    $return++;
  }
  return $return;
}

=head2 rdfa_xhtml

Once the query has been executed (see above), this method will return
a L<XML::LibXML::Document> containing the RDFa document with the
variables inserted.

=cut


sub rdfa_xhtml {
  my $self = shift;
  my $builder = XML::LibXML::SAX::Builder->new();

  my $sax = RDF::RDFa::Template::SAXFilter->new(Handler => $builder, Doc => $self->{DOC});
  my $generator = XML::LibXML::SAX::Parser->new(Handler => $sax);

  my $orig = $self->{DOC}->dom;

  $generator->generate($orig);

  # TODO:  # Get the doctypes and stuff
  # my $xpc = XML::LibXML::XPathContext->new($orig);
  # $xpc->registerNs('rat', $self->{DOC}->{RATURI});
  # $xpc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
  # my ($system_id) = $xpc->findnodes('/xhtml:html/@rat:doctype-system') || 'http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd';
  # my ($public_id) = $xpc->findnodes('/xhtml:html/@rat:doctype-public') || '-//W3C//DTD XHTML+RDFa 1.0//EN';
  # my $dtd = XML::LibXML::Dtd->new($public_id, $system_id); # Downloads the DTD, it seems


  my $output = $builder->result;
  # $output->setExternalSubset($dtd);

  return $output;
}

  


=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2010 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
