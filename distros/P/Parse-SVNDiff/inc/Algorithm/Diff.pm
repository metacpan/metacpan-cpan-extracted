#line 1 "inc/Algorithm/Diff.pm - /usr/local/lib/perl5/site_perl/5.8.7/Algorithm/Diff.pm"
package Algorithm::Diff;
# Skip to first "=head" line for documentation.
use strict;

use integer;    # see below in _replaceNextLargerWith() for mod to make
                # if you don't use this
use vars qw( $VERSION @EXPORT_OK );
$VERSION = 1.19_01;
#          ^ ^^ ^^-- Incremented at will
#          | \+----- Incremented for non-trivial changes to features
#          \-------- Incremented for fundamental changes
require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw(
    prepare LCS LCDidx LCS_length
    diff sdiff compact_diff
    traverse_sequences traverse_balanced
);

# McIlroy-Hunt diff algorithm
# Adapted from the Smalltalk code of Mario I. Wolczko, <mario@wolczko.com>
# by Ned Konz, perl@bike-nomad.com
# Updates by Tye McQueen, http://perlmonks.org/?node=tye

# Create a hash that maps each element of $aCollection to the set of
# positions it occupies in $aCollection, restricted to the elements
# within the range of indexes specified by $start and $end.
# The fourth parameter is a subroutine reference that will be called to
# generate a string to use as a key.
# Additional parameters, if any, will be passed to this subroutine.
#
# my $hashRef = _withPositionsOfInInterval( \@array, $start, $end, $keyGen );

sub _withPositionsOfInInterval
{
    my $aCollection = shift;    # array ref
    my $start       = shift;
    my $end         = shift;
    my $keyGen      = shift;
    my %d;
    my $index;
    for ( $index = $start ; $index <= $end ; $index++ )
    {
        my $element = $aCollection->[$index];
        my $key = &$keyGen( $element, @_ );
        if ( exists( $d{$key} ) )
        {
            unshift ( @{ $d{$key} }, $index );
        }
        else
        {
            $d{$key} = [$index];
        }
    }
    return wantarray ? %d : \%d;
}

# Find the place at which aValue would normally be inserted into the
# array. If that place is already occupied by aValue, do nothing, and
# return undef. If the place does not exist (i.e., it is off the end of
# the array), add it to the end, otherwise replace the element at that
# point with aValue.  It is assumed that the array's values are numeric.
# This is where the bulk (75%) of the time is spent in this module, so
# try to make it fast!

sub _replaceNextLargerWith
{
    my ( $array, $aValue, $high ) = @_;
    $high ||= $#$array;

    # off the end?
    if ( $high == -1 || $aValue > $array->[-1] )
    {
        push ( @$array, $aValue );
        return $high + 1;
    }

    # binary search for insertion point...
    my $low = 0;
    my $index;
    my $found;
    while ( $low <= $high )
    {
        $index = ( $high + $low ) / 2;

        # $index = int(( $high + $low ) / 2);  # without 'use integer'
        $found = $array->[$index];

        if ( $aValue == $found )
        {
            return undef;
        }
        elsif ( $aValue > $found )
        {
            $low = $index + 1;
        }
        else
        {
            $high = $index - 1;
        }
    }

    # now insertion point is in $low.
    $array->[$low] = $aValue;    # overwrite next larger
    return $low;
}

# This method computes the longest common subsequence in $a and $b.

# Result is array or ref, whose contents is such that
#   $a->[ $i ] == $b->[ $result[ $i ] ]
# foreach $i in ( 0 .. $#result ) if $result[ $i ] is defined.

# An additional argument may be passed; this is a hash or key generating
# function that should return a string that uniquely identifies the given
# element.  It should be the case that if the key is the same, the elements
# will compare the same. If this parameter is undef or missing, the key
# will be the element as a string.

# By default, comparisons will use "eq" and elements will be turned into keys
# using the default stringizing operator '""'.

# Additional parameters, if any, will be passed to the key generation
# routine.

sub _longestCommonSubsequence
{
    my $a        = shift;    # array ref or hash ref
    my $b        = shift;    # array ref or hash ref
    my $counting = shift;    # scalar
    my $keyGen   = shift;    # code ref
    my $compare;             # code ref

    if ( ref($a) eq 'HASH' )
    {                        # prepared hash must be in $b
        my $tmp = $b;
        $b = $a;
        $a = $tmp;
    }

    # Check for bogus (non-ref) argument values
    if ( !ref($a) || !ref($b) )
    {
        my @callerInfo = caller(1);
        die 'error: must pass array or hash references to ' . $callerInfo[3];
    }

    # set up code refs
    # Note that these are optimized.
    if ( !defined($keyGen) )    # optimize for strings
    {
        $keyGen = sub { $_[0] };
        $compare = sub { my ( $a, $b ) = @_; $a eq $b };
    }
    else
    {
        $compare = sub {
            my $a = shift;
            my $b = shift;
            &$keyGen( $a, @_ ) eq &$keyGen( $b, @_ );
        };
    }

    my ( $aStart, $aFinish, $matchVector ) = ( 0, $#$a, [] );
    my ( $prunedCount, $bMatches ) = ( 0, {} );

    if ( ref($b) eq 'HASH' )    # was $bMatches prepared for us?
    {
        $bMatches = $b;
    }
    else
    {
        my ( $bStart, $bFinish ) = ( 0, $#$b );

        # First we prune off any common elements at the beginning
        while ( $aStart <= $aFinish
            and $bStart <= $bFinish
            and &$compare( $a->[$aStart], $b->[$bStart], @_ ) )
        {
            $matchVector->[ $aStart++ ] = $bStart++;
            $prunedCount++;
        }

        # now the end
        while ( $aStart <= $aFinish
            and $bStart <= $bFinish
            and &$compare( $a->[$aFinish], $b->[$bFinish], @_ ) )
        {
            $matchVector->[ $aFinish-- ] = $bFinish--;
            $prunedCount++;
        }

        # Now compute the equivalence classes of positions of elements
        $bMatches =
          _withPositionsOfInInterval( $b, $bStart, $bFinish, $keyGen, @_ );
    }
    my $thresh = [];
    my $links  = [];

    my ( $i, $ai, $j, $k );
    for ( $i = $aStart ; $i <= $aFinish ; $i++ )
    {
        $ai = &$keyGen( $a->[$i], @_ );
        if ( exists( $bMatches->{$ai} ) )
        {
            $k = 0;
            for $j ( @{ $bMatches->{$ai} } )
            {

                # optimization: most of the time this will be true
                if ( $k and $thresh->[$k] > $j and $thresh->[ $k - 1 ] < $j )
                {
                    $thresh->[$k] = $j;
                }
                else
                {
                    $k = _replaceNextLargerWith( $thresh, $j, $k );
                }

                # oddly, it's faster to always test this (CPU cache?).
                if ( defined($k) )
                {
                    $links->[$k] =
                      [ ( $k ? $links->[ $k - 1 ] : undef ), $i, $j ];
                }
            }
        }
    }

    if (@$thresh)
    {
        return $prunedCount + @$thresh if $counting;
        for ( my $link = $links->[$#$thresh] ; $link ; $link = $link->[0] )
        {
            $matchVector->[ $link->[1] ] = $link->[2];
        }
    }
    elsif ($counting)
    {
        return $prunedCount;
    }

    return wantarray ? @$matchVector : $matchVector;
}

sub traverse_sequences
{
    my $a                 = shift;          # array ref
    my $b                 = shift;          # array ref
    my $callbacks         = shift || {};
    my $keyGen            = shift;
    my $matchCallback     = $callbacks->{'MATCH'} || sub { };
    my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { };
    my $finishedACallback = $callbacks->{'A_FINISHED'};
    my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { };
    my $finishedBCallback = $callbacks->{'B_FINISHED'};
    my $matchVector = _longestCommonSubsequence( $a, $b, 0, $keyGen, @_ );

    # Process all the lines in @$matchVector
    my $lastA = $#$a;
    my $lastB = $#$b;
    my $bi    = 0;
    my $ai;

    for ( $ai = 0 ; $ai <= $#$matchVector ; $ai++ )
    {
        my $bLine = $matchVector->[$ai];
        if ( defined($bLine) )    # matched
        {
            &$discardBCallback( $ai, $bi++, @_ ) while $bi < $bLine;
            &$matchCallback( $ai,    $bi++, @_ );
        }
        else
        {
            &$discardACallback( $ai, $bi, @_ );
        }
    }

    # The last entry (if any) processed was a match.
    # $ai and $bi point just past the last matching lines in their sequences.

    while ( $ai <= $lastA or $bi <= $lastB )
    {

        # last A?
        if ( $ai == $lastA + 1 and $bi <= $lastB )
        {
            if ( defined($finishedACallback) )
            {
                &$finishedACallback( $lastA, @_ );
                $finishedACallback = undef;
            }
            else
            {
                &$discardBCallback( $ai, $bi++, @_ ) while $bi <= $lastB;
            }
        }

        # last B?
        if ( $bi == $lastB + 1 and $ai <= $lastA )
        {
            if ( defined($finishedBCallback) )
            {
                &$finishedBCallback( $lastB, @_ );
                $finishedBCallback = undef;
            }
            else
            {
                &$discardACallback( $ai++, $bi, @_ ) while $ai <= $lastA;
            }
        }

        &$discardACallback( $ai++, $bi, @_ ) if $ai <= $lastA;
        &$discardBCallback( $ai, $bi++, @_ ) if $bi <= $lastB;
    }

    return 1;
}

sub traverse_balanced
{
    my $a                 = shift;              # array ref
    my $b                 = shift;              # array ref
    my $callbacks         = shift || {};
    my $keyGen            = shift;
    my $matchCallback     = $callbacks->{'MATCH'} || sub { };
    my $discardACallback  = $callbacks->{'DISCARD_A'} || sub { };
    my $discardBCallback  = $callbacks->{'DISCARD_B'} || sub { };
    my $changeCallback    = $callbacks->{'CHANGE'};
    my $matchVector = _longestCommonSubsequence( $a, $b, 0, $keyGen, @_ );

    # Process all the lines in match vector
    my $lastA = $#$a;
    my $lastB = $#$b;
    my $bi    = 0;
    my $ai    = 0;
    my $ma    = -1;
    my $mb;

    while (1)
    {

        # Find next match indices $ma and $mb
        do {
            $ma++;
        } while(
                $ma <= $#$matchVector
            &&  !defined $matchVector->[$ma]
        );

        last if $ma > $#$matchVector;    # end of matchVector?
        $mb = $matchVector->[$ma];

        # Proceed with discard a/b or change events until
        # next match
        while ( $ai < $ma || $bi < $mb )
        {

            if ( $ai < $ma && $bi < $mb )
            {

                # Change
                if ( defined $changeCallback )
                {
                    &$changeCallback( $ai++, $bi++, @_ );
                }
                else
                {
                    &$discardACallback( $ai++, $bi, @_ );
                    &$discardBCallback( $ai, $bi++, @_ );
                }
            }
            elsif ( $ai < $ma )
            {
                &$discardACallback( $ai++, $bi, @_ );
            }
            else
            {

                # $bi < $mb
                &$discardBCallback( $ai, $bi++, @_ );
            }
        }

        # Match
        &$matchCallback( $ai++, $bi++, @_ );
    }

    while ( $ai <= $lastA || $bi <= $lastB )
    {
        if ( $ai <= $lastA && $bi <= $lastB )
        {

            # Change
            if ( defined $changeCallback )
            {
                &$changeCallback( $ai++, $bi++, @_ );
            }
            else
            {
                &$discardACallback( $ai++, $bi, @_ );
                &$discardBCallback( $ai, $bi++, @_ );
            }
        }
        elsif ( $ai <= $lastA )
        {
            &$discardACallback( $ai++, $bi, @_ );
        }
        else
        {

            # $bi <= $lastB
            &$discardBCallback( $ai, $bi++, @_ );
        }
    }

    return 1;
}

sub prepare
{
    my $a       = shift;    # array ref
    my $keyGen  = shift;    # code ref

    # set up code ref
    $keyGen = sub { $_[0] } unless defined($keyGen);

    return scalar _withPositionsOfInInterval( $a, 0, $#$a, $keyGen, @_ );
}

sub LCS
{
    my $a = shift;                  # array ref
    my $b = shift;                  # array ref or hash ref
    my $matchVector = _longestCommonSubsequence( $a, $b, 0, @_ );
    my @retval;
    my $i;
    for ( $i = 0 ; $i <= $#$matchVector ; $i++ )
    {
        if ( defined( $matchVector->[$i] ) )
        {
            push ( @retval, $a->[$i] );
        }
    }
    return wantarray ? @retval : \@retval;
}

sub LCS_length
{
    my $a = shift;                          # array ref
    my $b = shift;                          # array ref or hash ref
    return _longestCommonSubsequence( $a, $b, 1, @_ );
}

sub LCSidx
{
    my $a= shift @_;
    my $b= shift @_;
    my $match= _longestCommonSubsequence( $a, $b, 0, @_ );
    my @am= grep defined $match->[$_], 0..$#$match;
    my @bm= @{$match}[@am];
    return \@am, \@bm;
}

sub compact_diff
{
    my $a= shift @_;
    my $b= shift @_;
    my( $am, $bm )= LCSidx( $a, $b, @_ );
    my @cdiff;
    my( $ai, $bi )= ( 0, 0 );
    push @cdiff, $ai, $bi;
    while( 1 ) {
        while(  @$am  &&  $ai == $am->[0]  &&  $bi == $bm->[0]  ) {
            shift @$am;
            shift @$bm;
            ++$ai, ++$bi;
        }
        push @cdiff, $ai, $bi;
        last   if  ! @$am;
        $ai = $am->[0];
        $bi = $bm->[0];
        push @cdiff, $ai, $bi;
    }
    push @cdiff, 0+@$a, 0+@$b
        if  $ai < @$a || $bi < @$b;
    return wantarray ? @cdiff : \@cdiff;
}

sub diff
{
    my $a      = shift;    # array ref
    my $b      = shift;    # array ref
    my $retval = [];
    my $hunk   = [];
    my $discard = sub {
        push @$hunk, [ '-', $_[0], $a->[ $_[0] ] ];
    };
    my $add = sub {
        push @$hunk, [ '+', $_[1], $b->[ $_[1] ] ];
    };
    my $match = sub {
        push @$retval, $hunk
            if 0 < @$hunk;
        $hunk = []
    };
    traverse_sequences( $a, $b,
        { MATCH => $match, DISCARD_A => $discard, DISCARD_B => $add }, @_ );
    &$match();
    return wantarray ? @$retval : $retval;
}

sub sdiff
{
    my $a      = shift;    # array ref
    my $b      = shift;    # array ref
    my $retval = [];
    my $discard = sub { push ( @$retval, [ '-', $a->[ $_[0] ], "" ] ) };
    my $add = sub { push ( @$retval, [ '+', "", $b->[ $_[1] ] ] ) };
    my $change = sub {
        push ( @$retval, [ 'c', $a->[ $_[0] ], $b->[ $_[1] ] ] );
    };
    my $match = sub {
        push ( @$retval, [ 'u', $a->[ $_[0] ], $b->[ $_[1] ] ] );
    };
    traverse_balanced(
        $a,
        $b,
        {
            MATCH     => $match,
            DISCARD_A => $discard,
            DISCARD_B => $add,
            CHANGE    => $change,
        },
        @_
    );
    return wantarray ? @$retval : $retval;
}

########################################
my $Root= __PACKAGE__;
package Algorithm::Diff::_impl;
use strict;

sub _Idx()  { 0 } # $me->[_Idx]: Ref to array of hunk indices
            # 1   # $me->[1]: Ref to first sequence
            # 2   # $me->[2]: Ref to second sequence
sub _End()  { 3 } # $me->[_End]: Diff between forward and reverse pos
sub _Same() { 4 } # $me->[_Same]: 1 if pos 1 contains unchanged items
sub _Base() { 5 } # $me->[_Base]: Added to range's min and max
sub _Pos()  { 6 } # $me->[_Pos]: Which hunk is currently selected
sub _Off()  { 7 } # $me->[_Off]: Offset into _Idx for current position
sub _Min() { -2 } # Added to _Off to get min instead of max+1

sub Die
{
    require Carp;
    Carp::confess( @_ );
}

sub _ChkPos
{
    my( $me )= @_;
    return   if  $me->[_Pos];
    my $meth= ( caller(1) )[3];
    Die( "Called $meth on 'reset' object" );
}

sub _ChkSeq
{
    my( $me, $seq )= @_;
    return $seq + $me->[_Off]
        if  1 == $seq  ||  2 == $seq;
    my $meth= ( caller(1) )[3];
    Die( "$meth: Invalid sequence number ($seq); must be 1 or 2" );
}

sub getObjPkg
{
    my( $us )= @_;
    return ref $us   if  ref $us;
    return $us . "::_obj";
}

sub new
{
    my( $us, $seq1, $seq2, $opts ) = @_;
    my @args;
    for( $opts->{keyGen} ) {
        push @args, $_   if  $_;
    }
    for( $opts->{keyGenArgs} ) {
        push @args, @$_   if  $_;
    }
    my $cdif= Algorithm::Diff::compact_diff( $seq1, $seq2, @args );
    my $same= 1;
    if(  0 == $cdif->[2]  &&  0 == $cdif->[3]  ) {
        $same= 0;
        splice @$cdif, 0, 2;
    }
    my @obj= ( $cdif, $seq1, $seq2 );
    $obj[_End] = (1+@$cdif)/2;
    $obj[_Same] = $same;
    $obj[_Base] = 0;
    my $me = bless \@obj, $us->getObjPkg();
    $me->Reset( 0 );
    return $me;
}

sub Reset
{
    my( $me, $pos )= @_;
    $pos= int( $pos || 0 );
    $pos += $me->[_End]
        if  $pos < 0;
    $pos= 0
        if  $pos < 0  ||  $me->[_End] <= $pos;
    $me->[_Pos]= $pos || !1;
    $me->[_Off]= 2*$pos - 1;
    return $me;
}

sub Base
{
    my( $me, $base )= @_;
    my $oldBase= $me->[_Base];
    $me->[_Base]= 0+$base   if  defined $base;
    return $oldBase;
}

sub Copy
{
    my( $me, $pos, $base )= @_;
    my @obj= @$me;
    my $you= bless \@obj, ref($me);
    $you->Reset( $pos )   if  defined $pos;
    $you->Base( $base );
    return $you;
}

sub Next {
    my( $me, $steps )= @_;
    $steps= 1   if  ! defined $steps;
    if( $steps ) {
        my $pos= $me->[_Pos];
        my $new= $pos + $steps;
        $new= 0   if  $pos  &&  $new < 0;
        $me->Reset( $new )
    }
    return $me->[_Pos];
}

sub Prev {
    my( $me, $steps )= @_;
    $steps= 1   if  ! defined $steps;
    my $pos= $me->Next(-$steps);
    $pos -= $me->[_End]   if  $pos;
    return $pos;
}

sub Diff {
    my( $me )= @_;
    $me->_ChkPos();
    return 0   if  $me->[_Same] == ( 1 & $me->[_Pos] );
    my $ret= 0;
    my $off= $me->[_Off];
    for my $seq ( 1, 2 ) {
        $ret |= $seq
            if  $me->[_Idx][ $off + $seq + _Min ]
            <   $me->[_Idx][ $off + $seq ];
    }
    return $ret;
}

sub Min {
    my( $me, $seq, $base )= @_;
    $me->_ChkPos();
    my $off= $me->_ChkSeq($seq);
    $base= $me->[_Base] if !defined $base;
    return $base + $me->[_Idx][ $off + _Min ];
}

sub Max {
    my( $me, $seq, $base )= @_;
    $me->_ChkPos();
    my $off= $me->_ChkSeq($seq);
    $base= $me->[_Base] if !defined $base;
    return $base + $me->[_Idx][ $off ] -1;
}

sub Range {
    my( $me, $seq, $base )= @_;
    $me->_ChkPos();
    my $off = $me->_ChkSeq($seq);
    if( !wantarray ) {
        return  $me->[_Idx][ $off ]
            -   $me->[_Idx][ $off + _Min ];
    }
    $base= $me->[_Base] if !defined $base;
    return  ( $base + $me->[_Idx][ $off + _Min ] )
        ..  ( $base + $me->[_Idx][ $off ] - 1 );
}

sub Items {
    my( $me, $seq )= @_;
    $me->_ChkPos();
    my $off = $me->_ChkSeq($seq);
    if( !wantarray ) {
        return  $me->[_Idx][ $off ]
            -   $me->[_Idx][ $off + _Min ];
    }
    return
        @{$me->[$seq]}[
                $me->[_Idx][ $off + _Min ]
            ..  ( $me->[_Idx][ $off ] - 1 )
        ];
}

sub Same {
    my( $me )= @_;
    $me->_ChkPos();
    return wantarray ? () : 0
        if  $me->[_Same] != ( 1 & $me->[_Pos] );
    return $me->Items(1);
}

my %getName;
BEGIN {
    %getName= (
        same => \&Same,
        diff => \&Diff,
        base => \&Base,
        min  => \&Min,
        max  => \&Max,
        range=> \&Range,
        items=> \&Items, # same thing
    );
}

sub Get
{
    my $me= shift @_;
    $me->_ChkPos();
    my @value;
    for my $arg (  @_  ) {
        for my $word (  split ' ', $arg  ) {
            my $meth;
            if(     $word !~ /^(-?\d+)?([a-zA-Z]+)([12])?$/
                ||  not  $meth= $getName{ lc $2 }
            ) {
                Die( $Root, ", Get: Invalid request ($word)" );
            }
            my( $base, $name, $seq )= ( $1, $2, $3 );
            push @value, scalar(
                4 == length($name)
                    ? $meth->( $me )
                    : $meth->( $me, $seq, $base )
            );
        }
    }
    if(  wantarray  ) {
        return @value;
    } elsif(  1 == @value  ) {
        return $value[0];
    }
    Die( 0+@value, " values requested from ",
        $Root, "'s Get in scalar context" );
}


my $Obj= getObjPkg($Root);
no strict 'refs';

for my $meth (  qw( new getObjPkg )  ) {
    *{$Root."::".$meth} = \&{$meth};
    *{$Obj ."::".$meth} = \&{$meth};
}
for my $meth (  qw(
    Next Prev Reset Copy Base Diff
    Same Items Range Min Max Get
    _ChkPos _ChkSeq
)  ) {
    *{$Obj."::".$meth} = \&{$meth};
}

1;
__END__

#line 1713
