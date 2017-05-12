package Statistics::ChisqIndep;

use strict;
use vars qw ($VERSION $AUTOLOAD);
use Carp;
use Statistics::Distributions qw (chisqrprob);

my %fields = (obs => [], 
              expected => [],
              rows => 0,
              cols => 0, 
              df => 0,
              total => 0,
              rtotals => [],
              ctotals => [], 
              chisq_statistic  => 0,
              p_value => 0,
              valid => 0, 
              warning => 0);
$VERSION = '0.1';

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self= {%fields};
  bless($self,$class);
  return $self;
}

sub load_data {
  my $self = shift;
  $self->{valid} = 0;
  $self->{obs} = shift;
  my @obs = @{$self->{obs}};
  my $exp;
  my $rows = scalar(@obs); 
  return if $rows < 2;
  my $cols = scalar(@{$obs[0]}); 
  return if $cols < 2;
  my @rtotals;
  my @ctotals;
  my $total = 0;
  my $df = 0;
  my $chisq = 0;
  my $chiprob = 0;
  for (my $i = 0; $i < $rows; $i++) {
     my $c = scalar(@{$obs[$i]});
     return if $c != $cols;
     for (my $j = 0; $j < $cols; $j++) {
        $rtotals[$i] = 0 if (!defined($rtotals[$i]));
        $ctotals[$j] = 0 if (!defined($ctotals[$j]));
        $rtotals[$i] += $obs[$i]->[$j];
        $ctotals[$j] += $obs[$i]->[$j];
        $total += $obs[$i]->[$j];
        $self->{warning} = 1 if $obs[$i]->[$j] < 25;
     }
  }   
  return if ($total < 0); 


  #compute the expected values for each cell
  for (my $i = 0; $i < $rows; $i++) {
    for (my $j = 0; $j < $cols; $j++) {
        if ($rtotals[$i] == 0 || $ctotals[$j] == 0) {
            $exp->[$i]->[$j] = 0
        } else {
            $exp->[$i]->[$j] = $rtotals[$i] * $ctotals[$j] / $total;  
            $chisq += ($obs[$i]->[$j] - $exp->[$i]->[$j])**2 /$exp->[$i]->[$j]; 
        }
    }
  }
   
  $df = ($rows - 1) * ($cols - 1);
  $chiprob = chisqrprob($df, $chisq); 

  #update the global fields
  $self->{expected} = $exp;
  $self->{rows} = $rows;
  $self->{cols} = $cols;
  $self->{df} = $df;
  $self->{total} = $total;
  $self->{rtotals} = \@rtotals;
  $self->{ctotals} = \@ctotals;
  $self->{chisq_statistic} = $chisq;
  $self->{p_value} = $chiprob;
  $self->{valid} = 1;
   
  return 1; 
}

sub print_contingency_table {
  my $self = shift;  
  my $rows = $self->{rows};
  my $cols = $self->{cols};
  my $obs = $self->{obs};
  my $exp = $self->{expected};
  my $rtotals = $self->{rtotals};
  my $ctotals = $self->{ctotals};
  my $total = $self->{total};
  
  for (my $j = 0; $j < $cols; $j++) {
    print "\t",$j + 1;
  }
  print "\trtotal\n"; 
  for (my $i = 0; $i < $rows; $i ++) {
    print $i + 1, "\t"; 
    for(my $j = 0 ; $j < $cols; $j ++) {
      print $obs->[$i]->[$j], "\t";
    }
    print $rtotals->[$i], "\n";
    print "\t";
    for(my $j = 0 ; $j < $cols; $j ++) {
      printf "(%.2f)\t", $exp->[$i]->[$j];
    }
    print "\n"; 
  }
  print "ctotal\t";
  for (my $j = 0; $j < $cols; $j++) {
    print $ctotals->[$j], "\t";
  }
  print $total, "\n";
}

sub print_summary {
  my $self = shift;
  if($self->{valid}) {
    print "Rows: ", $self->{rows}, "\n"; 
    print "Columns: ", $self->{cols}, "\n"; 
    print "Degree of Freedom: ", $self->{df}, "\n";
    print "Total Count: ", $self->{total}, "\n";
    print "Chi-square Statistic: ", $self->{chisq_statistic}, "\n";
    print "p-value: ", $self->{p_value}, "\n";
    print "Warning: some of the cell counts might be too low. \n" if ($self->{warning});
    $self->print_contingency_table();
  }
}

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;     ##Strip fully qualified-package portion
  return if $name eq "DESTROY";
  unless (exists $self->{$name} ) {
    croak "Can't access `$name' field in class $type";
  }
  ##Read only method
  return $self->{$name};
}

1;
__END__

=head1 Name

Statistics::ChisqIndep - The module to perform chi-square test of independence (a.k.a. contingency tables) 

=head1 Synopsis

 #example for Statistics::ChisqIndep
 use strict;
 use Statistics::ChisqIndep;
 use POSIX;
 # input data in the form of the array of array references
 my @obs = ([15, 68, 83], [23,47,65]);
 my $chi = new Statistics::ChisqIndep;
 $chi->load_data(\@obs);
 # print the summary data along with the contingency table
 $chi->print_summary();  
 #print the contingency table only
 $chi->print_contingency_table(); 
 #the following output is the same as calling the function of print_summary
 #all of the detailed info such as the expected values, degree of freedoms 
 #and totals are accessible as object globals  
 #check if the load_data() call is successful
 if($chi->{valid}) {  
   print "Rows: ", $chi->{rows}, "\n"; 
   print "Columns: ", $chi->{cols}, "\n"; 
   print "Degree of Freedom: ", $chi->{df}, "\n";
   print "Total Count: ", $chi->{total}, "\n";
   print "Chi-square Statistic: ", 
         $chi->{chisq_statistic}, "\n";
   print "p-value: ", $chi->{p_value}, "\n";
   print "Warning: 
         some of the cell counts might be too low.\n" 
     if ($chi->{warning});
   #output the contingency table
   my $rows = $chi->{rows};  # # rows
   my $cols = $chi->{cols};  # # columns
   my $obs = $chi->{obs}; # observed values 
   my $exp = $chi->{expected}; # expected values 
   my $rtotals = $chi->{rtotals}; # row totals 
   my $ctotals = $chi->{ctotals}; #column totals 
   my $total = $chi->{total}; # total counts
   for (my $j = 0; $j < $cols; $j++) {
     print "\t",$j + 1;
   }
   print "\trtotal\n"; 
   for (my $i = 0; $i < $rows; $i ++) {
     print $i + 1, "\t"; 
     for(my $j = 0 ; $j < $cols; $j ++) {
      #observed values can be accessed
      #in the following way 
      print $obs->[$i]->[$j], "\t";  
     }
     #row totals can be accessed
     # in the following way
     print $rtotals->[$i], "\n";
     print "\t";
     for(my $j = 0 ; $j < $cols; $j ++) {
      #expected values can be accessed 
      #in the following way
      printf "(%.2f)\t", $exp->[$i]->[$j];
     }
     print "\n"; 
   }
   print "ctotal\t";
   for (my $j = 0; $j < $cols; $j++) {
     #column totals can be accessed in the following way
     print $ctotals->[$j], "\t";
   }
   #output total counts
   print $total, "\n";
 }

=head1 Description
 
 This is the module to perform the Pearson's Chi-squared test on contingency tables of 2 dimensions. The users input the observed values in the table form and the module will compute the expected values for each cell based on the independence hypothesis. The module will then compute the chi-square statistic and the corresponding p-value based on the observed and the expected values to test if the 2 dimensions are truly independent.  

=head1 AUTHOR

 Yun-Fang Juan , Yahoo! Inc. 
 yunfang@yahoo-inc.com 
 yunfangjuan@yahoo.com

=head1 SEE ALSO

Statistics::Distributions

=cut


