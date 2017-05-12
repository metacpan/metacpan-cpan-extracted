#!/usr/bin/perl
#
# @File DataAccess.pm
# @Author andriy
# @Created Jun 27, 2016 3:27:32 PM
#

package DataAccess;
use DBI;
use UMLS::Association;




my $errorhandling = "";
my $association = "";
my $dbh = "";

#  method to create a new SemRep::Interface object
#  input : $SemMedLoginParams <- reference to hash containing SemMed login parameter
#          $AssociationLoginParams <- reference to hash containing the UMLS::Association login parameters
#  output:
sub new {
    $class = shift;
    my $self = {};
    my $SemMedLoginParams = shift; #hash containing the SemMed login parameters
    my $AssociationLoginParams = shift; #hash containing the UMLS::Association login parameters

    my $database = $SemMedLoginParams->{'database'};
    my $hostname = $SemMedLoginParams->{'hostname'};
    my $port = $SemMedLoginParams->{'port'};
    my $userid = $SemMedLoginParams->{'username'};
    my $password = $SemMedLoginParams->{'password'};

    my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

    if($association){
      $association = new UMLS::Association($AssociationLoginParams);
      $errorhandling = UMLS::Association::ErrorHandler->new();
    }



    $dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
    $dbh->{InactiveDestroy} = 1; #allows forking of threads containing this DB connect

    bless $self, $class;
    return $self;
}


#given a CUI, this method will return all Predicate-CUI connections leading from the given CUI

#INPUT: SOURCE_CUI_OBJECT, WEIGHT_STATISTICAL_MEASURE(string) or 1
#OPTIONAL INPUT: , List of predicates to only include, List of Predicates to Ignore

#OUTPUT: ARRAY OF PREDICATE objects whos source is SOURCE_CUI_OBJECT and destination is what was matched in DB.
sub getPredicateConnections {

    if(not $association){
      print "Error: UMLS::Association not loaded";
      exit;
    }

    my $self = shift;

    my $cui = shift;
    my $measure = shift;
    my $includedPredicates = shift;
    my $excludedPredicates = shift;
    unless($measure){ #default to tscore
        $measure = "tscore";
    }

    my $cuiid = $cui->getId();

    my $queryString =
    "SELECT s_cui, s_name, o_cui, o_name, predicate, $measure FROM SemMedDB.DISTINCT_PREDICATION_AGGREGATE
     WHERE s_cui = '$cuiid'";


     ### Will add in query parameters for removing certain predicate types
    if($includedPredicates){
        my $perm = " AND (";
        foreach $pred ( @$includedPredicates){
            $perm .= "predicate = '$pred' OR ";
        }
        substr($perm, -4) = ""; #remove extra OR
        $perm .= ")";
        $queryString .= $perm;
    }

    if($excludedPredicates){
        my $perm = " AND NOT (";
        foreach $pred ( @$excludedPredicates){
            $perm .= "predicate = '$pred' OR ";
        }
        substr($perm, -4) = "";
        $perm .= ")";
        $queryString .= $perm;
    }

    #print $queryString."\n";



    my $sth = $dbh->prepare($queryString);
    $sth->execute() or die $DBI::errstr;
    my @edges = ();


    while (my @row = $sth->fetchrow_array()) {
        my $source = new CUI($row[0], $row[1]); #create source vertex
        my $destination = new CUI($row[2], $row[3]); #create dest vertext

        my $weight;

        my $validConcepts = $errorhandling->_validCui($row[0]) && $errorhandling->_validCui($row[2]);

        if($measure == 1){ #no stats needed, we are just running a BFS
            $weight = 1;
        }else{

            #if value is cached in db, use it
            if($row[5]){
                $weight = $row[5];

            }else{
                #obtain value from UMLS, then cache it
                if($validConcepts){
                  #  print "calculating stats $row[1] $row[3] \n";
                    $weight = $association->calculateStatistic($source->getId(), $destination->getId(), $measure);
                }else{
                    $weight = -1;
                }


                my $updateString = "UPDATE SemMedDB.DISTINCT_PREDICATION_AGGREGATE SET $measure = $weight WHERE s_cui = '$row[0]' AND predicate = '$row[4]' AND o_cui = '$row[2]' LIMIT 1;";
                my $update = $dbh->prepare($updateString);
                $update->execute() or die $DBI::errstr;
            }
            #we need to calculate an edge weight, use the measure given to do so from UMLS::Association package



        }

        if($weight == -1){next;}#if no information was found, ignore this edge

        #The weight is now a statistic, a value further from 0 will indicate that the two words are highly associated
        #Take the multiplicative reciprical of this so that highly associated words will correspond to lower edge weights
        if($weight){ #make sure its not zero
            $weight = abs(1/$weight);
        }


        my $predicate = new Predicate($source, $row[4], $destination, $weight); #create edge
        push @edges, $predicate; #push to main array holding all edges
    }
    $sth->finish();

    return @edges;
}

#
#OBTAIN CUI FROM CUI ID
#INPUT: CUI | PREFERRED NAME
#OUTPUT: CUI_OBJECT with fields complete.
sub getCUI{
    my($self, $cui) = @_;
    my $sth = $dbh->prepare("SELECT CUI, PREFERRED_NAME FROM CONCEPT
                             WHERE CUI = '$cui' OR PREFERRED_NAME = '$cui'
                             LIMIT 1");
    $sth->execute() or die $DBI::errstr;
    my @row = $sth->fetchrow_array();
    return new CUI($row[0], $row[1]);
}



#Gets outgoing predicates from inputed concept
#INPUT: CUI
#OUTPUT: Array holding predicate's and destination_cui's (predicate, destination_cui)
sub getConnections {
  my $self = shift;
  my $concept = shift;
  my $includedPredicates = shift;
  my $query = "SELECT predicate, o_cui FROM DISTINCT_PREDICATION_AGGREGATE WHERE s_cui = '$concept'";

  if($includedPredicates){
      my $perm = " AND (";
      foreach $pred ( @$includedPredicates){
          $perm .= "predicate = '$pred' OR ";
      }
      substr($perm, -4) = ""; #remove extra OR
      $perm .= ")";
      $query .= $perm;
  }

  my $sth = $dbh->prepare($query);
  $sth->execute() or die $DBI::errstr;
  $rows = $sth->fetchall_arrayref();
  return $rows;
}

sub getBidirectionalConnections{
  my $self = shift;
  my $concept = shift;
  my $includedPredicates = shift;
  my $query = "SELECT s_cui, o_cui FROM DISTINCT_PREDICATION_AGGREGATE WHERE s_cui = '$concept' OR o_cui = '$concept'";

  if($includedPredicates){
      my $perm = " AND (";
      foreach $pred ( @$includedPredicates){
          $perm .= "predicate = '$pred' OR ";
      }
      substr($perm, -4) = ""; #remove extra OR
      $perm .= ")";
      $query .= $perm;
  }

  my $sth = $dbh->prepare($query);
  $sth->execute() or die $DBI::errstr;
  $rows = $sth->fetchall_arrayref();
  return $rows;

}



#
# OBTAIN SEMTYPE FROM CUI ID
#INPUT: CUI | PREFERRED NAME
#OUTPUT: Semantic Type Associated with that CUI or Term.
sub getSemtype {
    my($self, $cui) = @_;
    my $sth = $dbh->prepare(
    "SELECT CS.SEMTYPE FROM CONCEPT C
     JOIN CONCEPT_SEMTYPE CS ON (C.CONCEPT_ID = CS.CONCEPT_ID)
     WHERE C.CUI = '$cui' OR C.PREFERRED_NAME LIKE '$cui'
     LIMIT 1"
    );
    $sth->execute() or die $DBI::errstr;
    return ($sth->fetchrow_array())[0];

}
1;
