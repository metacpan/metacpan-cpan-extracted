package Struct::Compare;

=head1 NAME

Struct::Compare - Recursive diff for perl structures.

=head1 SYNOPSIS

    use Struct::Compare;
    my $is_different = compare($ref1, $ref2);

=head1 DESCRIPTION

Compares two values of any type and structure and returns true if they
are the same. It does a deep comparison of the structures, so a hash
of a hash of a whatever will be compared correctly.

This is especially useful for writing unit tests for your modules!

=head1 PUBLIC FUNCTIONS

=over 4

=cut

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
use Carp qw(croak);

@ISA = qw(Exporter);
@EXPORT = qw(compare);

$VERSION = '1.0.1';

# TODO: document

use constant FALSE=>0;
use constant TRUE =>1;
use constant DEBUG=>0;

=item * $bool = compare($var1, $var2)

Recursively compares $var1 to $var2, returning false if either
structure is different than the other at any point. If both are
undefined, it returns true as well, because that is considered equal.

=cut

sub compare {
  my $x = shift;
  my $y = shift;

  if (@_) {
    croak "Too many items sent to compare";
  }

  return FALSE if   defined $x xor   defined $y;
  return TRUE  if ! defined $x and ! defined $y;

  my $a = ref $x ? $x : \$x;
  my $b = ref $y ? $y : \$y;

  print "\$a is a ", ref $a, "\n" if DEBUG;
  print "\$b is a ", ref $b, "\n" if DEBUG;

  return FALSE unless ref $a eq ref $b;

  if (ref $a eq 'SCALAR') {
    print "a = $$a, b = $$b\n" if DEBUG;
    return $$a eq $$b;
  }

  if (ref $a eq 'HASH') {
    my @keys = keys %{$a};
    my $max = scalar(@keys);
    return FALSE if $max != scalar(keys %{$b});
    return TRUE  if $max == 0;

    # first just look to see if there are any keys not in the other;
    my $found = 0;
    foreach my $key (@keys) {
      $found++ if exists $b->{$key};
    }

    return FALSE if $found != $max;

    # now compare the values
    foreach my $key (@keys) {
      # WARN: recursion may get really deep.
      return FALSE unless compare($a->{$key}, $b->{$key});
    }

    return TRUE;
  }

  if (ref $a eq 'ARRAY') {
    my $max = scalar(@{$a});
    return FALSE if $max != scalar(@{$b});
    return TRUE  if $max == 0;

    for (my $i = 0; $i < $max; ++$i) {
      # WARN: recursion may get really deep.
      return FALSE unless compare($a->[$i], $b->[$i]);
    }

    return TRUE;
  }

  # FIX: doesn't deal with non-basic types... see if you can fake it.

  return FALSE;
}

1;

__END__

=back

=head1 BUGS/NEEDED ENHANCEMENTS

=item * blessed references

compare currently does not deal with blessed references. I need to
look into how to deal with this.

=head1 LICENSE

(The MIT License)

Copyright (c) 2001 Ryan Davis, Zen Spider Software

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Ryan Davis <ryand-cmp@zenspider.com>
Zen Spider Software <http://www.zenspider.com/ZSS/>

=cut
