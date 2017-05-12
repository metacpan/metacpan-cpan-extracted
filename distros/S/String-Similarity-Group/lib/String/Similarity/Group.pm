package String::Similarity::Group;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA %SEEN $DEBUG);
use Exporter;
use Carp;
use LEOCHARRE::Debug;
use String::Similarity 'similarity';

$VERSION = sprintf "%d.%02d", q$Revision: 1.16 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/groups groups_lazy groups_hard loners similarest sort_by_similarity _group_new _group_medium/;
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub _group_hard { # test every element of every group!
   my($min,$aref)=@_;
   ref $aref and ref $aref eq 'ARRAY' or croak("Argument is not an array ref");

   $min >=0 and $min <= 1 or croak("min similarity must be between 0.00 and 1.00");

   my %group;

   ELEMENT: for my $element (@{$aref}) {        
      
      # HARD MATCHING, continue until highest hit
      # traverse all groups, find highest

      my %matched_group = ( score => 0, id => undef );

      GROUP: for my $group_id ( keys %group ){

         my ($highest_element, $score) = similarest( $group{$group_id}, $element, $min ) 
            or next GROUP;
         
         if( $score > $matched_group{score} ){
            %matched_group = ( score => $score, id => $group_id );
         }
      }

      # did we match a group?
      if ( $matched_group{score} ){
        push @{$group{$matched_group{id}}}, $element; 
        next ELEMENT;
      }
      
      # no group matching, make new group.
      $group{$element} = [$element];  

   }

   \%group;
}


sub _group_lazy { # just get the first match
   my($min,$aref)=@_;
   ref $aref and ref $aref eq 'ARRAY' or croak("Argument is not an array ref");
   (($min >=0) and ($min <= 1)) or croak("min similarity must be between 0.00 and 1.00");

   my %group;

   ELEMENT: for my $element (@{$aref}) {  
         
         GROUP: for my $group_id ( keys %group ){

            similarity( $element, $group_id) >= $min 
               or next GROUP;

            push @{$group{$group_id}}, $element;
            next ELEMENT;
         }
         # no group matching, make new group.
         $group{$element} = [$element];
   }

   \%group;
}



sub _group_medium { # get the highest matching group id
   my($min,$aref)=@_;
   ref $aref and ref $aref eq 'ARRAY' or croak("Argument is not an array ref");
   (($min >=0) and ($min <= 1)) or croak("min similarity must be between 0.00 and 1.00");
   my %group;

   ELEMENT: for (@{$aref}) {         
      no warnings; 
      my ($group_id, $score ) = similarest( [ keys %group ], $_, $min );

      debug("score/string/groupid/min $score/$_/$group_id/$min");
      $score and  # one of the group keys had the highest match
         (( push @{$group{$group_id}}, $_ ) 
         and next ELEMENT);

      debug("+ no group matching, make new group '$_'");
      $group{$_} = [$_];
   }

   \%group;
}



sub _group_new {
   my($min,$aref)=@_;
   ref $aref and ref $aref eq 'ARRAY' or croak("Argument is not an array ref");
   (($min >=0) and ($min <= 1)) or croak("min similarity must be between 0.00 and 1.00");

   my @elements = @$aref; # COPY it

   my @groups;


   my $i = 0;
   
   ELEMENT:  while ( my $element = shift @elements ) {
      defined $element or next ELEMENT;
   
      #$DEBUG and (printf STDERR "iteration: %s %-80s\n", $i++, "'$element'");
      
      my @possible_group;
      
      
      TEST: for my $index ( 0 .. (scalar @elements - 1)){

         my $element_being_tested = $elements[$index];                  
         defined $element_being_tested or next TEST;

         my $score = similarity( $element, $element_being_tested, $min );

         #$DEBUG and print STDERR "Test [t$min:s$score] index($index) [$element][$element_being_tested]\n";

         $score >= $min or next TEST; 
         $DEBUG and warn(" + $element == $element_being_tested\n");         
         $DEBUG and warn(" + [t$min:s$score] index($index) [$element][$element_being_tested]\n\n");
      
         #(similarity( $element, $elements[$index], $min ) > $min) or next TEST;
         
         push @possible_group, $element_being_tested;
         $elements[$index] = undef; # undef it
      }

      # did we have matches?
      if( @possible_group and scalar @possible_group){
         push @possible_group, $element;
         push @groups, \@possible_group;
      }      
            
      $DEBUG and ( printf STDERR "group length: %s\n%s\n", scalar @possible_group, '-'x60 );
   }

   wantarray ? (@groups) : \@groups;
}




sub loners { map { $_->[0] } grep { scalar @$_ == 1 } values %{_group_medium(@_)} }
sub groups      { grep { scalar @$_  > 1 } values %{_group_medium(@_)} }
sub groups_hard { grep { scalar @$_  > 1 } values %{_group_hard(@_)}   }
sub groups_lazy { grep { scalar @$_  > 1 } values %{_group_lazy(@_)}   }






sub similarest { # may return undef   
   my ( $aref, $string, $min )= @_;   
   (ref $aref eq 'ARRAY') and (defined $string) or croak("bad arguments");
  
   my $high_score = 0;
   if( $min ){ $high_score = $min; $high_score-=0.01 }

   my $high_element = undef;
   
   for ( @$aref ){      
      my $score = similarity( $_, $string, $high_score ); #> $high_score or next;
      #my $score = similarity( $_, $string, $high_score ) or next;
      ( $score > $high_score ) or next;
      $high_score = $score;
      $high_element = $_;   
   }
    
   $high_element or return;      
   wantarray ? ( $high_element, $high_score ) : $high_element;
}


sub sort_by_similarity {
   my ($aref, $string, $min ) = @_;
   ref $aref and ref $aref eq 'ARRAY' or croak("First argument is array ref");
   defined $string or croak("missing string to test to");
   #$min ||=0;

   # rank them all first
   my %score;
   for my $element (@$aref){

      my $score = similarity( $element, $string, $min );
      $score ||= 0;      

      #(printf STDERR "%s %-18s min:%s, got:%0.2f\n", $string, $element, $min, $score) if $DEBUG;
      if ( defined $min ){
         $score >= $min or next;
      }

      $score{$element} = $score;      
   }  

   my @sorted = sort { $score{$b} <=> $score{$a} } keys %score;#@$aref;
   wantarray ? @sorted : \@sorted;
}


1;

__END__
see lib/String/Similarity/Group.pod
