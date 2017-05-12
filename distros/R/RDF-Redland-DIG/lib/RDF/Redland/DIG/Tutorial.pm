package RDF::Redland::DIG::Tutorial

=pod

=head1 NAME

Tutorial - RDF::Redland::DIG::Tutorial

=head1 Introduction

L<RDF::Redland> is a Perl wrapper around the Redland RDF libraries.  L<RDF::Redland::DIG> is a
(Perl-only) extension to exchange information with a I<DIG reasoner>, i.e. one which can be reached
via the DIG protocol.

The following gives an overview over the API. To learn more you may want to consult the
manpages
  
  man RDF::Redland::DIG

for the reasoner itself, or

  man RDF::Redland::DIG::KB

for the knowledge base hosted inside the reasoner.

=head1 Test Ontology

Before we can start with using the reasoning services, we have to create an
RDF::Redland::Model to host the data. In the following, I created a simple test ontology inspired by
the Prot√©g©pizza ontology (L<http://protege.stanford.edu>).
  
  @prefix owl  <http://www.w3.org/2002/07/owl#> .
  @prefix xsd  <http://www.w3.org/2001/XMLSchema#> .
  @prefix rdfs <http://www.w3.org/2000/01/rdf-schema#>.
  @prefix rdf  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
  
  Pizza            a    owl:Class.
  PizzaTopping     a    owl:Class.
  
  CheesePizza      a    owl:Class;
                   rdfs:subClassOf Pizza.
  ProsciuttoPizza  a    owl:Class;
                   rdfs:subClassOf Pizza.

  CheeseTopping    a    owl:Class;
                   rdfs:subClassOf PizzaTopping.
  HamTopping       a    owl:Class;
                   rdfs:subClassOf PizzaTopping.
  TomatoTopping    a    owl:Class;
                   rdfs:subclassOf PizzaTopping.
    
  hasIngredient    a           owl:ObjectProperty;
                   owl:inverseOf isIngredientOf.
  hasTopping       rdfs:subPropertyOf hasIngredient;
                   owl:inverseOf isToppingOf;
                   rdfs:domain   Pizza;
                   rdfs:range    PizzaTopping.
  isIngredientOf   a           owl:ObjectProperty;
                   owl:inverseOf hasIngredient.
  isToppingOf      rdfs:subPropertyOf isIngredientOf;
                   owl:inverseOf hasTopping;
                   rdfs:domain   PizzaTopping;
                   rdfs:range    Pizza.

Apart from the ontological information, we can also add some instance data to play with:

  Margharita       a         CheesePizza;
                   hasTopping  MozarellaTopping.
  MozarellaTopping a         CheeseTopping;
                   isToppingOf Margharita.

=head1 The Model

If we assume that the above ontology and instance data is stored in an RDF file
C<pizza.n3>, the we can load this file into a model:
  
  use RDF::Redland::Parser;
  my $parser = new RDF::Redland::Parser (undef, "application/rdf+xml")
      or die "Failed to find parser";

  use RDF::Redland::Storage;  
  my $storage = new RDF::Redland::Storage (
                  "hashes",
                  "test",
                  "new='yes', hash-type='bdb', dir='/where/ever/'")
      or die "Failed to create RDF::Redland::Storage";

  use RDF::Redland::Model;
  my $model   = new RDF::Redland::Model ($storage, "")
      or die "Failed to create RDF::Redland::Model for storage";
    
  my $uri = new RDF::Redland::URI ("file:///where/ever/pizza.n3");
  $parser->parse_into_model ($uri, $uri, $model);

A detailed step-by-step tutorial for L<RDF::Redland> can
be found at L<http://kill.devc.at/internet/semantic-web/rdf/redland/tutorial> .
  
=head1 The Reasoner and KB Handles

A DIG reasoner is a separate process, popular choices being pellet, Fact++. As the
communication occurs via HTTP, we have to specify the URL when we create a handle
to the reasoner:

  use RDF::Redland::DIG;  
  my $digreasoner = new RDF::Redland::DIG ( "http://localhost:8081" )
      or die "Failed to create RDF::Redland::DIG";

From then on we are able to create our own knowledge base. This can be easily done by
requesting such from our $digreasoner:
  
  my $kb = $digreasoner->kb;
    
This way, we can create as many knowledge bases as we need.

To fill our knowledge base $kb with data we tell it about our $model:
  
  $kb->tell ($model) or die "Tell failed";

After having executed C<tell>, our C<$model> is stored in the knowledge base, we can start
with the reasoning. In the following I will describe a few stereotypical methods. For
further details on all available methods please have a look at the manual page of
L<RDF::Redland::DIG::KB>.

=head1 Concept Retrieval

For pure concept retrieval there are three methods available. One of them is the function
C<allRoleNames> that returns all roles from our C<$model>:
  
  warn Dumper $kb->allRoleNames;
  
  Result:
      'hasIngredient',
      'hasTopping',
      'isIngredientOf',
      'isToppingOf'
  
The methods C<allConceptNames> and C<allIndividuals> work analogous. 

=head1 Satisfiability

To check, whether or not the relations between classes are satisfied, there are three
methods available:
  
With C<unsatisfiable> we can retrieve a list of all those concepts, which are not
satisfiable. Because there are no unsatisfiable concepts in our pizza ontology, we would
get back an empty list:

  warn Dumper $kb->unsatisfiable;
  
  Result:

We can also query whether or not one concept subsumes another. To do that we have to
provide a hash (reference) that contains the classes we want to check:
  
  warn Dumper $kb->subsumes (\ %('Pizza' => ['PizzaTopping', 'CheesePizza']) );
  
  Result:
      'Pizza' => 'CheesePizza'
  
The result contains all those classes as values that indeed subsume the concept that is
provided as key.

The third method C<disjoint> works the same way.
  
=head1 Concept Hierarchy

Furthermore, there are some methods regarding the hierarchy of concepts.  If you want to
know, for instance, the parents from a specific concept of our C<$model>, you can simply
write:
  
  warn Dumper $kb->parents ('CheesePizza', 'HamTopping');
  
  Result:
      'CheesePizza' => 'Pizza',
      'HamTopping'  => 'PizzaTopping'
  
You can also request information on children, descendants or ancestors from classes.
  
=head3 Role Hierarchy

Similar to the concept hierarchy methods, there are also role hierarchy functions
available. This way you are able to retrieve information regarding the parents, children,
ancestors or descendants of a specific role. If we want to know all children for a
specific role in our C<$model>, we write:
  
  warn Dumper $kb->rchildren ('isIngredientOf');
  
  Result:
     'isIngredientOf' => 'isToppingOf'

=head1 Queries about Individuals
  
For retrieving information about the relations between concepts, roles or individuals,
there is also a bunch of methods available.  We can query the instances from a specific
class:
  
  warn Dumper $kb->instances ('CheesePizza')
  
  Result:
     'CheesePizza' => 'Margharita'
  
We can retrieve information about individuals that are asserted to a specific
(individual,role)-pair with the C<roleFillers> method. All we have to provide is one
individual and one role as parameter and in return we get all individuals that are
asserted as statement involving this pair:
  
  warn Dumper $kb->roleFillers ('Margharita', 'hasTopping');
  
  Result:
      'MozarellaTopping'
  
If we want to know which pairs of individuals are asserted to a given role, we use the
method C<relatedIndividuals>:
  
  warn Dumper $kb->relatedIndividuals ('hasTopping');
  
  Result:
      ('Margharita', 'MozarellaTopping')
  
  
=head1 Variation: Procure your own User Agent

Sometimes you will want to use an HTTP user agent of your own making, be it for testing,
caching, etc. In any case it will have to be a subclass of L<LWP::UserAgent>.

If we assume that it is stored in C<$ua>, then you will need to provide it as a additional
parameter when the reasoner handle is created:

  my $digreasoner = new RDF::Redland::DIG ( "http://localhost:8081", ua => $ua )
     or die "Failed to create RDF::Redland::DIG";

=head1 Variation: Concept Hierarchy Parameters

There are some alternatives regarding parameters when using the concept and role hierarchy
methods.
  
As shown above, you can provide a specific concept or role as parameter and get all the
information you want for those specified concepts/roles. If you want to create a general
query on all existing concepts and roles from your model, you can leave the parameter
blank.
  
For instance, if you want to have the parents from all concepts of our C<$model>, you
can write:
  
  warn Dumper $kb->parents;
  
  Result:
      'Pizza' => '',
      'PizzaTopping' => '',
      'CheesePizza' => 'Pizza',
      'ProsciuttoPizza' => 'Pizza',
      'CheeseTopping' => 'PizzaTopping',
      'TomatoTopping' => 'PizzaTopping',
      'HamTopping' => 'PizzaTopping'
  
=head1 COPYRIGHT AND LICENCE

Copyright 2008 by Lara Spendier and Robert Barta

Creative Commons Licence L<http://creativecommons.org/licenses/by/2.0/at/>

=cut

our $VERSION = '0.03';

1;
