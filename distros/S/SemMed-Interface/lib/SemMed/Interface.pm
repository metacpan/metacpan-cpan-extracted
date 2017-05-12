#!/usr/bin/perl
#
# @File Interface.pm
# @Author andriy
# @Created Aug 1, 2016 10:33:50 AM
#

=head1 NAME

SemMed::Interface -  A suite of Perl modules that utilize path information
present in the Semantic Medline Database in order to calculate the semantic
association between two concepts in the UMLS.

=head1 INSTALL
To install the module, run the following magic commands:

  perl Makefile.PL
  make
  make test
  make install

This will install the module in the standard location. You will, most
probably, require root privileges to install in standard system
directories. To install in a non-standard directory, specify a prefix
during the 'perl Makefile.PL' stage as:

  perl Makefile.PL PREFIX=/home/sid

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 DESCRIPTION
This package provides a Perl interface to the Semantic Medline Database

=head1 DATABASE SETUP

The interface assumes you have installed the Semantic Medline Database onto your
MySQL server and in addition, followed the steps present in the INSTALL file to
create the appropriate auxilary tables in order to speed up program runtime.
The name of the database can be passed through during program runtime but will
default to 'SemMedDB' if no parameter is given.

The SemMedDB database must contain the following tables:
	1. CONCEPT
	2. CONCEPT_SEMTYPE
	3. PREDICATION_ARGUMENT
	4. PREDICATION
  5. SENTENCE_PREDICATION
  6. SENTENCE
  7. CITATIONS
  8. PREDICATION_AGGREGATE
  9. DISTINCT_PREDICATION_AGGREGATE *

*The table 'DISTINCT_PREDICATION_AGGREGATE' does not install alongside the
Semantic Medline Database via the .SQL file provided on their website. Steps
must be followed in the INSTALL file to set-up this table. Failure to do so
will cause fatal errors at runtime.

A script inside the INSTALL file details the steps needed to generate
the required auxilary tables. These steps are to be done following the Semantic
Medline Database install and may take up to several days to complete due to the
size of the database.

=head1 INITIALIZING THE MODULE

To create an instance of the interface module, using default values
for all configuration options:

  use SemMed::Interface;
  my $SemMedLoginParam =     {      "driver" => "mysql",
                                    "database" => "SemMedDB",
                                    "username" => "username",
                                    "password" => "password",
                                    "socket" => "/home/mysql/mysql.sock",
                                    "hostname" => "localhost",
                                    "port"   => "3306"};




  my $interface = new SemMed::Interface($SemMedLoginParam);

=cut

package SemMed::Interface;
use strict;
use warnings;
use SemMed::Interface::GraphTraversal;
use SemMed::Interface::DataAccess;


use vars qw($VERSION);

$VERSION = '0.05';

my $connection = "";
my $gt = "";

my @includedPredicates; #only this predicates will be used in the traversal
my @excludedPredicates; #these predicates will be excluded in the traversal

#  method to create a new SemMed::Interface object
#  input : $SemMedLoginParams <- reference to hash containing SemMed login parameter
#          $AssociationLoginParams <- reference to hash containing the UMLS::Association login parameters
#  output:
sub new {

    my $self = {};
    my $class = shift;
    my $SemMedLoginParams = shift; #hash containing the SemMed login parameters
    my $AssociationLoginParams = shift; #hash containing the UMLS::Association login parameters

    @includedPredicates = ();
    @excludedPredicates = ();

    bless($self, $class);

    $connection = new DataAccess($SemMedLoginParams, $AssociationLoginParams);
    $gt = new GraphTraversal($connection);

    return $self;
}

#######################################

=head3 findPathLength

description:

 Utilizes a breadth first search to find the path length from a source_concept to a destination_concept

input:

 $source_concept <- string containing the concept id of the cui to start searching from
 $destination_concept <- string containing the concept id you are searching for
 @includedPredicates <- List of predicates to include when searching for outgoing edges.

output:

 length of path   <- Non-negative Integer | -1 indicating length of path between the two concepts

example:

 #finds path length between Heart and Myocardial Infarction
 use SemMed::Interface;
 my $interface = new SemMed::Interface();

 my $pathlength = $interface->findPathLength("C0018787", "C0027061");

example:

 #finds path length between Heart and Myocardial Infarction
 use SemMed::Interface;
 my $interface = new SemMed::Interface();
 my @includedPredicates = ("TREATS", "CAUSES"); #limits BFS to paths that are associated with the predicates TREATS or CAUSES.

 my $pathlength = $interface->findPathLength("C0018787", "C0027061", \@includedPredicates);


=cut
sub findPathLength{

    my $self = shift;
    my $source_cui = shift;
    my $destination_cui = shift;
    my $includedPredicates = shift;
    return $gt->findPath($source_cui, $destination_cui);
}

#######################################

=head3 findPathScore

description:

 Function utilizing a breadth first search along with UMLS::Association to find the aggregate association score
 along the path between source_concept and destination_concept

input:

 $source_concept <- string containing the concept id of the cui to start seraching from
 $destination_concept <- string containing the concept id you are searching for
 $measure <- string containing the UMLS::Association statistic measure to aggregate along paths.

output:

 Aggregate association score   <- Non-negative float indicating the aggregate path score

example:

 #finds aggregate association score between Heart and Myocardial Infarction
 use SemMed::Interface;
 my $interface = new SemMed::Interface();

 my $score = $interface->findPathLength("C0018787", "C0027061", "tscore");


=cut
sub findPathScore{

    my $self = shift;
    my $source_cui = shift;
    my $destination_cui = shift;
    my $measure = shift;
    return $gt->findPathScore($source_cui, $destination_cui, $measure, \@includedPredicates, \@excludedPredicates);

}


=head3 getConceptDegree
description:
  Gets the degree(the number of outgoing relationships) from a particular cui
input:
 $concept <- string containing the concept id of the cui to start seraching from
output:
 Integer >= 0   <- Degree of the concept
=cut
sub getConceptDegree{
  my $self = shift;
  my $concept = shift;
  return $connection->getConceptDegree($concept);
}

=head3 getConnections
description:
  Gets all outgoing predicates and concepts from a given concept
input:
 $concept <- string containing the concept id to get outgoing edges from
output:
 $edges  <- array reference of outgoing predicates and concepts

example:
  use SemMed::Interface;
  my $interface = new SemMed::Interface();

  my $edges = $interface->getConnections("C0018787");

  foreach @edge (@$edges){
      $predicate = $edge[0];
      $destination_concept = $edge[1];
  }

=cut

sub getConnections {
  my $self = shift;
  my $concept = shift;
  return $connection->getConnections($concept);
}


=head3 getOverlappingConcepts
description:
  Gets the number of overlapping concepts in the neighboorhood of two given concepts
input:
 $concept_one <- string containing the concept id of the first concept
 $concept_two <- string containing the concept id of the second concept
output:
 $numberOfOverlap  <- number of overlapping concepts in the neighboorhoods of the two given concepts

example:
  use SemMed::Interface;
  my $interface = new SemMed::Interface();

  my $overlap = $interface->getOverlappingConcepts("C0018787", "C0000932");
S
=cut

sub getOverlappingConcepts{
  my $self = shift;
  my $concept_one = shift;
  my $concept_two = shift;
  my $includedPredicates = shift;

  return $gt->getOverlappingConcepts($concept_one, $concept_two, $includedPredicates);

}


=head3 randomWalk
description:
  Simulates a random walk starting at $concept_one and ending at $concept_two
input:
 $concept_one <- string containing the concept id of the starting concept
 $concept_two <- string containing the concept id of the ending concept
output:
 $stepsTaken  <- number of steps it took to reach $concept_two from $concept_one

example:
  use SemMed::Interface;
  my $interface = new SemMed::Interface();

  my $steps = $interface->randomWalk("C0018787", "C0000932");

=cut

sub randomWalk{
  my $self = shift;
  my $concept_one = shift;
  my $concept_two = shift;
  my $includedPredicates = shift;

  my $currentVertex = $concept_one;
  my $steps = 0;
  while($currentVertex ne $concept_two){

    $steps++;

    my $randomNeighbor = $gt->getRandomNeighbor($currentVertex, $includedPredicates);
    if($randomNeighbor){
      $currentVertex = $randomNeighbor;
    }else{exit;}
  }

  return $steps;
}


sub addIncludedPredicates{
    my $self = shift;
    my $predicates = shift;
    push @includedPredicates, @$predicates;
}



sub clearIncludedPredicates{
    my $self = shift;
    @includedPredicates = ();
}



sub addExcludedPredicates{
    my $self = shift;
    my $predicates = shift;
    push @excludedPredicates, @$predicates;
}



sub clearExcludedPredicates{
    my $self = shift;
    @excludedPredicates = ();
}




1;
