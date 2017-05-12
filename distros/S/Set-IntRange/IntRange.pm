
###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Set::IntRange;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = '5.2';

use Carp;

use Bit::Vector 7.1;

use overload
      '""' => '_string',
     'neg' => '_complement',
       '~' => '_complement',
    'bool' => '_boolean',
       '!' => '_not_boolean',
     'abs' => '_norm',
       '+' => '_union',
       '|' => '_union',                  # alternative for '+'
       '-' => '_difference',
       '*' => '_intersection',
       '&' => '_intersection',           # alternative for '*'
       '^' => '_exclusive_or',
      '+=' => '_assign_union',
      '|=' => '_assign_union',           # alternative for '+='
      '-=' => '_assign_difference',
      '*=' => '_assign_intersection',
      '&=' => '_assign_intersection',    # alternative for '*='
      '^=' => '_assign_exclusive_or',
      '==' => '_equal',
      '!=' => '_not_equal',
       '<' => '_true_sub_set',
      '<=' => '_sub_set',
       '>' => '_true_super_set',
      '>=' => '_super_set',
     'cmp' => '_compare',                # also enables lt, le, gt, ge, eq, ne
       '=' => '_clone',
'fallback' =>   undef;

sub new
{
    croak "Usage: \$set = Set::IntRange->new(\$lower,\$upper);"
      if (@_ != 3);

    my $proto = shift;
    my $class = ref($proto) || $proto || 'Set::IntRange';
    my $lower = shift;
    my $upper = shift;
    my $object;
    my $set;

    if ($lower <= $upper)
    {
        $set = Bit::Vector->new($upper-$lower+1);
        if ((defined $set) && ref($set) && (${$set} != 0))
        {
            $object = [ $set, $lower, $upper ];
            bless($object, $class);
            return($object);
        }
        else
        {
            croak
  "Set::IntRange::new(): unable to create new 'Set::IntRange' object";
        }
    }
    else
    {
        croak
  "Set::IntRange::new(): lower > upper boundary";
    }
}

sub Resize
{
    croak "Usage: \$set->Resize(\$lower,\$upper);"
      if (@_ != 3);

    my($object,$new_lower,$new_upper) = @_;
    my($old_lower,$old_upper) = ($object->[1],$object->[2]);
    my($diff);

    if ($new_lower <= $new_upper)
    {
        $diff = $new_lower - $old_lower;
        if ($diff == 0)
        {
            $object->[0]->Resize($new_upper-$new_lower+1);
        }
        else
        {
            if ($diff > 0)
            {
                $object->[0]->Delete(0,$diff);
                $object->[0]->Resize($new_upper-$new_lower+1);
            }
            else
            {
                $object->[0]->Resize($new_upper-$new_lower+1);
                $object->[0]->Insert(0,-$diff);
            }
        }
        ($object->[1],$object->[2]) = ($new_lower,$new_upper);
    }
    else
    {
        croak "Set::IntRange::Resize(): lower > upper boundary";
    }
}

sub Size
{
    croak "Usage: (\$lower,\$upper) = \$set->Size();"
      if (@_ != 1);

    my($object) = @_;

    return( $object->[1], $object->[2] );
}

sub Bit_Vector
{
    croak "Usage: \$set2->Bit_Vector->Bit_Vector_method(\$set1->Bit_Vector);"
      if (@_ != 1);

    my($object) = @_;

    return( $object->[0] );
}

sub Empty
{
    croak "Usage: \$set->Empty();"
      if (@_ != 1);

    my($object) = @_;

    $object->[0]->Empty();
}

sub Fill
{
    croak "Usage: \$set->Fill();"
      if (@_ != 1);

    my($object) = @_;

    $object->[0]->Fill();
}

sub Flip
{
    croak "Usage: \$set->Flip();"
      if (@_ != 1);

    my($object) = @_;

    $object->[0]->Flip();
}

sub Interval_Empty
{
    croak "Usage: \$set->Interval_Empty(\$min,\$max);"
      if (@_ != 3);

    my($object,$min,$max) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    croak "Set::IntRange::Interval_Empty(): minimum index out of range"
      if (($min < $lower) || ($min > $upper));

    croak "Set::IntRange::Interval_Empty(): maximum index out of range"
      if (($max < $lower) || ($max > $upper));

    croak "Set::IntRange::Interval_Empty(): minimum > maximum index"
      if ($min > $max);

    $object->[0]->Interval_Empty($min-$lower,$max-$lower);
}

sub Interval_Fill
{
    croak "Usage: \$set->Interval_Fill(\$min,\$max);"
      if (@_ != 3);

    my($object,$min,$max) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    croak "Set::IntRange::Interval_Fill(): minimum index out of range"
      if (($min < $lower) || ($min > $upper));

    croak "Set::IntRange::Interval_Fill(): maximum index out of range"
      if (($max < $lower) || ($max > $upper));

    croak "Set::IntRange::Interval_Fill(): minimum > maximum index"
      if ($min > $max);

    $object->[0]->Interval_Fill($min-$lower,$max-$lower);
}

sub Interval_Flip
{
    croak "Usage: \$set->Interval_Flip(\$min,\$max);"
      if (@_ != 3);

    my($object,$min,$max) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    croak "Set::IntRange::Interval_Flip(): minimum index out of range"
      if (($min < $lower) || ($min > $upper));

    croak "Set::IntRange::Interval_Flip(): maximum index out of range"
      if (($max < $lower) || ($max > $upper));

    croak "Set::IntRange::Interval_Flip(): minimum > maximum index"
      if ($min > $max);

    $object->[0]->Interval_Flip($min-$lower,$max-$lower);
}

sub Interval_Scan_inc
{
    croak "Usage: (\$min,\$max) = \$set->Interval_Scan_inc(\$start);"
      if (@_ != 2);

    my($object,$start) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);
    my($min,$max);

    croak "Set::IntRange::Interval_Scan_inc(): start index out of range"
      if (($start < $lower) || ($start > $upper));

    if (($min,$max) = $object->[0]->Interval_Scan_inc($start-$lower))
    {
        $min += $lower;
        $max += $lower;
        return($min,$max);
    }
    else
    {
        return();
    }
}

sub Interval_Scan_dec
{
    croak "Usage: (\$min,\$max) = \$set->Interval_Scan_dec(\$start);"
      if (@_ != 2);

    my($object,$start) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);
    my($min,$max);

    croak "Set::IntRange::Interval_Scan_dec(): start index out of range"
      if (($start < $lower) || ($start > $upper));

    if (($min,$max) = $object->[0]->Interval_Scan_dec($start-$lower))
    {
        $min += $lower;
        $max += $lower;
        return($min,$max);
    }
    else
    {
        return();
    }
}

sub Bit_Off
{
    croak "Usage: \$set->Bit_Off(\$index);"
      if (@_ != 2);

    my($object,$index) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    if (($index >= $lower) && ($index <= $upper))
    {
        $object->[0]->Bit_Off($index-$lower);
    }
    else
    {
        croak "Set::IntRange::Bit_Off(): index out of range";
    }
}

sub Bit_On
{
    croak "Usage: \$set->Bit_On(\$index);"
      if (@_ != 2);

    my($object,$index) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    if (($index >= $lower) && ($index <= $upper))
    {
        $object->[0]->Bit_On($index-$lower);
    }
    else
    {
        croak "Set::IntRange::Bit_On(): index out of range";
    }
}

sub bit_flip
{
    croak "Usage: if (\$set->bit_flip(\$index))"
      if (@_ != 2);

    my($object,$index) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    if (($index >= $lower) && ($index <= $upper))
    {
        return( $object->[0]->bit_flip($index-$lower) );
    }
    else
    {
        croak "Set::IntRange::bit_flip(): index out of range";
    }
}

sub bit_test
{
    croak "Usage: if (\$set->bit_test(\$index))"
      if (@_ != 2);

    my($object,$index) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);

    if (($index >= $lower) && ($index <= $upper))
    {
        return( $object->[0]->bit_test($index-$lower) );
    }
    else
    {
        croak "Set::IntRange::bit_test(): index out of range";
    }
}

sub contains
{
    return( bit_test(@_) );
}

sub Norm
{
    croak "Usage: \$norm = \$set->Norm();"
      if (@_ != 1);

    my($object) = @_;

    return( $object->[0]->Norm() );
}

sub Min
{
    croak "Usage: \$min = \$set->Min();"
      if (@_ != 1);

    my($object) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);
    my($result);

    $result = $object->[0]->Min();
    return( (($result >= 0) && ($result <= ($upper-$lower))) ?
            ($result+$lower) : $result );
}

sub Max
{
    croak "Usage: \$max = \$set->Max();"
      if (@_ != 1);

    my($object) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);
    my($result);

    $result = $object->[0]->Max();
    return( (($result >= 0) && ($result <= ($upper-$lower))) ?
            ($result+$lower) : $result );
}

sub Union
{
    croak "Usage: \$set1->Union(\$set2,\$set3);"
      if (@_ != 3);

    my($set1,$set2,$set3) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);
    my($lower3,$upper3) = ($set3->[1],$set3->[2]);

    if (($lower1 == $lower2) && ($lower1 == $lower3) &&
        ($upper1 == $upper2) && ($upper1 == $upper3))
    {
        $set1->[0]->Union($set2->[0],$set3->[0]);
    }
    else
    {
        croak "Set::IntRange::Union(): set size mismatch";
    }
}

sub Intersection
{
    croak "Usage: \$set1->Intersection(\$set2,\$set3);"
      if (@_ != 3);

    my($set1,$set2,$set3) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);
    my($lower3,$upper3) = ($set3->[1],$set3->[2]);

    if (($lower1 == $lower2) && ($lower1 == $lower3) &&
        ($upper1 == $upper2) && ($upper1 == $upper3))
    {
        $set1->[0]->Intersection($set2->[0],$set3->[0]);
    }
    else
    {
        croak "Set::IntRange::Intersection(): set size mismatch";
    }
}

sub Difference
{
    croak "Usage: \$set1->Difference(\$set2,\$set3);"
      if (@_ != 3);

    my($set1,$set2,$set3) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);
    my($lower3,$upper3) = ($set3->[1],$set3->[2]);

    if (($lower1 == $lower2) && ($lower1 == $lower3) &&
        ($upper1 == $upper2) && ($upper1 == $upper3))
    {
        $set1->[0]->Difference($set2->[0],$set3->[0]);
    }
    else
    {
        croak "Set::IntRange::Difference(): set size mismatch";
    }
}

sub ExclusiveOr
{
    croak "Usage: \$set1->ExclusiveOr(\$set2,\$set3);"
      if (@_ != 3);

    my($set1,$set2,$set3) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);
    my($lower3,$upper3) = ($set3->[1],$set3->[2]);

    if (($lower1 == $lower2) && ($lower1 == $lower3) &&
        ($upper1 == $upper2) && ($upper1 == $upper3))
    {
        $set1->[0]->ExclusiveOr($set2->[0],$set3->[0]);
    }
    else
    {
        croak "Set::IntRange::ExclusiveOr(): set size mismatch";
    }
}

sub Complement
{
    croak "Usage: \$set1->Complement(\$set2);"
      if (@_ != 2);

    my($set1,$set2) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);

    if (($lower1 == $lower2) && ($upper1 == $upper2))
    {
        $set1->[0]->Complement($set2->[0]);
    }
    else
    {
        croak "Set::IntRange::Complement(): set size mismatch";
    }
}

sub is_empty
{
    croak "Usage: if (\$set->is_empty())"
      if (@_ != 1);

    my($object) = @_;

    return( $object->[0]->is_empty() );
}

sub is_full
{
    croak "Usage: if (\$set->is_full())"
      if (@_ != 1);

    my($object) = @_;

    return( $object->[0]->is_full() );
}

sub equal
{
    croak "Usage: if (\$set1->equal(\$set2))"
      if (@_ != 2);

    my($set1,$set2) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);

    if (($lower1 == $lower2) && ($upper1 == $upper2))
    {
        return( $set1->[0]->equal($set2->[0]) );
    }
    else
    {
        croak "Set::IntRange::equal(): set size mismatch";
    }
}

sub subset
{
    croak "Usage: if (\$set1->subset(\$set2))"
      if (@_ != 2);

    my($set1,$set2) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);

    if (($lower1 == $lower2) && ($upper1 == $upper2))
    {
        return( $set1->[0]->subset($set2->[0]) );
    }
    else
    {
        croak "Set::IntRange::subset(): set size mismatch";
    }
}

sub Lexicompare
{
    croak "Usage: \$cmp = \$set1->Lexicompare(\$set2);"
      if (@_ != 2);

    my($set1,$set2) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);

    if (($lower1 == $lower2) && ($upper1 == $upper2))
    {
        return( $set1->[0]->Lexicompare($set2->[0]) );
    }
    else
    {
        croak "Set::IntRange::Lexicompare(): set size mismatch";
    }
}

sub Compare
{
    croak "Usage: \$cmp = \$set1->Compare(\$set2);"
      if (@_ != 2);

    my($set1,$set2) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);

    if (($lower1 == $lower2) && ($upper1 == $upper2))
    {
        return( $set1->[0]->Compare($set2->[0]) );
    }
    else
    {
        croak "Set::IntRange::Compare(): set size mismatch";
    }
}

sub Copy
{
    croak "Usage: \$set1->Copy(\$set2);"
      if (@_ != 2);

    my($set1,$set2) = @_;
    my($lower1,$upper1) = ($set1->[1],$set1->[2]);
    my($lower2,$upper2) = ($set2->[1],$set2->[2]);

    if (($lower1 == $lower2) && ($upper1 == $upper2))
    {
        $set1->[0]->Copy($set2->[0]);
    }
    else
    {
        croak "Set::IntRange::Copy(): set size mismatch";
    }
}

sub Shadow
{
    croak "Usage: \$other_set = \$some_set->Shadow();"
      if (@_ != 1);

    my($object) = @_;
    my($result);

    $result = $object->new($object->[1],$object->[2]);
    return($result);
}

sub Clone
{
    croak "Usage: \$twin_set = \$some_set->Clone();"
      if (@_ != 1);

    my($object) = @_;
    my($result);

    $result = $object->new($object->[1],$object->[2]);
    $result->Copy($object);
    return($result);
}

sub to_Enum
{
    croak "Usage: \$string = \$set->to_Enum();"
      if (@_ != 1);

    my($object) = @_;
    my($lower) = $object->[1];
    my($start,$string);
    my($min,$max);

    $start = 0;
    $string = '';
    while (($start < $object->[0]->Size()) &&
        (($min,$max) = $object->[0]->Interval_Scan_inc($start)))
    {
        $start = $max + 2;
        $min += $lower;
        $max += $lower;
        if    ($min == $max)   { $string .= "${min},"; }
        elsif ($min == $max-1) { $string .= "${min},${max},"; }
        else                   { $string .= "${min}..${max},"; }
    }
    $string =~ s/,$//;
    return($string);
}

sub from_Enum
{
    croak "Usage: \$set->from_Enum(\$string);"
      if (@_ != 2);

    my($object,$string) = @_;
    my($lower,$upper) = ($object->[1],$object->[2]);
    my(@intervals,$interval);
    my($min,$max);

    croak "Set::IntRange::from_Enum(): syntax error in input string"
      unless ($string =~ /^ (?: [+-]? \d+ (?: \.\. [+-]? \d+ )? )
                      (?: , (?: [+-]? \d+ (?: \.\. [+-]? \d+ )? ) )* $/x);

    $object->[0]->Empty();

    @intervals = split(/,/, $string);

    foreach $interval (@intervals)
    {
        if ($interval =~ /\.\./)
        {
            ($min,$max) = split(/\.\./, $interval);

            croak "Set::IntRange::from_Enum(): minimum index out of range"
              if (($min < $lower) || ($min > $upper));

            croak "Set::IntRange::from_Enum(): maximum index out of range"
              if (($max < $lower) || ($max > $upper));

            croak "Set::IntRange::from_Enum(): minimum > maximum index"
              if ($min > $max);

            $min -= $lower;
            $max -= $lower;

            $object->[0]->Interval_Fill($min,$max);
        }
        else
        {
            croak "Set::IntRange::from_Enum(): index out of range"
              if (($interval < $lower) || ($interval > $upper));

            $interval -= $lower;

            $object->[0]->Bit_On($interval);
        }
    }
}

sub to_Hex
{
    croak "Usage: \$string = \$set->to_Hex();"
      if (@_ != 1);

    my($object) = @_;

    return( $object->[0]->to_Hex() );
}

sub from_Hex
{
    croak "Usage: \$set->from_Hex(\$string);"
      if (@_ != 2);

    my($object,$string) = @_;

    eval { $object->[0]->from_Hex($string); };
    if ($@)
    {
        croak "Set::IntRange::from_Hex(): syntax error in input string";
    }
}

                ########################################
                #                                      #
                # define overloaded operators section: #
                #                                      #
                ########################################

sub _string
{
    my($object,$argument,$flag) = @_;
#   my($name) = '""'; #&_trace($name,$object,$argument,$flag);
    my($vector) = $object->[0];

    return( "$vector" );
}

sub _complement
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'~'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    $result = $object->new($object->[1],$object->[2]);
    $result->Complement($object);
    return($result);
}

sub _boolean
{
    my($object,$argument,$flag) = @_;
#   my($name) = "bool"; #&_trace($name,$object,$argument,$flag);

    return( ! $object->is_empty() );
}

sub _not_boolean
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'!'"; #&_trace($name,$object,$argument,$flag);

    return( $object->is_empty() );
}

sub _norm
{
    my($object,$argument,$flag) = @_;
#   my($name) = "abs"; #&_trace($name,$object,$argument,$flag);

    return( $object->Norm() );
}

sub _union
{
    my($object,$argument,$flag) = @_;
    my($name) = "'+'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            $result->Union($object,$argument);
            return($result);
        }
        else
        {
            $object->Union($object,$argument);
            return($object);
        }
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            $result->Copy($object);
            $result->Bit_On($argument);
            return($result);
        }
        else
        {
            $object->Bit_On($argument);
            return($object);
        }
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
}

sub _difference
{
    my($object,$argument,$flag) = @_;
    my($name) = "'-'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            if ($flag) { $result->Difference($argument,$object); }
            else       { $result->Difference($object,$argument); }
            return($result);
        }
        else
        {
            $object->Difference($object,$argument);
            return($object);
        }
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            if ($flag)
            {
                unless ($object->bit_test($argument))
                { $result->Bit_On($argument); }
            }
            else
            {
                $result->Copy($object);
                $result->Bit_Off($argument);
            }
            return($result);
        }
        else
        {
            $object->Bit_Off($argument);
            return($object);
        }
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
}

sub _intersection
{
    my($object,$argument,$flag) = @_;
    my($name) = "'*'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            $result->Intersection($object,$argument);
            return($result);
        }
        else
        {
            $object->Intersection($object,$argument);
            return($object);
        }
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            if ($object->bit_test($argument))
            { $result->Bit_On($argument); }
            return($result);
        }
        else
        {
            $flag = $object->bit_test($argument);
            $object->Empty();
            if ($flag) { $object->Bit_On($argument); }
            return($object);
        }
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
}

sub _exclusive_or
{
    my($object,$argument,$flag) = @_;
    my($name) = "'^'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            $result->ExclusiveOr($object,$argument);
            return($result);
        }
        else
        {
            $object->ExclusiveOr($object,$argument);
            return($object);
        }
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        if (defined $flag)
        {
            $result = $object->new($object->[1],$object->[2]);
            $result->Copy($object);
            $result->bit_flip($argument);
            return($result);
        }
        else
        {
            $object->bit_flip($argument);
            return($object);
        }
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
}

sub _assign_union
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'+='"; #&_trace($name,$object,$argument,$flag);

    return( &_union($object,$argument,undef) );
}

sub _assign_difference
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'-='"; #&_trace($name,$object,$argument,$flag);

    return( &_difference($object,$argument,undef) );
}

sub _assign_intersection
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'*='"; #&_trace($name,$object,$argument,$flag);

    return( &_intersection($object,$argument,undef) );
}

sub _assign_exclusive_or
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'^='"; #&_trace($name,$object,$argument,$flag);

    return( &_exclusive_or($object,$argument,undef) );
}

sub _equal
{
    my($object,$argument,$flag) = @_;
    my($name) = "'=='"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    return( $object->equal($result) );
}

sub _not_equal
{
    my($object,$argument,$flag) = @_;
    my($name) = "'!='"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    return( !($object->equal($result)) );
}

sub _true_sub_set
{
    my($object,$argument,$flag) = @_;
    my($name) = "'<'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    if ((defined $flag) && $flag)
    {
        return( !($result->equal($object)) &&
                 ($result->subset($object)) );
    }
    else
    {
        return( !($object->equal($result)) &&
                 ($object->subset($result)) );
    }
}

sub _sub_set
{
    my($object,$argument,$flag) = @_;
    my($name) = "'<='"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    if ((defined $flag) && $flag)
    {
        return( $result->subset($object) );
    }
    else
    {
        return( $object->subset($result) );
    }
}

sub _true_super_set
{
    my($object,$argument,$flag) = @_;
    my($name) = "'>'"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    if ((defined $flag) && $flag)
    {
        return( !($object->equal($result)) &&
                 ($object->subset($result)) );
    }
    else
    {
        return( !($result->equal($object)) &&
                 ($result->subset($object)) );
    }
}

sub _super_set
{
    my($object,$argument,$flag) = @_;
    my($name) = "'>='"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    if ((defined $flag) && $flag)
    {
        return( $object->subset($result) );
    }
    else
    {
        return( $result->subset($object) );
    }
}

sub _compare
{
    my($object,$argument,$flag) = @_;
    my($name) = "cmp"; #&_trace($name,$object,$argument,$flag);
    my($result);

    if ((defined $argument) && ref($argument) &&
        (ref($argument) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $result = $argument;
    }
    elsif ((defined $argument) && !(ref($argument)))
    {
        $result = $object->new($object->[1],$object->[2]);
        $result->Bit_On($argument);
    }
    else
    {
        croak "Set::IntRange $name: wrong argument type";
    }
    if ((defined $flag) && $flag)
    {
        return( $result->Compare($object) );
    }
    else
    {
        return( $object->Compare($result) );
    }
}

sub _clone
{
    my($object,$argument,$flag) = @_;
#   my($name) = "'='"; #&_trace($name,$object,$argument,$flag);
    my($result);

    $result = $object->new($object->[1],$object->[2]);
    $result->Copy($object);
    return($result);
}

sub _trace
{
    my($text,$object,$argument,$flag) = @_;

    unless (defined $object)   { $object   = 'undef'; };
    unless (defined $argument) { $argument = 'undef'; };
    unless (defined $flag)     { $flag     = 'undef'; };
    if (ref($object))   { $object   = ref($object);   }
    if (ref($argument)) { $argument = ref($argument); }
    print "$text: \$obj='$object' \$arg='$argument' \$flag='$flag'\n";
}

1;

__END__

=head1 NAME

Set::IntRange - Sets of Integers

=head2 PURPOSE

Easy manipulation of sets of integers (arbitrary intervals)

=head1 SYNOPSIS

=head2 METHODS

  Version
      $version = $Set::IntRange::VERSION;

  new
      $set = Set::IntRange->new($lower,$upper);
      $set = $any_set->new($lower,$upper);

  Resize
      $set->Resize($lower,$upper);

  Size
      ($lower,$upper) = $set->Size();

  Empty
      $set->Empty();

  Fill
      $set->Fill();

  Flip
      $set->Flip();

  Interval_Empty
      $set->Interval_Empty($lower,$upper);
      $set->Empty_Interval($lower,$upper); # (deprecated)

  Interval_Fill
      $set->Interval_Fill($lower,$upper);
      $set->Fill_Interval($lower,$upper);  # (deprecated)

  Interval_Flip
      $set->Interval_Flip($lower,$upper);
      $set->Flip_Interval($lower,$upper);  # (deprecated)

  Interval_Scan_inc
      while (($min,$max) = $set->Interval_Scan_inc($start))

  Interval_Scan_dec
      while (($min,$max) = $set->Interval_Scan_dec($start))

  Bit_Off
      $set->Bit_Off($index);
      $set->Delete($index);                # (deprecated)

  Bit_On
      $set->Bit_On($index);
      $set->Insert($index);                # (deprecated)

  bit_flip
      $bit = $set->bit_flip($index);
      if ($set->bit_flip($index))
      $bit = $set->flip($index);           # (deprecated)
      if ($set->flip($index))              # (deprecated)

  bit_test
      $bit = $set->bit_test($index);
      if ($set->bit_test($index))
      $bit = $set->contains($index);
      if ($set->contains($index))
      $bit = $set->in($index);             # (deprecated)
      if ($set->in($index))                # (deprecated)

  Norm
      $norm = $set->Norm();

  Min
      $min = $set->Min();

  Max
      $max = $set->Max();

  Union
      $set1->Union($set2,$set3);           # in-place is possible!

  Intersection
      $set1->Intersection($set2,$set3);    # in-place is possible!

  Difference
      $set1->Difference($set2,$set3);      # in-place is possible!

  ExclusiveOr
      $set1->ExclusiveOr($set2,$set3);     # in-place is possible!

  Complement
      $set1->Complement($set2);            # in-place is possible!

  is_empty
      if ($set->is_empty())

  is_full
      if ($set->is_full())

  equal
      if ($set1->equal($set2))

  subset
      if ($set1->subset($set2))
      if ($set1->inclusion($set2))         # (deprecated)

  Lexicompare
      $cmp = $set1->Lexicompare($set2);    # unsigned

  Compare
      $cmp = $set1->Compare($set2);        # signed

  Copy
      $set1->Copy($set2);

  Shadow
      $other_set = $some_set->Shadow();

  Clone
      $twin_set = $some_set->Clone();

  to_Enum
      $string = $set->to_Enum();           # e.g., "-8..-5,-1..2,4,6..9"

  from_Enum
      eval { $set->from_Enum($string); };

  to_Hex
      $string = $set->to_Hex();            # e.g., "0007AF1E"

  from_Hex
      eval { $set->from_Hex($string); };

  BitVector
      $set->BitVector->any_Bit_Vector_method();

=head2 OVERLOADED OPERATORS

      # "$index" is a number or a Perl scalar variable containing a
      # number which represents the set containing only that element:

  Emptyness
      if ($set) # if not empty
      if (! $set) # if empty
      unless ($set) # if empty

  Equality
      if ($set1 == $set2)
      if ($set1 != $set2)
      if ($set == $index)
      if ($set != $index)

  Lexical Comparison
      $cmp = $set1 cmp $set2;
      if ($set1 lt $set2)
      if ($set1 le $set2)
      if ($set1 gt $set2)
      if ($set1 ge $set2)
      if ($set1 eq $set2)
      if ($set1 ne $set2)
      $cmp = $set cmp $index;
      if ($set lt $index)
      if ($set le $index)
      if ($set gt $index)
      if ($set ge $index)
      if ($set eq $index)
      if ($set ne $index)

  String Conversion
      $string = "$set";
      print "\$set = '$set'\n";

  Union
      $set1 = $set2 + $set3;
      $set1 += $set2;
      $set1 = $set2 | $set3;
      $set1 |= $set2;
      $set1 = $set2 + $index;
      $set += $index;
      $set1 = $set2 | $index;
      $set |= $index;

  Intersection
      $set1 = $set2 * $set3;
      $set1 *= $set2;
      $set1 = $set2 & $set3;
      $set1 &= $set2;
      $set1 = $set2 * $index;
      $set *= $index;
      $set1 = $set2 & $index;
      $set &= $index;

  Difference
      $set1 = $set2 - $set3;
      $set1 -= $set2;
      $set1 = $set2 - $set1;
      $set1 = $set2 - $index;
      $set1 = $index - $set2;
      $set -= $index;

  ExclusiveOr
      $set1 = $set2 ^ $set3;
      $set1 ^= $set2;
      $set1 = $set2 ^ $index;
      $set ^= $index;

  Complement
      $set1 = -$set2;
      $set1 = ~$set2;
      $set = -$set;
      $set = ~$set;

  Subset Relationship
      if ($set1 <= $set2)

  True Subset Relationship
      if ($set1 < $set2)

  Superset Relationship
      if ($set1 >= $set2)

  True Superset Relationship
      if ($set1 > $set2)

  Norm
      $norm = abs($set);

=head1 DESCRIPTION

This class lets you dynamically create sets of arbitrary intervals of
integers and perform all the basic operations for sets on them (for a
list of available methods and operators, see above).

See L<Bit::Vector(3)> for more details!

=head1 SEE ALSO

Bit::Vector(3), Math::MatrixBool(3),
Math::MatrixReal(3), DFA::Kleene(3),
Math::Kleene(3), Graph::Kruskal(3).

=head1 VERSION

This man page documents "Set::IntRange" version 5.2.

=head1 AUTHOR

Steffen Beyer <STBEY@cpan.org>.

=head1 COPYRIGHT

Copyright (c) 1995 - 2009 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

