#!/usr/bin/perl
#
# @File GraphTraversal.pm
# @Author andriy
# @Created Jul 1, 2016 10:53:44 AM
#
use strict;
use warnings;
use SemMed::Interface::CUI;
use SemMed::Interface::Predicate;
use SemMed::Interface::DataAccess;
use Heap::Priority;
package GraphTraversal;



my $conn = ""; #used for data access
sub new{
    my $class = shift;
    $conn = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}


#given a source CUI-ID and a destination CUI-ID this sub will return the destination CUI containing shortest path data or a
#-1 signifying no path was found. Path data in the returned CUI can be access through its methods (ie. $CUI->getPathLength())
#Utilizes Dijktras for finding shortest path between CUI's

#INPUT: SOURCE_CUI(string), DESTINATION_CUI(String), WEIGHT_STATISTICAL_MEASURE(string)
#OPTIONAL INPUT: , List of predicates to only include, List of Predicates to Ignore


sub findShortestPath{
    my $self = shift;
    my $startCui = $conn->getCUI(shift); #ex. heart arrest C0018790
    my $endCui = $conn->getCUI(shift); #ex. traffic accidents C0000932
    my $statistic = shift;
    my $includedPredicates = shift; #array reference to list of predicates to include
    my $excludedPredicates = shift; #array reference to list of predicates to ignore



    my $currentVertex = $startCui; #starting vertex
    $currentVertex-> setPathLength(0); #mark first vertex as reached

    my @edges = (); #this array contains all predicate connections found thus far

    my $fringe = new Heap::Priority; #this PriorityQueue contains all CUI under consideration for the next shortest path.
    $fringe->lowest_first(); #set priority to the smallest element

    my @reached = (); #this array contains references to all CUI's that have already been reached.

    ## load initial set of predicate connections
    my @query = $conn->getPredicateConnections($startCui, $statistic, $includedPredicates, $excludedPredicates);
    foreach my $edge (@query){
        push @edges, $edge;
    }



    while($currentVertex->getId() ne $endCui->getId()){ #while we have not reached the vertex we're searching for
        $currentVertex->_print();
        push @reached, $currentVertex; #add current vertex to reached vertices
   #     $currentVertex->printPath();
        foreach my $edge (@edges){
            if($edge->getSource()->getId() eq $currentVertex->getId() ){

                my $destVertex = $edge->getDestination();


                if( not(grep $_->getId() eq $destVertex->getId(), @reached) ){ #if destVertex has not been reached yet

                    if($destVertex->getPathLength() == -1){
                        $destVertex->setPathLength( $currentVertex->getPathLength() + $edge->getWeight() ); #TODO implement own method
                        $destVertex->setPrevCUI($currentVertex); #save the vertex we arrived from
                        $destVertex->setPrevPredicate($edge -> getPredicate);
                    }
                    if($destVertex->getPathLength() >= ($currentVertex->getPathLength() + $edge->getWeight() ) ){ #TODO
                        $destVertex->setPathLength( $currentVertex->getPathLength() + $edge->getWeight() ); #TODO implement own method
                        $destVertex->setPrevCUI($currentVertex); #save the vertex we arrived fromcd
                        $destVertex->setPrevPredicate($edge -> getPredicate);
                    }

                   # if(not(grep $_->getId() eq $destVertex->getId(), @fringe) ){
                        $fringe->add($destVertex, $destVertex->getPathLength());
                        #push onto the queue giving it a priority equal to its edge weight.
                   # }
                }
            }
        }


        if($fringe->count()==0){ #if fringe is empty,break
           return -1;
        }

       #set current vertex to CUI with smallest aggregate weight
       $currentVertex = $fringe->pop();

       ##loads new set of edges from databa$gt = new GraphTraversal();se
       my @newedges = $conn->getPredicateConnections($currentVertex, $statistic);
       foreach my $edge (@newedges){
           push @edges, $edge;
       }

    }

    push @reached, $currentVertex; #push end cui onto reached as we have found it

    return $currentVertex;

}


#finds a path between two given CUI's
#utilizes BFS

#
#INPUT: SOURCE_CUI(string), DESTINATION_CUI(string)
#OPTIONAL INPUT: List of predicates to only include
#
#OUTPUT: PathLength from SOURCE_CUI to DESTINATION_CUI
#
#
sub findPath{
    my $self = shift;
    my $startCui = shift; #String containing the start cui
    my $endCui = shift; #String containing the end cui
    my $includedPredicates = shift; #array reference to list of predicates to include




    #shift will return head of the queue
    #push will add element to the queue
    my @reachedCUI = (); #this array(treated as a queue) will contain the next node we want to go to
    my @reachedLength = (); #parallel array to hold the length to each cui

    my $currentCUI = $startCui;
    my $currentLength = 0;

    while($currentCUI ne $endCui){



        if($currentLength == 10){
            return -1;
        }

        my $adjacentedges = $conn->getConnections($currentCUI, $includedPredicates);
        #push new vertices to end of queue
        foreach my $edge (@{$adjacentedges}){
	          push @reachedCUI, @{$edge}[1];
            push @reachedLength, ($currentLength + 1);
        }
        #pop next vertex from queue
        $currentCUI = shift @reachedCUI;
        $currentLength = shift @reachedLength;


    }

    return $currentLength;


}

#finds the aggregate path score between two given CUI's
#utilizes BFS

#
#INPUT: SOURCE_CUI(string), DESTINATION_CUI(string)
#OPTIONAL INPUT: statistical measure, List of predicates to only include, List of Predicates to Ignore
#
#OUTPUT: Aggregate relatedness score(measure specified in parameters) from SOURCE_CUI to DESTINATION_CUI
#
#TODO
sub findPathScore{
    my $self = shift;
    my $startCui = shift; #String containing the start cui
    my $endCui = shift; #String containing the end cui
    my $measure = shift;
    my $includedPredicates = shift; #array reference to list of predicates to include
    my $excludedPredicates = shift; #array reference to list of predicates to ignore




    #shift will return head of the queue
    #push will add element to the queue
    my @reachedCUI = (); #this array(treated as a queue) will contain the next node we want to go to
    my @reachedScore = (); #parallel array to hold the score of each cui

    my $currentCUI = $startCui;
    my $currentLength = 0;
    my $iter = 0;
    while($currentCUI ne $endCui){
        $iter++;
        if($iter % 1000 == 0){
       #     print STDERR "Buffered CUI's: ". scalar(@reachedCUI)." ==> $iter \n";
        }

        #TODO add threshold
#        if($currentLength == 10){
#            return -1;
#        }

        my @adjacentedges = $conn->getPredicateConnections($conn->getCUI($currentCUI), $measure, $includedPredicates, $excludedPredicates);

        #push new vertices to end of queue
        foreach my $edge (@adjacentedges){
            push @reachedCUI, $edge->getDestination()->getId();
            push @reachedScore, ($currentLength + ($edge->getWeight()));
        }

        #pop next vertex from queue
        $currentCUI = shift @reachedCUI;
        $currentLength = shift @reachedScore;


    }

    return $currentLength;


}


sub findPathString{
    my $self = shift;
    my $startCui = shift; #String containing the start cui
    my $endCui = shift; #String containing the end cui
    my $measure = shift;
    my $includedPredicates = shift; #array reference to list of predicates to include
    my $excludedPredicates = shift; #array reference to list of predicates to ignore

    my @reachedCUI; #this array(treated as a queue) will contain the next node we want to go to
    my @reachedString = (); #parallel array to hold the path string

    my $currentCUI = $startCui;
    my $currentString = "$startCui ";

    while($currentCUI ne $endCui){

        my $adjacentedges = $conn->getConnections($currentCUI);

        #push new vertices to end of queue
        foreach my $edge (@{$adjacentedges}){
            push @reachedCUI, @{$edge}[1];
            push @reachedString, ($currentString." ".@{$edge}[1]);
        }

        #pop next vertex from queue
        $currentCUI = shift @reachedCUI;
        $currentString = shift @reachedString;


    }

    return $currentString;

}

#Finds overlap in outgoing concepts from two given concepts
#
#input: cui, cui
#output: score <- integer denoting the number of overlapping concepts

sub getOverlappingConcepts{
  my $self = shift;
  my $concept_one = shift;
  my $concept_two = shift;
  my $includedPredicates = shift;

  my $concept_one_breadth = $conn->getConnections($concept_one, $includedPredicates);
  my $concept_two_breadth = $conn->getConnections($concept_two, $includedPredicates);

  my $overlapping_concepts = 0;
  foreach my $edge (@{$concept_one_breadth}){
    my $concept = @{$edge}[1];
    foreach my $edge2 (@{$concept_two_breadth}){
      if($concept eq @{$edge2}[1]){
        $overlapping_concepts++;
        last;
      }
    }
  }
  return $overlapping_concepts;


}

# a random neighboor of a given cui

sub getRandomNeighbor{
  my $self = shift;
  my $concept = shift;
  my $includedPredicates = shift;
  my @neighbors = @{$conn->getBidirectionalConnections($concept, $includedPredicates)};
  my @randomConnection = @{$neighbors[rand @neighbors]};

  if($randomConnection[0] eq $concept){#our neighbor is the second element
    return $randomConnection[1];
  }else{
    return $randomConnection[0];
  }

}




1;
