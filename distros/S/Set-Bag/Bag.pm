package Set::Bag;

$VERSION = 1.012;

=pod

=head1 NAME

    Set::Bag - bag (multiset) class

=head1 SYNOPSIS

    use Set::Bag;

    my $bag_a = Set::Bag->new(apples => 3, oranges => 4);
    my $bag_b = Set::Bag->new(mangos => 3);
    my $bag_c = Set::Bag->new(apples => 1);
    my $bag_d = ...;
    
    # Methods

    $bag_b->insert(apples => 1);
    $bag_b->delete(mangos => 1);

    $bag_b->insert(cherries => 1, $bag_c);

    my @b_elements = $bag_b->elements;  # ('apples','cherries','mangos')
    my @b_grab_app = $bag_b->grab('apples', 'cherries'); # (3, 1)
    my @a_grab_all = $bag_a->grab;  # (apples => 3, oranges => 4)

    print "bag_a     sum      bag_b = ", $bag_a->sum($bag_b),          "\n";
    print "bag_a  difference  bag_b = ", $bag_a->difference($bag_b),   "\n";

    print "bag_a    union     bag_b = ", $bag_a->union($bag_b),        "\n";
    print "bag_a intersection bag_b = ", $bag_a->intersection($bag_b), "\n";

    print "bag_b complement = ", $bag_b->complement, "\n";

    # Operator Overloads

    print "bag_a = $bag_a\n";   # (apples => 3, oranges => 4)

    $bag_b += $bag_c;         # Insert
    $bag_b -= $bag_d;         # Delete

    print "bag_b = $bag_b\n";

    print "bag_a + bag_b = ", $bag_a + $bag_b, "\n";  # Sum
    print "bag_a - bag_b = ", $bag_a - $bag_b, "\n";  # Difference

    print "bag_a | bag_b = ", $bag_a | $bag_b, "\n";  # Union
    print "bag_a & bag_b = ", $bag_a & $bag_b, "\n";  # Intersection

    $bag_b |= $bag_c;         # Maximize
    $bag_b &= $bag_d;         # Minimize

    print "good\n" if     $bag_a eq "(apples => 3, oranges => 4)";  # Eq
    print "bad\n"  unless $bag_a ne "(apples => 3, oranges => 4)";  # Ne

    print "-bag_b = ", -$bag_b"\n";     # Complement

    $bag_c->delete(apples => 5);      # Would abort.

    print "Can",          # Cannot ...
          $bag_c->over_delete() ? "" : "not",
          " over delete from bag_c\n";

    $bag_c->over_delete(1);
    print "Can",          # Can ...
          $bag_c->over_delete() ? "" : "not",
          " over delete from bag_c\n";
    $bag_c->delete(apples => 5);      # Would succeed.

    print $bag_c, "\n";         # ()


=head1 DESCRIPTION

This module implements a simple bag (multiset) class.

A bag may contain one or more instances of elements.  One may add and
delete one or more instances at a time.

If one attempts to delete more instances than there are to delete
from, the default behavious of B<delete> is to raise an exception.
The B<over_delete> method can be used to control this behaviour.

Inserting or removing negative number of instances translates into
removing or inserting positive number of instances, respectively.

The B<sum> is also known as the I<additive union>.  It leaves in
the result bag the sum of all the instances of all bags.

Before using the B<difference> you very often will need the B<over_delete>.

The B<union> is also known as the I<maximal union>.  It leaves in
the result bag the maximal number of instances in all bags.

The B<intersection> leaves in the result bag only the elements that
have instances in all bags and of those the minimal number of instances.

The B<complement> will leave in the result bag the maximal number of
instances I<ever> seen (via B<new>, B<insert>, B<sum>, or B<maximize>)
in the bag minus the current number of instances in the bag.

The B<grab> method returns the contents of a bag.
If used with parameters the parameters are the elements and their
number of instances in the bag are returned.  If an element that
does not exist in the bag is grabbed for,
the number of instances returned for that element will be C<undef>.
If used without parameters the elements are returned in pseudorandom order.

=head1 NOTES

Beware the low precedence of C<|> and C<&> compared with C<eq> and C<ne>.

=head1 AUTHOR

David Oswald C<< <davido@cpan.org> >> is the current maintainer, starting with
release 1.010.

Jarkko Hietaniemi C<< <jhi@iki.fi> >> was the original author.

=head1 LICENSE AND COPYRIGHT

Copyright O'Reilly and Associates.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<perlgpl> and L<perlartistic> for full details.

=cut

require 5.004;
use strict;
use overload
    q("")  => \&bag,
    q(eq)  => \&eq,
    q(ne)  => \&ne,
    q(+=)  => \&insert,
    q(-=)  => \&delete,
    q(+)   => \&sum,
    q(-)   => \&difference,
    q(|=)  => \&maximize,
    q(&=)  => \&minimize,
    q(|)   => \&union,
    q(&)   => \&intersection,
    q(neg) => \&complement,
    q(=)   => \&copy,
    ;

my $over_delete = 'Set::Bag::__over_delete__';

sub new {
    my $type = shift;
    my $bag = { };
    bless $bag, $type;
    $bag->insert(@_);
    return $bag;
}

sub elements {
    my $bag = shift;
    return sort grep { $_ ne $over_delete } keys %{$bag};
}

sub bag {
    my $bag = shift;
    return
  "(" .
  (join ", ",
             map { "$_ => $bag->{$_}" }
                 sort grep { ! /^Set::Bag::/ } $bag->elements) .
  ")";
}

sub eq {
    return $_[2] ? "$_[1]" eq $_[0] : "$_[0]" eq $_[1];
}

sub ne {
    return not $_[0] eq $_[1];
}

sub grab {
    my $bag = shift;
    if (@_) {
      return @{$bag}{@_};
    } else {
      return %{$bag};
    }
}

sub _merge {
    my $bag     = shift;
    my $sub     = shift; # Element subroutine.
    my $ref_arg = shift; # Argument list.
    my $ref_bag = ref $bag;
    while (my $e = shift @{$ref_arg}) {
        if (ref $e eq $ref_bag) {
            foreach my $c ($e->elements) {
                $sub->($bag, $c, $e->{$c});
            }
        } else {
            $sub->($bag, $e, shift @{$ref_arg});
        }
    }
}

sub _underload { # Undo overload effects on @_.
    # If the last argument looks like it might be
    # residue of the operator overload system, drop it.
    pop @{$_[0]}
        if (not defined $_[0]->[-1] and not ref $_[0]->[-1]) or
     $_[0]->[-1] eq '';
}

my %universe;

sub _insert {
    my ($bag, $e, $n) = @_;
    $bag->{$e} += int $n;
    $universe{$e} = $bag->{$e}
        if $bag->{$e} > ($universe{$e} || 0);
}

sub over_delete {
    my $bag = shift;

    if (@_ == 1) {
  $bag->{$over_delete} = shift;
    } elsif (@_ == 0) {
  return ($bag->{$over_delete} ||= 0);
    } else {
  die "Set::Bag::over_delete: too many arguments (",
      $#_+1,
      "), want 0 or 1\n";
    }
}

sub _delete {
    my ($bag, $e, $n) = @_;

    unless ($bag->over_delete) {
  my $m = $bag->{$e} || 0;
  $m >= $n or
      die "Set::Bag::delete: '$e' $m < $n\n";
    }
    $bag->{$e} -= int $n;
    delete $bag->{$e} if $bag->{$e} < 1;
}


sub insert {
    _underload(\@_);
    my $bag = shift;
    $bag->_merge(sub { my ($bag, $e, $n) = @_;
           if ($n > 0) {
         $bag->_insert($e, $n);
           } elsif ($n < 0) {
         $bag->_delete($e, -$n);
           } },
     \@_);
    return $bag;
}

sub delete {
    _underload(\@_);
    my $bag = shift;
    $bag->_merge(sub { my ($bag, $e, $n) = @_;
          if ($n > 0) {
        $bag->_delete($e, $n);
          } elsif ($n < 0) {
        $bag->_insert($e, -$n);
          } },
    \@_);
    return $bag;
}

sub maximize {
    _underload(\@_);
    my $max = shift;
    $max->_merge(sub { my ($bag, $e, $n) = @_;
          $bag->{$e} = $n
        if not defined $bag->{$e} or $n > $bag->{$e};
          $universe{$e} = $n
                  if $n > ($universe{$e} || 0) },
    \@_);
    return $max;
}

sub minimize {
    _underload(\@_);
    my $min = shift;
    my %min;
    foreach my $e ($min->elements) { $min{$e} = 1 }
    $min->_merge(sub { my ($bag, $e, $n) = @_;
          $min{$e}++;
          $bag->{$e} = $n
        if defined $bag->{$e} and $n < $bag->{$e} },
    \@_);
    foreach my $e (keys %min) { delete $min->{$e} if $min{$e} == 1 }
    return $min;
}

sub copy {
    my $bag = shift;
    return (ref $bag)->new($bag->grab);
}

sub sum {
    my $union = (shift)->copy;
    $union->insert(@_);
    return $union;
}

sub difference {
    my $difference = (shift)->copy;
    $difference->delete(@_);
    return $difference;
}

sub union {
    my $union = (shift)->copy;
    $union->maximize(@_);
    return $union;
}

sub intersection {
    my $intersection = (shift)->copy;
    $intersection->minimize(@_);
    return $intersection;
}

sub complement {
    my $bag = shift;
    my $complement  = (ref $bag)->new;
    foreach my $e (keys %universe) {
  $complement->{$e} = $universe{$e} - ($bag->{$e} || 0);
  delete $complement->{$e} unless $complement->{$e};
    }
    return $complement;
}

1;
