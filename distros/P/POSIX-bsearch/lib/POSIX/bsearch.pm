package POSIX::bsearch;

use 5.000;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT 
   $a $b $index $count);
@ISA = qw(Exporter);
@EXPORT = qw( bsearch );

$VERSION = '0.02';


sub bsearch(&$\@){
 # warn "in bsearch with args [@_]";
 my $comparator = shift;
 my ($ca,$cb);
 {
   no strict 'refs';
   my $callerpackage = caller();
   $ca = \*{"$callerpackage\::a"};
   $cb = \*{"$callerpackage\::b"};
 };
 local *$ca = \$a;
 local *$cb = \$b;
 $a = shift;
 my $table = shift;
 undef($count);
 my ($lowerbound,$first,$last,$upperbound) = (-1,-1,-1,0+@$table);
 $upperbound or return (); # empty list
 
 my ($guess,$compres);

 # find index
 our $icount = 0;
 do {{
    # warn join ', ',$lowerbound,$first,$last,$upperbound;
    $icount++ > 40 and die "STUCK";
    $guess = int (($upperbound + $lowerbound)/2);
    if ($guess == $lowerbound){
       $index = $lowerbound;
       return ();
    }; 
    $b = $table->[$guess];
    $compres =  &$comparator;
    # warn "got $compres";
    if ($compres < 0){
       unless ($guess){
           # guess is zero! we are off the low end
	   $index = -1;
	   return ();
       };
       $upperbound = $guess;
       next;
    };
    if ($compres > 0){
       if ($guess == $#$table){
           # we are off the high end
	   $index = @$table;
	   return ();
       };
       $lowerbound = $guess;
       next;
    };
 }} while ($compres);

 # Found something. POSIX semantics actually stops here. 
 wantarray or return $table->[$guess];

 # call in array context for the special sauce.
 ($index,$count) =(-1,0); 
 my $GoodGuess = $guess;
 if ($guess ==  1+$lowerbound){
       $first = $guess;
 }else{
       # search for the first
       my $upperboun =  $guess;
       $icount = 0;
       for(;;){
    $icount++ > 40 and die "STUCK";
         # warn join ', ',SearchingForFirst =>$lowerbound,$first,$last,$upperboun;
         $guess = int (( $upperboun + $lowerbound ) /2);
         if ($guess == $lowerbound){
            
            $first = $upperboun;
            last;
         }; 
         $b = $table->[$guess];
         $compres =  &$comparator;
         # warn "got $compres";
         if ($compres < 0){
            die "TABLE NOT SORTED\n";
         };
         if ($compres > 0){
            $lowerbound = $guess;
            next;
         };
         if ($guess == 1+ $lowerbound){
            $first = $guess;
            last;
         };
         $upperboun = $guess;
      };
 };


 $guess = $GoodGuess;
 if ($guess ==  -1+$upperbound){
       $last = $guess;
 }else{
       # search for the last
       my $lowerboun =  $guess;
       $icount = 0;
       for(;;){
    $icount++ > 40 and die "STUCK";
         # warn join ', ',SearchingForLast =>$lowerboun,$first,$last,$upperbound;
         $guess = int (( $upperbound + $lowerboun ) /2);
         $b = $table->[$guess];
         $compres =  &$comparator;
         # warn "got $compres";
         if ($compres > 0){
            die "TABLE NOT SORTED\n";
         };
         if ($compres < 0){
            $upperbound = $guess;
            next;
         };
         if ($guess == -1+ $upperbound){
            $last = $guess;
            last;
         };
         $lowerboun = $guess;
       };
 };
 # warn "finished, should have $lowerbound < $first <= $last < $upperbound";
          

 $index = $first;
 $count = 1 + $last - $first;


 # return result
 @$table[ $first .. $last ];
}

1;
__END__

=head1 NAME

POSIX::bsearch - supplies (and extends) a function missing from the L<POSIX> module

=head1 SYNOPSIS

C<bsearch(\&SortFunc,$key,@SortedTable)> returns a possibly empty list of all
elements from the sorted list matching $key according to the sort function.

In scalar context, the first matching element located is returned
and the C<$POSIX::bsearch::count> variable is left alone.

  use POSIX::bsearch;
  sub SortFunc {
     $a->{lastname} cmp $b->{lastname} or
     $a->{firstname} cmp $b->{firstname}
  }
  my @SortedList = sort SortFunc GetRecords();
  for ( bsearch
      \&SortFunc   # a block would work too
      { lastname => 'Strummer', firstname => 'Joe' },  # key record
      @SortedList, # uses \@ prototype
  ){
      $_->{city} eq 'London' and $_->PrintRecord
  };
  print "Found $POSIX::bsearch::count ";
  print "Joes Strummer starting at index $POSIX::bsearch::index\n";
  

=head1 DESCRIPTION

Generally, in Perl, you don't need C<bsearch> as we prefer to keep our
data in hash tables rather than in sorted lists. So the L<POSIX> module
explicitly does not supply a bsearch function.

But here one is. In case you want, for instance, a range of consecutive
records.

The function takes three arguments, a comparison function, a key, and a
sorted array.  Side effects include setting the C<$POSIX::bsearch::count>
and C<$POSIX::bsearch::index> variables.

Results and behavior are not defined when applying this function to a list
that is not sorted congruently with the provided comparison function. You
might get a C<TABLE NOT SORTED> exception, you might get results.

=head1 POSIX SEMANTICS

Call C<bsearch> in scalar context to get any matching element.

=head1 EXTENDED SEMANTICS

Call C<bsearch> in list context to trigger the extended semantics. Futher
exploration of the table is done to find the first and last matching
elements. All matching elements are returned in the result set, and two
package variables are set.

=head2 C<$POSIX::bsearch::index>
Set in both scalar and array context, C<$POSIX::bsearch::index> holds
the index of the first record that gives a nonnegative
comparison result, or -1 when the key is under the 0th
element, or the array length when over the last.

=head2 C<$POSIX::bsearch::count>

the number of records that give zero comparison result

undefined when called in scalar context


=head2 reentrancy

it should be possible to call bsearch within another bsearch's comparison
function, although this feature is not explicitly checked in this
revision's .t file. The index and count variables will be from the last
completed bsearch called in array context.

=head2 EXPORT

C<bsearch>

=head1 HISTORY

initial version 0.01 written March 4, 2010, in response to a discussion on
the perl 5 porters mailng list concerning possible perl uses for bsearch.

version 0.02 edited August 23, 2010, now handles a key that is previous to
the first element in the sorted list, also handles larger lists without
claiming to be stuck, also sets C<$POSIX::bsearch::index> indicatively
when the key is over or under the data range.
Stefane Leforestier kindly brought the bug to my attention.

=head1 SEE ALSO

look into "Schwarz-Gutman transform" to see the generally recognized
best practice for sorting objects by creating a unique string for each
object and sorting the strings.

=head1 AUTHOR

David Nicol

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by David Nicol / Tipjar LLC

This work is licensed under the Creative Commons Attribution
3.0 Unported License. To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/ or send a letter to Creative
Commons, 171 Second Street, Suite 300, San Francisco, California,
94105, USA.

Leaving this section of the documentation in your installed copy of
this module intact is sufficient attribution. A source code comment
mentioning the POSIX::bsearch module from CPAN is sufficient attribution
in derivative works.

=cut
