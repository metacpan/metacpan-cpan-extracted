package NestedMap;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(nestedmap);

$VERSION = '1.0';

use strict;
use warnings;

=head1 NAME

NestedMap - a module to make nesting map{}s inside map{}s easier

=head1 SYNOPSIS

  # show all combinations of (A,B,C) (a,b,c) and (1,2,3)
  print join("\n",
    nestedmap {
      nestedmap {
        nestedmap {
          join('',@NestedMap::stack[0..2])
        } qw(A B C)
      } qw(a b c)
    } qw(1 2 3)
  );

  # a zip() function for any number of lists of varying length
  sub zipn {
    my @args = @_;
    [
      nestedmap {
        nestedmap {
          defined($args[$_][$NestedMap::stack[1]]) ?
            $args[$_][$NestedMap::stack[1]] :
            ''
        } 0..$#args
      } 0 .. max(map { $#{$_[$_]} } 0..$#args)
    ]
  }
  
NB - older versions of perl may not like the code blocks I use in these
examples.  You may have to use:

  nestedmap sub { ... }, @list;

instead of

  nestedmap { ... } @list;

See the test suite for examples of the above code modified to use that
syntax.

=head1 DESCRIPTION

Perl's map{} function is very useful, but ain't so great when you try to
put map{}s inside map{}s, as inner maps can have no idea what the outer
map{}s are doing.  NestedMap solves that, by maintaining a stack of all
the nested map{}s' ideas of what $_ is.  It's useful if you want to
iterate over lists of lists.

It exports one function into your namespace ...

=over 4

=item nestedmap

This function takes any number of arguments, the first of which must be
a coderef (ie, either a reference to a subroutine, or an anonymous
subroutine).  That subroutine should take one argument.  It will be
called once for each of the remaining arguments given to nestedmap().
The return value of nestedmap() is a list of all the return values of
the user-supplied subroutine  Within your subroutine, $_ is available
just like in an ordinary map{}.  There is also an array called
@NestedMap::stack which lets you get at the 'parent' nestedmaps' values
of $_.  The first element (element 0) is your own $_, the second is the
parent's, the third is the grandparent's, and so on.  Yes, you can change
them.  That would be considered evil.  And funny.

=back

=head1 HOW IT DIFFERS FROM map{}

Because nestedmap() is a subroutine, as is the user-supplied function,
then unlike with map{} (which is a perl built-in) the value of @_ will not
remain the same inside a pile of nestedmap()s.  If you want to refer to the
same @_ throughout, then you will need to assign @_ to another variable
first.  See the zipn() example in the synopsis above.

=head1 BUGS

No bugs are known, but if you find any please let me know, and send a test
case.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism.  And,
while this is free software (both free-as-in-beer and free-as-in-speech) I
also welcome payment.  In particular, your bug reports will get moved to
the front of the queue if you buy me something from my wishlist, which can
be found at L<http://www.cantrell.org.uk/david/shopping-list/wishlist>.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

=head1 COPYRIGHT

Copyright 2003 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=cut

sub nestedmap(&@) {
    my $f = shift;
    map {
        local @NestedMap::stack = ($_, @NestedMap::stack);
        $f->($_);
    } @_
}
