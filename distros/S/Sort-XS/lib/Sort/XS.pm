package Sort::XS;
use strict;
use warnings;
use base Exporter::;
our @EXPORT = qw(xsort ixsort sxsort);

our $VERSION = '0.30';
require XSLoader;
XSLoader::load( 'Sort::XS', $VERSION );
use Carp qw/croak/;

use constant ERR_MSG_NOLIST           => 'Need to provide a list';
use constant ERR_MSG_UNKNOWN_ALGO     => 'Unknown algorithm : ';
use constant ERR_MSG_NUMBER_ARGUMENTS => 'Bad number of arguments';
my $_mapping = {
    quick     => \&Sort::XS::quick_sort,
    heap      => \&Sort::XS::heap_sort,
    merge     => \&Sort::XS::merge_sort,
    insertion => \&Sort::XS::insertion_sort,
    perl      => \&_perl_sort,

    # string sorting
    quick_str     => \&Sort::XS::quick_sort_str,
    heap_str      => \&Sort::XS::heap_sort_str,
    merge_str     => \&Sort::XS::merge_sort_str,
    insertion_str => \&Sort::XS::insertion_sort_str,
    perl_str      => \&_perl_sort_str,
};

# API to call XS subs

sub xsort {

    # shortcut to speedup API usage, we first advantage preferred usage
    # ( we could avoid it... but we want to provide an api as fast as possible )
    my $argc = scalar @_;
    if ( $argc == 1 ) {
        croak ERR_MSG_NOLIST unless ref $_[0] eq ref [];
        return Sort::XS::quick_sort( $_[0] );
    }

    # default parameters
    my %params;
    $params{algorithm} = 'quick';

    # default list
    $params{list} = $_[0];

    croak ERR_MSG_NOLIST unless $params{list};
    my %args;
    unless ( ref $params{list} eq ref [] ) {

        # hash input
        croak ERR_MSG_NUMBER_ARGUMENTS if $argc % 2;
        (%args) = @_;
        croak ERR_MSG_NOLIST
          unless defined $args{list} && ref $args{list} eq ref [];
        $params{list} = $args{list};
    }
    else {

        # first element was the array, then hash option
        croak ERR_MSG_NUMBER_ARGUMENTS unless scalar @_ % 2;
        my $void;
        ( $void, %args ) = @_;
    }
    map { $params{$_} = $args{$_} || $params{$_}; } qw/algorithm type/;

    my $type =
      ( defined $params{type} && $params{type} eq 'string' ) ? '_str' : '';
    my $sub = $_mapping->{ $params{algorithm} . $type };
    croak( ERR_MSG_UNKNOWN_ALGO, $params{algorithm} ) unless defined $sub;

    return $sub->( $params{list} );
}

# shortcut to xsort with integers
sub ixsort {
    xsort(@_);
}

# shortcut to xsort with strings
sub sxsort {
    xsort( @_, type => 'string' );
}

sub _perl_sort {
    my $list = shift;
    my @sorted = sort { $a <=> $b } @{$list};
    return \@sorted;
}

sub _perl_sort_str {
    my $list = shift;
    my @sorted = sort { $a cmp $b } @{$list};
    return \@sorted;
}

1;

__END__

=head1 NAME

Sort::XS - a ( very ) fast XS sort alternative for one dimension list

=head1 SYNOPSIS

  use Sort::XS qw/xsort/;

  # use it simply
  my $sorted = xsort([1, 5, 3]);
  $sorted = [ 1, 3, 5 ];
  
  # personalize your xsort with some options
  my $list = [ 1..100, 24..42 ]
  my $sorted = xsort( $list ) or ixsort( $list )
            or xsort( list => $list )
            or xsort( list => $list, algorithm => 'quick' )
            or xsort( $list, algorithm => 'quick', type => integer )
            or xsort( list => $list, algorithm => 'heap', type => 'integer' ) 
            or xsort( list => $list, algorithm => 'merge', type => 'string' );
   
   # if you [ mainly ] use very small arrays ( ~ 10 rows ) 
   #    prefer using directly one of the XS subroutines
   $sorted = Sort::XS::quick_sort( $list )
        or Sort::XS::heap_sort($list)
        or Sort::XS::merge_sort($list)
        or Sort::XS::insertion_sort($list);
    
    # sorting array of strings
    $list = [ 'kiwi', 'banana', 'apple', 'cherry' ];
    $sorted = sxsort( $list )
        or sxsort( [ $list ], algorithm => 'quick' )
        or sxsort( [ $list ], algorithm => 'heap' )
        or sxsort( [ $list ], algorithm => 'merge' );
    
    # use direct XS subroutines to sort array of strings 
    $sorted = Sort::XS::quick_sort_str( $list )
        or Sort::XS::heap_sort_str($list)
        or Sort::XS::merge_sort_str($list)
        or Sort::XS::insertion_sort_str($list);
            
    
=head1 DESCRIPTION

This module provides several common sort algorithms implemented as XS.
Sort can only be used on one dimension list of integers or strings.

It's goal is not to replace the internal sort subroutines, but to provide a better alternative in some specifics cases :

=over 2

=item - no need to specify a comparison operator

=item - sorting a mono dimension list

=back


=head1 ALGORITHMS

Quicksort has been chosen as the default method ( even if it s not a stable algorithm ), you can also consider to use heapsort which provides a worst case in "n log n".

Choosing the correct algorithm depends on distribution of your values and size of your list.
Quicksort provides an average good solution, even if in some case it will be better to use a different choice.

=head2 quick sort

This is the default algorithm. 
In pratice it provides the best results even if in worst case heap sort will be a better choice.

read http://en.wikipedia.org/wiki/Quicksort for more informations

=head2 heap sort

A little slower in practice than quicksort but provide a better worst case runtime.

read http://en.wikipedia.org/wiki/Heapsort for more informations

=head2 merge sort

Stable sort algorithm, that means that in any case the time to compute the result will be similar.
It's still a better choice than the internal perl sort.

read http://en.wikipedia.org/wiki/Mergesort for more informations

=head2 insertion sort

Provide one implementation of insertion sort, but prefer using either any of the previous algorithm or even the perl internal sort.

read http://en.wikipedia.org/wiki/Mergesort for more informations

=head2 perl

this is not an algorithm by itself, but provides an easy way to disable all XS code by switching back to a regular sort.

Perl 5.6 and earlier used a quicksort algorithm to implement sort. 
That algorithm was not stable, so could go quadratic. (A stable sort preserves the input order of elements that compare equal. 
Although quicksort's run time is O(NlogN) when averaged over all arrays of length N, the time can be O(N**2), 
quadratic behavior, for some inputs.) 

In 5.7, the quicksort implementation was replaced with a stable mergesort algorithm whose worst-case behavior is O(NlogN). 
But benchmarks indicated that for some inputs, on some platforms, the original quicksort was faster. 

5.8 has a sort pragma for limited control of the sort. Its rather blunt control of the underlying algorithm may not persist into future Perls, 
but the ability to characterize the input or output in implementation independent ways quite probably will.

use default perl version

=head1 METHODS

=head2 xsort

API that allow you to use one of the XS subroutines. Prefer using this method. ( view optimization section for tricks )

=over 4

=item list

provide a reference to an array
if only one argument is provided can be ommit

    my $list = [ 1, 3, 2, 5, 4 ];
    xsort( $list ) or xsort( list => $list )

=item algorithm [ optional, default = quick ]

default value is quick
you can use any of the following choices

    quick # quicksort
    heap  # heapsort
    merge
    insertion # not recommended ( slow )
    perl # use standard perl sort method instead of c implementation

=item type [ optional, default = integer ]

You can specify which kind of sort you are expecting ( i.e. '<=>' or 'cmp' ) by setting this attribute to one of these two values

    integer # <=>, is the default operator if not specified
    string  # cmp, do the compare on string

=back

=head2 ixsort

alias on xsort method but force type to integer comparison
same usage as xsort

=head2 sxsort

alias on xsort method but force type to string comparison
same usage as xsort

=head2  quick_sort   

XS subroutine to perform the quicksort algorithm. No type checking performed.
Accept only one single argument as input.

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::quick_sort($list);
    
=head2  heap_sort

XS subroutine to perform the heapsort algorithm. No type checking performed.
Accept only one single argument as input.    

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::heap_sort($list);
    
=head2  merge_sort

XS subroutine to perform the mergesort algorithm. No type checking performed.
Accept only one single argument as input.    
    
    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::merge_sort($list)
    
=head2  insertion_sort    

XS subroutine to perform the insertionsort algorithm. No type checking performed.
Accept only one single argument as input.    

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::insertion_sort($list);

=head2 quick_sort_str

XS subroutine to perform quicksort on array of strings.

    Sort::XS::quick_sort_str( [ 'aa' .. 'zz' ] );
    
=head2 heap_sort_str

XS subroutine to perform heapsort on array of strings.

    Sort::XS::heap_sort_str( [ 'aa' .. 'zz' ] );

=head2 merge_sort_str

XS subroutine to perform mergesort on array of strings.

    Sort::XS::merge_sort_str( [ 'aa' .. 'zz' ] );

=head2 insertion_sort_str

XS subroutine to perform insertionsort on array of strings.

    Sort::XS::insertion_sort_str( [ 'aa' .. 'zz' ] );

=head1 OPTIMIZATION

xsort provides an api to call xs subroutines to easy change sort preferences and an easy way to use it ( adding minimalist type checking )
as it provides an extra layer on the top of xs subroutines it has a cost... and adds a little more slowness...
This extra cost cannot be noticed on large arrays ( > 100 rows ), but for very small arrays ( ~ 10 rows ) it will not a good idea to use the api ( at least at this stage ). 
In this case you will prefer to do a direct call to one of the XS methods to have pure performance.

Note that all the XS subroutines are not exported by default. 

    my $list = [1, 6, 4, 2, 3, 5 ]
    Sort::XS::quick_sort($list);
    Sort::XS::heap_sort($list);
    Sort::XS::merge_sort($list)
    Sort::XS::insertion_sort($list);

Once again, if you use large arrays, it will be better to use API calls :

    xsort([5, 7, 1, 4]);
    ixsort([1..10]);
    sxsort(['a'..'z']);

=head1 BENCHMARK

Here is a glance of what you can expect from this module :
These results have been computed on a set of multiple random arrays generated by the benchmark test included in the dist testsuite.

Results are splitted in two parts : integers and strings.
Here is a short definition for each label used for these benchmarks.

    [ integers ]
    * Perl                  : reference test with perl internal sort sub : sort { $a <=> $b } @array;
    * API Perl              : use native sort perl method thru API ; xsort(list => $array, algorithm => 'perl');      
    * API quick             : use quicksort via API ; xsort($array);         
    * API quick with hash   : use xsort method with additonnal parameters ; xsort(list => $array, algorithm => 'quick', type => 'integer');
    * isort                 : use isort method from Key::Sort module ; 
    * isort radix           : use isort method from Sort::Key::Radix module ; 
    * XS heap               : direct call to the xs method ; Sort::XS::heap_sort($array);
    * XS merge              : direct call to the xs method ; Sort::XS::merge_sort($array);       
    * XS quick              : direct call to the xs method ; Sort::XS::quick_sort($array);
    * void                  : a void sub used as baseline

Comparing "Perl" vs "API Perl" or "API quick" vs "XS quick" gives an idea of the extra cost of the API
Perl and void bench are here as a baseline.
    
    [ strings ]
    * Perl          : native perl sort method : sort { $a cmp $b } @array;
    * API sxsort    : use sxsort method ; sxsort($array);    
    * keysort       : use keysort method from Key::Sort module ; keysort { $_ } @$array; 
    * XS heap       : direct call to the xs method ; Sort::XS::heap_sort_str($array);
    * XS merge      : direct call to the xs method ; Sort::XS::merge_sort_str($array);
    * XS quick      : direct call to the xs method ; Sort::XS::quick_sort_str($array);
    
=head2 Small arrays

Small arrays are arrays with around 10 elements.
benchmark with 1000 arrays of 10 rows

        [ integers ]         Rate       API quick with hash       API Perl       API quick       XS merge       isort radix       XS quick       heap       isort void       Perl
        API quick with hash 130/s                        --            -7%            -67%           -74%              -77%           -78%       -78%        -80% -83%       -84%
        API Perl            140/s                        7%             --            -64%           -72%              -75%           -76%       -76%        -78% -81%       -82%
        API quick           390/s                      200%           179%              --           -22%              -31%           -33%       -33%        -39% -48%       -51%
        XS merge            502/s                      287%           260%             29%             --              -11%           -13%       -14%        -21% -33%       -37%
        isort radix         564/s                      335%           304%             45%            12%                --            -3%        -3%        -11% -25%       -29%
        XS quick            580/s                      346%           315%             49%            15%                3%             --        -0%         -9% -23%       -27%
        heap                581/s                      348%           317%             49%            16%                3%             0%         --         -9% -23%       -27%
        isort               636/s                      390%           356%             63%            27%               13%            10%         9%          -- -15%       -20%
        void                752/s                      479%           439%             93%            50%               33%            30%        29%         18%   --        -5%
        Perl                794/s                      512%           469%            104%            58%               41%            37%        37%         25%   6%         --
        
         [ sting ]  Rate       API sxsort       keysort       Perl       XS merge       XS heap       XS quick
        API sxsort 106/s               --           -8%       -59%           -59%          -62%           -63%
        keysort    116/s               9%            --       -55%           -55%          -58%           -60%
        Perl       260/s             145%          124%         --            -0%           -7%           -10%
        XS merge   260/s             145%          124%         0%             --           -7%           -10%
        XS heap    278/s             162%          140%         7%             7%            --            -4%
        XS quick   289/s             172%          149%        11%            11%            4%             --

=head2 Medium arrays

A mixed of arrays with 10, 100 and 1000 rows. ( 10 arrays of each size, maybe this should match most common usages ? ).

        [ integers ]          Rate       API Perl       Perl       XS merge       isort       heap       API quick with hash       API quick       XS quick       isort radix void
        API Perl             429/s             --       -13%           -16%        -20%       -24%                      -25%            -33%           -35%              -40% -73%
        Perl                 493/s            15%         --            -4%         -8%       -12%                      -14%            -23%           -25%              -32% -68%
        XS merge             511/s            19%         4%             --         -5%        -9%                      -11%            -20%           -22%              -29% -67%
        isort                536/s            25%         9%             5%          --        -5%                       -7%            -16%           -18%              -26% -66%
        heap                 562/s            31%        14%            10%          5%         --                       -2%            -12%           -14%              -22% -64%
        API quick with hash  575/s            34%        17%            13%          7%         2%                        --            -10%           -12%              -20% -63%
        API quick            638/s            48%        29%            25%         19%        13%                       11%              --            -3%              -12% -59%
        XS quick             657/s            53%        33%            29%         23%        17%                       14%              3%             --               -9% -58%
        isort radix          722/s            68%        46%            41%         35%        28%                       25%             13%            10%                -- -54%
        void                1562/s           264%       217%           206%        191%       178%                      172%            145%           138%              117%   --
        
        [ sting ]    Rate       keysort       API sxsort       Perl       XS heap       XS merge       XS quick
        keysort     770/s            --             -47%       -48%          -57%           -57%           -62%
        API sxsort 1450/s           88%               --        -2%          -19%           -20%           -28%
        Perl       1476/s           92%               2%         --          -18%           -18%           -27%
        XS heap    1790/s          132%              23%        21%            --            -1%           -11%
        XS merge   1806/s          135%              25%        22%            1%             --           -10%
        XS quick   2017/s          162%              39%        37%           13%            12%             --


Sorting arrays of 100.000 rows

                            Rate         API Perl       Perl       isort       heap       XS merge       XS quick       API quick with hash       API quick       isort radix void
        API Perl            3.03/s             --        -1%         -6%       -22%           -24%           -42%                      -42%            -43%              -59% -82%
        Perl                3.07/s             1%         --         -5%       -21%           -23%           -41%                      -41%            -43%              -58% -82%
        isort               3.21/s             6%         5%          --       -18%           -20%           -38%                      -39%            -40%              -56% -81%
        heap                3.90/s            29%        27%         21%         --            -2%           -25%                      -25%            -27%              -47% -77%
        XS merge            4.00/s            32%        30%         24%         2%             --           -23%                      -24%            -25%              -46% -76%
        XS quick            5.20/s            72%        70%         62%        33%            30%             --                       -1%             -3%              -30% -69%
        API quick with hash 5.23/s            73%        71%         63%        34%            31%             1%                        --             -2%              -29% -69%
        API quick           5.36/s            77%        75%         67%        37%            34%             3%                        2%              --              -27% -68%
        isort radix         7.39/s           144%       141%        130%        89%            85%            42%                       41%             38%                -- -56%
        void                16.9/s           459%       453%        427%       334%           323%           226%                      224%            216%              129%   --

=head2 Large arrays

Sorting arrays of 1.000.000 rows.

        [ integers ]          Rate       API Perl       Perl       isort       heap       XS merge       isort radix       XS quick       API quick       API quick with hash void
        API Perl            1.75/s             --        -0%        -22%       -40%           -48%              -48%           -61%            -61%                      -62% -89%
        Perl                1.76/s             0%         --        -22%       -40%           -47%              -48%           -61%            -61%                      -62% -89%
        isort               2.25/s            28%        28%          --       -23%           -33%              -33%           -49%            -50%                      -51% -86%
        heap                2.94/s            67%        67%         30%         --           -12%              -13%           -34%            -35%                      -36% -82%
        XS merge            3.35/s            91%        90%         49%        14%             --               -1%           -25%            -25%                      -27% -79%
        isort radix         3.37/s            92%        92%         50%        15%             1%                --           -24%            -25%                      -26% -79%
        XS quick            4.46/s           154%       154%         98%        52%            33%               32%             --             -1%                       -3% -73%
        API quick           4.48/s           156%       155%         99%        53%            34%               33%             1%              --                       -2% -72%
        API quick with hash 4.57/s           161%       160%        103%        56%            37%               36%             3%              2%                        -- -72%
        void                16.2/s           826%       824%        621%       453%           385%              382%           264%            262%                      255%   --

       [ sting ]      Rate       Perl       XS heap       XS merge       API sxsort       XS quick
        Perl       0.698/s         --          -17%           -47%             -52%           -52%
        XS heap    0.836/s        20%            --           -37%             -43%           -43%
        XS merge    1.32/s        90%           58%             --             -10%           -10%
        API sxsort  1.46/s       110%           75%            11%               --            -0%
        XS quick    1.47/s       110%           76%            11%               0%             --
  

=head1 CONTRIBUTE

You can contribute to this project via GitHub :
    https://github.com/atoomic/Sort-XS

=head1 TODO

Implementation of float comparison...
At this time only implement sort of integers and strings

Improve API performance for small set of arrays : could use enum and array to speedup API.
C algorithms can be also tuned.

=head1 AUTHOR

Nicolas R., E<lt>me@eboxr.comE<gt>

=head1 CONTRIBUTORS

Salvador Fandi–o

=head1 SEE ALSO

Also consider the modules Sort::Key and Sort::Key::Radix, that provide a different API but that can sort faster on many common usage.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by eboxr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
