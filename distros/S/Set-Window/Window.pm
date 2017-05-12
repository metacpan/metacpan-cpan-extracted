# Copyright 1996-2002 by Steven McDougall.  
# This module is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Set::Window;

use 5.6.0;
use strict;
use vars qw($VERSION @ISA);

require Exporter;

@ISA     = qw(Exporter);
$VERSION = '1.01';


sub new_lr
{
    my($class, $left, $right) = @_;
    $right < $left and return empty $class;
    bless [$left, $right], $class
}


sub new_ll
{
    my($class, $left, $length) = @_;
    $length  < 1 and return empty $class;
    bless [$left, $left+$length-1], $class
}


sub left   
{ 
    my $window = shift;
    my($left, $right) = @$window;
    $right < $left and return undef;
    $left
}


sub right
{ 
    my $window = shift;
    my($left, $right) = @$window;
    $right < $left and return undef;
    $right
}


sub size
{ 
    my $window = shift;
    my($left, $right) = @$window;
    $right - $left + 1
}

*length = \&size;	#deprecated


sub elements
{
    my $window = shift;
    my($left, $right) = @$window;
    my @elements = ($left .. $right);
    wantarray ? @elements : \@elements
}


sub bounds
{
    my $window = shift;
    my($left, $right) = @$window;
    $right < $left and return undef;
    my @bounds = ($left, $right);
    wantarray ? @bounds : \@bounds
}


sub empty
{
    my $arg = shift;
    my $ref = ref $arg;

    $ref ? 
	$arg->[1] < $arg->[0] :
	bless [0, -1], $arg
}


sub equal
{
    my($w1, $w2) = @_;
    $w1->[0]==$w2->[0] and $w1->[1]==$w2->[1]
}


sub equivalent
{
    my($w1, $w2) = @_;
    $w1->[1] - $w1->[0] == $w2->[1] - $w2->[0]
}


sub copy
{
    my $window = shift;
    bless [ @$window ], ref $window
}


sub offset
{
    my($window, $offset) = @_;
    $window = copy $window;
    empty $window and return $window;

    $window->[0] += $offset;
    $window->[1] += $offset;
    $window
}


sub inset
{
    my($window, $inset) = @_;
    $window = copy $window;
    empty $window and return $window;

    $window->[0] += $inset;
    $window->[1] -= $inset;

    empty $window and return empty (ref $window);

    $window
}


sub cover
{
    my(@windows) = grep { not empty $_ } @_;

    @windows or return empty Set::Window;

    my $window = shift @windows;
    my $cover  = copy  $window;

    for $window (@windows)
    {
	$cover->[0] > $window->[0] and $cover->[0] = $window->[0];
	$cover->[1] < $window->[1] and $cover->[1] = $window->[1];
    }

    $cover
}


sub intersect
{
    my(@windows) = @_;

    grep { empty $_ } @windows and return empty Set::Window;

    my $window = shift @windows;
    my $core   = copy  $window;

    for $window (@windows)
    {
	$core->[0] < $window->[0] and $core->[0] = $window->[0];
	$core->[1] > $window->[1] and $core->[1] = $window->[1];
    }
    
    empty $core and return empty Set::Window;
    $core
}


sub series
{
    my($window, $length) = @_;
    $length < 1 and return undef;

    my($left, $right) = @$window;
    my @left   = $left .. $right + 1 - $length;
    my $class  = ref $window;
    my @series = map { $class->new_ll($_, $length) } @left;
    wantarray ? @series : \@series
}

1

__END__

=head1 NAME

Set::Window - Manages an interval on the integer line

=head1 SYNOPSIS

  use Set::Window;
  
  $window  = new_lr Set::Window $left, $right;
  $window  = new_ll Set::Window $left, $length;
  $window  = empty  Set::Window;
  
  $left     = $window->left;
  $right    = $window->right;
  $size     = $window->size;  
  @bounds   = $window->bounds;
  @elements = $window->elements;
  
  empty     $window;
  eqivalent $window1 $window2;
  equal     $window1 $window2;
  
  $window = copy        $window
  $window = offset      $window $offset
  $window = inset       $window $inset
  $window = cover       $window @windows
  $window = intersect   $window @windows
  
  @windows = $window->series($length);

=head1 REQUIRES

Perl 5.6.0, Exporter

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

A C<Set::Window> object represents a window on the integer line; 
that is,
a finite set of consecutive integers.

Methods are provided for creating and modifying windows,
for obtaining information about windows,
and for performing some simple set operations on windows.

=head2 The empty window

The empty window represents the empty set.
Like the empty set, the empty window is unique.

=head1 METHODS

=head2 Creation

=over 4

=item C<new_lr Set::Window> I<$left>C<,> I<$right>

Creates and returns a new C<Set::Window> object.
I<$left> and I<$right> specify the first and last integers in the window.

If I<$right> is less than I<$left>, returns the empty window.

=item C<new_ll Set::Window> I<$left>C<,> I<$length>

Creates and returns a new Set::Window object.
I<$left> is the first integer in the interval,
and I<$length> is the number of integers in the interval

If I<$length> is less than one, returns the empty window.

=item C<empty Set::Window>

Creates and returns an empty C<Set::Window> object.

=back

=head2 Access

=over 4

=item I<$window>C<-E<gt>left>

Returns the first integer in the window,
or undef if I<$window> is empty.

=item I<$window>C<-E<gt>right>

Returns the last integer in the window,
or undef if I<$window> is empty.

=item I<$window>C<-E<gt>size>

Returns the number of integers in the window.

The identity 
I<$window>C<-E<gt>size == >I<$window>C<-E<gt>right - >I<$window>C<-E<gt>left + 1>
holds for all non-empty windows.

=item I<$window>C<-E<gt>bounds>

Returns a list of the first and last integers in I<$window>,
or undef if I<$window> is empty.
In scalar context, returns an array reference.

=item I<$window>C<-E<gt>elements>

Returns a list of the integers in I<$window>, in order.
In scalar context, returns an array reference.

=back

=head2 Predicates

=over 4

=item C<empty> I<$window>

Returns true iff I<$window> is empty.

=item C<equal> I<$window1> I<$window2>

Returns true iff I<$window1> and I<$window2> are the same.

All empty windows are C<equal>.

=item C<equivalent> I<$window1> I<$window2>

Returns true iff I<$window1> and I<$window2> are the same size.

=back

=head2 Modification

These methods implement copy semantics:
modifications are made to a copy of the original window.
The original window is unaltered, 
and the new window is returned.

=over 4

=item C<copy> I<$window>

Creates and returns a (deep) copy of I<$window>.

=item C<offset> I<$window> I<$offset>

Makes a copy of I<$window>,
and then shifts it by I<$offset>.
Positive values of I<$offset> move the window to the right;
negative values move it to the left.
Returns the new window.

If C<offset> is called on the empty window,
it returns the empty window.

=item C<inset> I<$window> I<$inset>

Makes a copy of I<$window>,
and then shrinks it by I<$inset> at each end.
If I<$inset> is negative,
the window expands.
Returns the new window.

If C<inset> is called on the empty window,
it returns the empty window.

=item C<cover> I<$window> I<@windows>

Creates and returns the smallest window that covers (i.e. contains)
I<$window> and all the I<@windows>.

=item C<intersect> I<$window> I<@windows>

Creates and returns the largest window that is contained by
I<$window> and all the I<@windows>.
This may be the empty window.

=back

=head2 Utility

=over 4

=item I<$window>C<-E<gt>series(>I<$length>C<)>

Returns a list of all the windows of I<$length> that are contained
in I<$window>, ordered from left to right.
In scalar context, returns an array reference.

If I<$length> is greater than I<$window>C<-E<gt>length>,
the list will be empty.
If I<$length> is less than 1, returns undef.


=back

=head1 DIAGNOSTICS

None.

=head1 NOTES

=head2 Why?

Belive it or not, 
I actually needed this structure in a program.
Maybe someone else will need it, too.

=head2 Weight

C<Set::Window> objects are designed to be lightweight.
If you need more functionality, consider using C<Set::IntSpan>.

=head2 Error handling

C<Set::Window> does not issue any diganostics;
in particular,
none of the methods can C<die>.

Calling C<elements> on a large window can lead to an 
C<out of memory!> message,
which cannot be trapped (as of perl 5.003).
Applications that must retain control can protect calls to C<elements>
with an C<intersect>

  $limit = new_lr Set::Window -1_000_000, 1_000_000;
  @elements = $window->intersect($limit)->elements;

or check the size of I<$window> first:

  length $window < 2_000_000 and @elements = elements $window;

Operations involving the empty window are handled consistently.
They return valid results if they make sense, and undef otherwise.
Thus:

  Set::Window->empty->elements

returns an empty list, because the empty window has no elements, while

  Set::Windows->empty->bounds

returns undef, because the empty window has no first or last element.

=head1 SEE ALSO

perl(1), C<Set::IntSpan>

=head1 AUTHOR

Steven McDougall, swmcd@world.std.com

=head1 COPYRIGHT

Copyright 1996-200 by Steven McDougall. 
All rights reserved.
This module is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
