package Operator::Util;

use 5.006;
use strict;
use warnings;
use parent 'Exporter';
use List::MoreUtils qw( uniq );

our $VERSION   = '0.05';
our @EXPORT_OK = qw(
    reduce  reducewith
    zip     zipwith
    cross   crosswith
    hyper   hyperwith
    applyop reverseop
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

*reducewith = \&reduce;
*hyperwith  = \&hyper;

# sub: operator subroutines
# res: responses in an arrayref for when zero or one argument is provided --
#      the first element is the response for zero args and the second is for
#      one arg, defaulting to the arg itself
# chain: set non-chaining Perl 5 operator to chaining-associative
# right: set operator to right-associative

my %ops = (
    # binary infix
    'infix:**'  => { sub => sub { $_[0] **  $_[1] }, res => [1], right => 1 },
    'infix:=~'  => { sub => sub { $_[0] =~  $_[1] }, res => [1, 1] },
    'infix:!~'  => { sub => sub { $_[0] !~  $_[1] }, res => [1, 1] },
    'infix:*'   => { sub => sub { $_[0] *   $_[1] }, res => [1] },
    'infix:/'   => { sub => sub { $_[0] /   $_[1] }, res => [undef] },
    'infix:%'   => { sub => sub { $_[0] %   $_[1] }, res => [undef] },
    'infix:x'   => { sub => sub { $_[0] x   $_[1] }, res => [undef] },
    'infix:+'   => { sub => sub { $_[0] +   $_[1] }, res => [0] },
    'infix:-'   => { sub => sub { $_[0] -   $_[1] }, res => [0] },
    'infix:.'   => { sub => sub { $_[0] .   $_[1] }, res => [''] },
    'infix:<<'  => { sub => sub { $_[0] <<  $_[1] }, res => [undef] },
    'infix:>>'  => { sub => sub { $_[0] >>  $_[1] }, res => [undef] },
    'infix:<'   => { sub => sub { $_[0] <   $_[1] }, res => [1, 1], chain => 1 },
    'infix:>'   => { sub => sub { $_[0] >   $_[1] }, res => [1, 1], chain => 1 },
    'infix:<='  => { sub => sub { $_[0] <=  $_[1] }, res => [1, 1], chain => 1 },
    'infix:>='  => { sub => sub { $_[0] >=  $_[1] }, res => [1, 1], chain => 1 },
    'infix:lt'  => { sub => sub { $_[0] lt  $_[1] }, res => [1, 1], chain => 1 },
    'infix:gt'  => { sub => sub { $_[0] gt  $_[1] }, res => [1, 1], chain => 1 },
    'infix:le'  => { sub => sub { $_[0] le  $_[1] }, res => [1, 1], chain => 1 },
    'infix:ge'  => { sub => sub { $_[0] ge  $_[1] }, res => [1, 1], chain => 1 },
    'infix:=='  => { sub => sub { $_[0] ==  $_[1] }, res => [1, 1], chain => 1 },
    'infix:!='  => { sub => sub { $_[0] !=  $_[1] }, res => [1, 1], chain => 1 },
    'infix:<=>' => { sub => sub { $_[0] <=> $_[1] }, res => [1, 1], chain => 1 },
    'infix:eq'  => { sub => sub { $_[0] eq  $_[1] }, res => [1, 1], chain => 1 },
    'infix:ne'  => { sub => sub { $_[0] ne  $_[1] }, res => [1, 1], chain => 1 },
    'infix:cmp' => { sub => sub { $_[0] cmp $_[1] }, res => [1, 1], chain => 1 },
    'infix:&'   => { sub => sub { $_[0] &   $_[1] }, res => [-1] },
    'infix:|'   => { sub => sub { $_[0] |   $_[1] }, res => [0] },
    'infix:^'   => { sub => sub { $_[0] ^   $_[1] }, res => [0] },
    'infix:&&'  => { sub => sub { $_[0] &&  $_[1] }, res => [1] },
    'infix:||'  => { sub => sub { $_[0] ||  $_[1] }, res => [0] },
    'infix:..'  => { sub => sub { $_[0] ..  $_[1] }, res => [1] },
    'infix:...' => { sub => sub { $_[0] ... $_[1] }, res => [1] },
    'infix:='   => { sub => sub { $_[0] =   $_[1] }, res => [undef] },
    'infix:**=' => { sub => sub { $_[0] **= $_[1] }, res => [undef] },
    'infix:*='  => { sub => sub { $_[0] *=  $_[1] }, res => [undef] },
    'infix:/='  => { sub => sub { $_[0] /=  $_[1] }, res => [undef] },
    'infix:%='  => { sub => sub { $_[0] %=  $_[1] }, res => [undef] },
    'infix:x='  => { sub => sub { $_[0] x=  $_[1] }, res => [undef] },
    'infix:+='  => { sub => sub { $_[0] +=  $_[1] }, res => [undef] },
    'infix:-='  => { sub => sub { $_[0] -=  $_[1] }, res => [undef] },
    'infix:.='  => { sub => sub { $_[0] .=  $_[1] }, res => [undef] },
    'infix:<<=' => { sub => sub { $_[0] <<= $_[1] }, res => [undef] },
    'infix:>>=' => { sub => sub { $_[0] >>= $_[1] }, res => [undef] },
    'infix:&='  => { sub => sub { $_[0] &=  $_[1] }, res => [undef] },
    'infix:|='  => { sub => sub { $_[0] |=  $_[1] }, res => [undef] },
    'infix:^='  => { sub => sub { $_[0] ^=  $_[1] }, res => [undef] },
    'infix:&&=' => { sub => sub { $_[0] &&= $_[1] }, res => [undef] },
    'infix:||=' => { sub => sub { $_[0] ||= $_[1] }, res => [undef] },
    'infix:,'   => { sub => sub { $_[0] ,   $_[1] }, res => [[]] },
    'infix:=>'  => { sub => sub { $_[0] =>  $_[1] }, res => [[]] },
    'infix:and' => { sub => sub { $_[0] and $_[1] }, res => [1] },
    'infix:or'  => { sub => sub { $_[0] or  $_[1] }, res => [0] },
    'infix:xor' => { sub => sub { $_[0] xor $_[1] }, res => [0] },
    'infix:->'  => { sub => sub { my $m = $_[1];         $_[0]->$m }, res => [undef] },
    'infix:->=' => { sub => sub { my $m = $_[1]; $_[0] = $_[0]->$m }, res => [undef] },

    # unary prefix
    'prefix:++' => { sub => sub { ++$_[0]  } },
    'prefix:--' => { sub => sub { --$_[0]  } },
    'prefix:!'  => { sub => sub {  !$_[0]  } },
    'prefix:~'  => { sub => sub {  ~$_[0]  } },
    'prefix:\\' => { sub => sub {  \$_[0]  } },
    'prefix:+'  => { sub => sub {  +$_[0]  } },
    'prefix:-'  => { sub => sub {  -$_[0]  } },
    'prefix:$'  => { sub => sub { ${$_[0]} } },
    'prefix:@'  => { sub => sub { @{$_[0]} } },
    'prefix:%'  => { sub => sub { %{$_[0]} } },
    'prefix:&'  => { sub => sub { &{$_[0]} } },
    'prefix:*'  => { sub => sub { *{$_[0]} } },

    # unary postfix
    'postfix:++' => { sub => sub { $_[0]++ } },
    'postfix:--' => { sub => sub { $_[0]-- } },

    # circumfix
    'circumfix:()'  => { sub => sub {  ($_[0]) } },
    'circumfix:[]'  => { sub => sub {  [$_[0]] } },
    'circumfix:{}'  => { sub => sub {  {$_[0]} } },
    'circumfix:${}' => { sub => sub { ${$_[0]} } },
    'circumfix:@{}' => { sub => sub { @{$_[0]} } },
    'circumfix:%{}' => { sub => sub { %{$_[0]} } },
    'circumfix:&{}' => { sub => sub { &{$_[0]} } },
    'circumfix:*{}' => { sub => sub { *{$_[0]} } },

    # postcircumfix
    'postcircumfix:[]'   => { sub => sub { $_[0]->[$_[1]] }, res => [undef] },
    'postcircumfix:{}'   => { sub => sub { $_[0]->{$_[1]} }, res => [undef] },
    'postcircumfix:->[]' => { sub => sub { $_[0]->[$_[1]] }, res => [undef] },
    'postcircumfix:->{}' => { sub => sub { $_[0]->{$_[1]} }, res => [undef] },
);

# Perl 5.10 operators
if ($] >= 5.010) {
    $ops{'infix:~~'} = { sub => eval 'sub { $_[0] ~~ $_[1] }', res => [1, 1], chain => 1 };
    $ops{'infix://'} = { sub => eval 'sub { $_[0] // $_[1] }', res => [0] };
}

sub reduce {
    my ($op, $list, %args) = @_;
    my $type;
    ($op, $type) = _get_op_info($op);

    return unless $op;
    return if $type ne 'infix';

    my @list = ref $list eq 'ARRAY' ? @$list :
               defined $list        ? $list  :
                                      ()     ;

    # return default for zero args
    return $ops{$op}{res}[0]
        unless @list;

    # return default for one arg if defined, otherwise return the arg itself
    return exists $ops{$op}{res}[1] ? $ops{$op}{res}[1] : $list[0]
        if @list == 1;

    if ( $ops{$op}{right} ) {
        @list = reverse @list;
    }

    my $result   = shift @list;
    my $bool     = 1;
    my @triangle = $ops{$op}{chain} ? $bool : $result;

    my $apply = sub {
        my ($a, $b) = @_;
        return applyop( $op, $ops{$op}{right} ? ($b, $a) : ($a, $b) );
    };

    while (@list) {
        my $next = shift @list;

        if ( $ops{$op}{chain} ) {
            $bool = $bool && $apply->($result, $next);
            $result = $next;
            push @triangle, $bool if $args{triangle};
        }
        else {
            $result = $apply->($result, $next);
            push @triangle, $result if $args{triangle};
        }
    }

    return @triangle if $args{triangle};
    return $bool     if $ops{$op}{chain};
    return $result;
}

sub zip   { zipwith(   ',', @_ ) }
sub cross { crosswith( ',', @_ ) }

sub zipwith {
    my ($op, $lhs, $rhs) = @_;
    my ($a, $b, @results);

    $lhs = [$lhs] if ref $lhs ne 'ARRAY';
    $rhs = [$rhs] if ref $rhs ne 'ARRAY';

    while (@$lhs && @$rhs) {
        $a = shift @$lhs;
        $b = shift @$rhs;
        push @results, applyop($op, $a, $b);
    }

    return @results;
}

sub crosswith {
    my ($op, $lhs, $rhs) = @_;
    my ($a, $b, @results);

    $lhs = [$lhs] if ref $lhs ne 'ARRAY';
    $rhs = [$rhs] if ref $rhs ne 'ARRAY';

    for my $a (@$lhs) {
        for my $b (@$rhs) {
            push @results, applyop($op, $a, $b);
        }
    }

    return @results;
}

sub hyper {
    my ($op, $lhs, $rhs, %args) = @_;

    if (@_ == 2) {
        return map {
            ref eq 'ARRAY' ? [ hyper($op, $_) ] :
            ref eq 'HASH'  ? { hyper($op, $_) } :
                             applyop($op, $_)
        } @$lhs if ref $lhs eq 'ARRAY';

        return map {
            $_ => ref eq 'ARRAY' ? [ hyper($op, $_) ] :
                  ref eq 'HASH'  ? { hyper($op, $_) } :
                                   applyop($op, $lhs->{$_})
        } keys %$lhs if ref $lhs eq 'HASH';

        return applyop($op, $$lhs) if ref $lhs eq 'SCALAR';
        return applyop($op, $lhs);
    }

    my $dwim_left  = $args{dwim_left}  || $args{dwim};
    my $dwim_right = $args{dwim_right} || $args{dwim};

    if (ref $lhs eq 'HASH' && ref $rhs eq 'HASH') {
        my %results;
        my @keys = do {
            if ($dwim_left && $dwim_right) { # intersection
                grep { exists $rhs->{$_} } keys %$lhs;
            }
            elsif ($dwim_left) {
                keys %$rhs;
            }
            elsif ($dwim_right) {
                keys %$lhs;
            }
            else { # union
                uniq keys %$lhs, keys %$rhs;
            }
        };

        for my $key (@keys) {
            $results{$key} = do {
                if ( exists $lhs->{$key} && exists $rhs->{$key} ) {
                    applyop( $op, $lhs->{$key}, $rhs->{$key} );
                }
                else {
                    exists $ops{$op}{res}[1] ? $ops{$op}{res}[1] :
                    exists $lhs->{$key}      ? $lhs->{$key}      :
                                               $rhs->{$key}      ;
                }
            };
        }

        return %results;
    }
    elsif (ref $lhs eq 'HASH') {
        die "Sorry, structures on both sides of non-dwimmy hyper() are not of same shape:\n"
            . "    left:  HASH\n"
            . "    right: " . ref($rhs) . "\n"
            unless $dwim_right;

        return map { $_ => applyop( $op, $lhs->{$_}, $rhs ) } keys %$lhs;
    }
    elsif (ref $rhs eq 'HASH') {
        die "Sorry, structures on both sides of non-dwimmy hyper() are not of same shape:\n"
            . "    left: " . ref($rhs) . "\n"
            . "    right:  HASH\n"
            unless $dwim_left;

        return map { $_ => applyop( $op, $lhs, $rhs->{$_} ) } keys %$rhs;
    }

    my $length;
    $lhs = [$lhs] if ref $lhs ne 'ARRAY';
    $rhs = [$rhs] if ref $rhs ne 'ARRAY';

    if (!$dwim_left && !$dwim_right) {
        die "Sorry, arrayrefs passed to non-dwimmy hyper() are not of same length:\n"
            . "    left:  " . @$lhs . " elements\n"
            . "    right: " . @$rhs . " elements\n"
            if @$lhs != @$rhs;

        $length = @$lhs;
    }
    elsif (!$dwim_left) {
        $length = @$lhs;
    }
    elsif (!$dwim_right) {
        $length = @$rhs;
    }
    else {
        $length = @$lhs > @$rhs ? @$lhs : @$rhs;
    }

    my @results;
    my $lhs_index = 0;
    my $rhs_index = 0;
    for (1 .. $length) {
        $lhs_index = 0 if $dwim_left  && $lhs_index > $#{$lhs};
        $rhs_index = 0 if $dwim_right && $rhs_index > $#{$rhs};
        push @results, applyop($op, $lhs->[$lhs_index], $rhs->[$rhs_index]);
    }
    continue {
        $lhs_index++;
        $rhs_index++;
    }

    return @results;
}

sub applyop {
    my ($op) = @_;
    my $type;
    ($op, $type) = _get_op_info($op);

    return unless $op;
    return $ops{$op}{sub}->( @_[1, 2] )
        if $type eq 'infix'
        || $type eq 'postcircumfix';
    return $ops{$op}{sub}->( $_[1] );
}

sub reverseop {
    my ($op) = @_;

    return applyop( $op, $_[1]    ) if $op =~ m{^ (?: pre | post ) fix : }x;
    return applyop( $op, @_[1, 2] );
}

sub _get_op_info {
    my ($op) = @_;
    my ($type) = $op =~ m{^ (\w+) : }x;

    if (!$type) {
        $type = "infix";
        $op   = "infix:$op";
    }

    return unless exists $ops{$op};
    return $op, $type;
}

1;

__END__

=head1 NAME

Operator::Util - A selection of array and hash functions that extend operators

=head1 VERSION

This document describes Operator::Util version 0.05.

=head1 SYNOPSIS

    use Operator::Util qw(
        reduce reducewith
        zip zipwith
        cross crosswith
        hyper hyperwith
        applyop reverseop
    );

=head1 DESCRIPTION

Warning: This is an early release of Operator::Util.  Not all features
described in this document are complete.  Please see the L</TODO> list for
details.

A pragmatic approach at providing the functionality of many of Perl 6's
meta-operators in Perl 5.

The terms "operator string" or "opstring" are used to describe a string that
represents an operator, such as the string C<'+'> for the addition operator or
the string C<'.'> for the concatenation operator.  Opstrings default to binary
infix operators and the short form may be used, e.g., C<'*'> instead of
C<'infix:*'>.  All other operator types (prefix, postfix, circumfix, and
postcircumfix) must have the type prepended in the opstrings, e.g.,
C<prefix:++> and C<postcircumfix:{}>.

When a list is passed as an argument for any of the functions, it must be
either an array reference or a scalar value that will be used as a
single-element list.

The following functions are provided but are not exported by default.

=head2 Reduction

=over 4

=item reduce OPSTRING, LIST [, triangle => 1 ]

C<reducewith> is an alias for C<reduce>.  It may be desirable to use
C<reducewith> to avoid naming conflicts or confusion with
L<List::Util/reduce>.

Any infix opstring (except for non-associating operators) can be passed to
C<reduce> along with an arrayref to reduce the array using that operation:

    reduce('+', [1, 2, 3])  # 1 + 2 + 3 = 6
    my @a = (5, 6)
    reduce('*', \@a)        # 5 * 6 = 30

C<reduce> associates the same way as the operator used:

    reduce('-', [4, 3, 2])   # 4-3-2 = (4-3)-2 = -1
    reduce('**', [4, 3, 2])  # 4**3**2 = 4**(3**2) = 262144

For comparison operators (like C<<>), all reduced pairs of operands are broken
out into groups and joined with C<&&> because Perl 5 doesn't support
comparison operator chaining:

    reduce('<', [1, 3, 5])  # 1 < 3 && 3 < 5

If fewer than two elements are given, the results will vary depending on the
operator:

    reduce('+', [])   # 0
    reduce('+', [5])  # 5
    reduce('*', [])   # 1
    reduce('*', [5])  # 5

If there is one element, the C<reduce> returns that one element.  However,
this default doesn't make sense for operators like C<<> that don't return
the same type as they take, so these kinds of operators overload the
single-element case to return something more meaningful.

You can also reduce the comma operator, although there isn't much point in
doing so.  This just returns an arrayref that compares deeply to the arrayref
passed in:

    [1, 2, 3]
    reduce(',', [1, 2, 3])  # same thing

Operators with zero-element arrayrefs return the following values:

    **    # 1    (arguably nonsensical)
    =~    # 1    (also for 1 arg)
    !~    # 1    (also for 1 arg)
    *     # 1
    /     # fail (reduce is nonsensical)
    %     # fail (reduce is nonsensical)
    x     # fail (reduce is nonsensical)
    +     # 0
    -     # 0
    .     # ''
    <<    # fail (reduce is nonsensical)
    >>    # fail (reduce is nonsensical)
    <     # 1    (also for 1 arg)
    >     # 1    (also for 1 arg)
    <=    # 1    (also for 1 arg)
    >=    # 1    (also for 1 arg)
    lt    # 1    (also for 1 arg)
    le    # 1    (also for 1 arg)
    gt    # 1    (also for 1 arg)
    ge    # 1    (also for 1 arg)
    ==    # 1    (also for 1 arg)
    !=    # 1    (also for 1 arg)
    eq    # 1    (also for 1 arg)
    ne    # 1    (also for 1 arg)
    ~~    # 1    (also for 1 arg)
    &     # -1   (from ^0, the 2's complement in arbitrary precision)
    |     # 0
    ^     # 0
    &&    # 1
    ||    # 0
    //    # 0
    =     # undef (same for all assignment operators)
    ,     # []

You can say

    reduce('||', [a(), b(), c(), d()])

to return the first true result, but the evaluation of the list is controlled
by the semantics of the list, not the semantics of C<||>.

To generate all intermediate results along with the final result, you can set
the C<triangle> argument:

    reduce('+', [1..5], triangle=>1)  # (1, 3, 6, 10, 15)

The visual picture of a triangle is not accidental.  To produce a triangular
list of lists, you can use a "triangular comma":

    reduce(',', [1..5], triangle=>1)
    # [1],
    # [1,2],
    # [1,2,3],
    # [1,2,3,4],
    # [1,2,3,4,5]

=back

=head2 Zip

=over 4

=item zipwith OPSTRING, LIST1, LIST2

=item zip LIST1, LIST2

The C<zipwith> function may be passed any infix opstring.  It applies the operator
across all groupings of its list elements.

The string concatenating form is:

    zipwith('.', ['a','b'], [1,2])  # ('a1', 'b2')

The list concatenating form when used like this:

    zipwith(',', ['a','b'], [1,2], ['x','y'])

produces

    ('a', 1, 'x', 'b', 2, 'y')

This list form is common enough to have a shortcut, calling C<zip> without an
opstring as the first argument will use C<,> by default:

    zip(['a','b'], [1,2], ['x','y'])

also produces

    ('a', 1, 'x', 'b', 2, 'y')

Any non-mutating infix operator may be used.

    zipwith('*', [1,2], [3,4])  # (3, 8)

All assignment operators are considered mutating.

If the underlying operator is non-associating, so is C<zipwith>, except for
basic comparison operators since a chaining workaround is provided:

    zipwith('cmp', \@a, \@b, \@c)  # ILLEGAL
    zipwith('eq', \@a, \@b, \@c)   # ok

The underlying operator is always applied with its own associativity, just as
the corresponding C<reduce> operator would do.

All lists are assumed to be flat; multidimensional lists are handled by
treating the first dimension as the only dimension.

The response is a flat list by default.  To return a list of arrayrefs, unset
the C<flat> argument:

    zip(['a','b'], [1,2], ['x','y'], flat=>0)

produces:

    (['a', 1, 'x'], ['b', 2, 'y'])

=back

=head2 Cross

=over 4

=item crosswith OPSTRING, LIST1, LIST2

=item cross LIST1, LIST2

The C<crosswith> function may be passed any infix opstring.  It applies the
operator across all groupings of its list elements.

The string concatenating form is:

    crosswith('.', ['a','b'], [1,2])  # ('a1', 'a2', 'b1', 'b2')

The list concatenating form when used like this:

    crosswith(',', ['a','b'], [1,2], ['x','y'])

produces

    'a', 1, 'x',
    'a', 1, 'y',
    'a', 2, 'x',
    'a', 2, 'y',
    'b', 1, 'x',
    'b', 1, 'y',
    'b', 2, 'x',
    'b', 2, 'y'

This list form is common enough to have a shortcut, calling C<cross> without
an opstring as the first argument will use C<,> by default:

    cross(['a','b'], [1,2], ['x','y'])

Any non-mutating infix operator may be used.

    crosswith('*', [1,2], [3,4])  # (3, 4, 6, 8)

All assignment operators are considered mutating.

If the underlying operator is non-associating, so is C<crosswith>, except for
basic comparison operators since a chaining workaround is provided:

    crosswith('cmp', \@a, \@b, \@c)  # ILLEGAL
    crosswith('eq', \@a, \@b, \@c)   # ok

The underlying operator is always applied with its own associativity, just as
the corresponding C<reduce> operator would do.

All lists are assumed to be flat; multidimensional lists are handled by
treating the first dimension as the only dimension.

The response is a flat list by default.  To return a list of arrayrefs, unset
the C<flat> argument:

    cross(['a','b'], [1,2], ['x','y'], flat=>0)

produces:

    ['a', 1, 'x'],
    ['a', 1, 'y'],
    ['a', 2, 'x'],
    ['a', 2, 'y'],
    ['b', 1, 'x'],
    ['b', 1, 'y'],
    ['b', 2, 'x'],
    ['b', 2, 'y']

=back

=head2 Hyper

=over 4

=item hyper OPSTRING, LIST1, LIST2 [, dwim_left => 1, dwim_right => 1 ]

=item hyper OPSTRING, LIST

C<hyperwith> is an alias for C<hyper>.

The C<hyper> function operates on each element of its arrayref argument (or
arguments) and returns a single list of the results.  In other words, C<hyper>
distributes the operator over its elements as lists.

     hyper('prefix:-' [1,2,3])             # (-1,-2,-3)
     hyper('+', [1,1,2,3,5], [1,2,3,5,8])  # (2,3,5,8,13)

Unary operators always produce a list of exactly the same shape as their
single argument.  When infix operators are presented with two arrays of
identical shape, a result of that same shape is produced.  Otherwise the
result depends on what C<dwim> arguments are passed.

For an infix operator, if either argument is insufficiently dimensioned,
C<hyper> "upgrades" it, but only if you tell it to "dwim" on that side.

     hyper('-', [3,8,2,9,3,8], 1, dwim_right=>1)  # (2,7,1,8,2,7)
     hyper('+=', \@array, 42, dwim_right=>1)      # add 42 to each element

If you don't know whether one side or the other will be under-dimensioned, you
can dwim on both sides:

    hyper('*', $left, $right, dwim=>1)

The upgrade never happens on the non-dwim end of a C<hyper>.  If you write

    hyper('*', $bigger, $smaller, dwim_left=>1)
    hyper('*', $smaller, $bigger, dwim_right=>1)

an exception is thrown, and if you write

    hyper('*', $foo, $bar)

you are requiring the shapes to be identical, or an exception will be thrown.

For all hyper dwimminess, if a scalar is found where the other side expects an
array, the scalar is considered to be an array of one element.

Once we have two lists to process, we have to decide how to put the elements
into correspondence.  If both sides are dwimmy, the short list will have to be
repeated as many times as necessary to make the appropriate number of elements.

If only one side is dwimmy, then the list on that side only will be grown or
truncated to fit the list on the non-dwimmy side.

This produces an array the same length as the corresponding dimension on the
other side.  The original operator is then recursively applied to each
corresponding pair of elements, in case there are more dimensions to handle.

Here are some examples:

    hyper('+', [1,2,3,4], [1,2]               ) # always error
    hyper('+', [1,2,3,4], [1,2], dwim=>1      ) # (2,4,4,6) rhs dwims to 1,2,1,2
    hyper('+', [1,2,3],   [1,2], dwim=>1      ) # (2,4,4)   rhs dwims to 1,2,1
    hyper('+', [1,2,3,4], [1,2], dwim_left=>1 ) # (2,4)     lhs dwims to 1,2
    hyper('+', [1,2,3,4], [1,2], dwim_right=>1) # (2,4,4,6) rhs dwims to 1,2,1,2
    hyper('+', [1,2,3],   [1,2], dwim_right=>1) # (2,4,4)   rhs dwims to 1,2,1
    hyper('+', [1,2,3],   1,     dwim_right=>1) # (2,3,4)   rhs dwims to 1,1,1

Another way to look at it is that the dwimmy array's elements are indexed
modulo its number of elements so as to produce as many or as few elements as
necessary.

Note that each element of a dwimmy list may in turn be expanded into another
dimension if necessary, so you can, for instance, add one to all the elements
of a matrix regardless of its dimensionality:

    hyper('+=', \@fancy, 1, dwim_right=>1)

On the non-dwimmy side, any scalar value will be treated as an array of one
element, and for infix operators must be matched by an equivalent one-element
array on the other side.  That is, C<hyper> is guaranteed to degenerate to the
corresponding scalar operation when all its arguments are non-array arguments.

When using a unary operator no dwimmery is ever needed:

     @negatives = hyper('prefix:-', \@positives)

     hyper('postfix:++', \@positions)              # increment each
     hyper('->', \@objects, 'run', dwim_right=>1)  # call ->run() on each
     hyper('length', ['f','oo','bar'])             # (1, 2, 3)

Note that method calls are infix operators with a string used for the method
name.

Hyper operators are defined recursively on nested arrays, so:

    hyper('prefix:-', [[1, 2], 3])  # ([-1, -2], -3)

Likewise the dwimminess of dwimmy infixes propagates:

    hyper('+', [[1, 2], 3], [4, [5, 6]], dwim=>1)  # [[5, 6], [8, 9]]

C<hyper> may be applied to hashes as well as to arrays.  In this case
"dwimminess" says whether to ignore keys that do not exist in the other hash,
while "non-dwimminess" says to use all keys that are in either hash.  That is,

    hyper('+', \%foo, \%bar, dwim=>1)

gives you the intersection of the keys, while

    hyper('+', \%foo, \%bar)

gives you the union of the keys.  Asymmetrical hypers are also useful; for
instance, if you say:

    hyper('+', \%outer, \%inner, dwim_right=>1)

only the %inner keys that already exist in %outer will occur in the result.
Note, however, that you want

    hyper('+=', \%outer, \%inner)

in order to pass accumulated statistics up a tree, assuming you want %outer to
have the union of keys.

Unary hash hypers and binary hypers that have only one hash operand will apply
the hyper operator to just the values but return a new hash value with the
same set of keys as the original hash.

     hyper('prefix:-' {a => 1, b => 2, c => 3})  # (a => -1, b => -2, c => -3)

=back

=head2 Flat list vs. "list of lists"

The optional named-argument C<flat> can be passed to any of the above
functions.  It defaults to C<1>, which causes the function to return a flat
list.  When set to C<0>, it causes the return value from each operator to be
stored in an array ref, resulting in a "list of lists" being returned from the
function.

    zip([1..3], ['a'..'c'])           # 1, 'a', 2, 'b', 3, 'c'
    zip([1..3], ['a'..'c'], flat=>0)  # [1, 'a'], [2, 'b'], [3, 'c']

=head2 Other utils

=over 4

=item applyop OPSTRING, OPERAND1, OPERAND2

=item applyop OPSTRING, OPERAND

Apply the operator OPSTRING to the operands OPERAND1 and OPERAND2.  If an
unary opstring is provided, only the first operand will be used.

    applyop('.', 'foo', 'bar')  # foobar
    applyop('prefix:++', 5)     # 6

=item reverseop OPSTRING, OPERAND1, OPERAND2

C<reverseop> provides the same functionality as C<applyop> except that
OPERAND1 and OPERAND2 are reversed.

    reverseop('.', 'foo', 'bar')  # barfoo

If an unary opstring is used, C<reverseop> has the same functionality as
C<applyop>.

=back

=head1 TODO

=over

=item * Allow more than two arrayrefs with C<zipwith>, C<crosswith>, and
C<hyper>

=item * Support multi-dimensional binary operator distribution with C<hyper>

=item * Support the C<flat =E<gt> 0> option

=item * Add C<warn>ings on errors instead of simply C<return>ing

=item * Add named unary operators such as C<uc> and C<lc>

=item * Support meta-operator literals such as C<Z> and C<X> in C<applyop>

=item * Add C<evalop> for C<eval>ing strings including meta-operator literals

=item * Should the first argument optionally be a subroutine ref instead of an
operator string?

=item * Should the C<flat =E<gt> 0> option be changed to C<lol =E<gt> 1>?

=back

=head1 SEE ALSO

=over

=item * L<perlop>

=item * L<List::MoreUtils/pairwise> is similar to C<zip> except that its first
argument is a block instead of an operator string and the remaining arguments
are arrays instead of array refs:

    pairwise { $a + $b }, @array1, @array2  # List::MoreUtils
    zip '+', \@array1, \@array2             # Operator::Util

=item * C<mesh> a.k.a. L<List::MoreUtils/zip> is similar to C<zip> except that
the arguments are arrays instead of array refs:

    mesh @array1, @array2   # List::MoreUtils
    zip \@array1, \@array2  # Operator::Util

=item * L<Set::CrossProduct> is an object-oriented alternative to C<cross>

=item * The "Meta operators" section of Synopsis 3: Perl 6 Operators
(L<http://perlcabal.org/syn/S03.html#Meta_operators>) is the inspiration for
this module

=back

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 ACKNOWLEDGEMENTS

=over

=item * This module is based on the Perl 6 specification, as described in the
Synopsis and implemented in Rakudo

=item * Much of the documentation is taken directly from Synopsis 3: Perl 6
Operators (L<http://perlcabal.org/syn/S03.html>)

=item * The tests were forked from the Official Perl 6 Test Suite
(L<https://github.com/perl6/roast>)

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2010, 2011 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
