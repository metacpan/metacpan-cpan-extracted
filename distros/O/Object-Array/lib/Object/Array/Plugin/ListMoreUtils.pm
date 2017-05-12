package Object::Array::Plugin::ListMoreUtils;

use strict;
use warnings;

our @UTILS;
BEGIN {
  @UTILS = qw(
             any
             all
             none
             notall
             true
             false
             firstidx first_index
             lastidx  last_index
             insert_after
             insert_after_string
             apply
             after
             after_incl
             before
             before_incl
             indexes
             firstval first_value
             lastval  last_value
             natatime
             uniq
             minmax
           );
}

use List::MoreUtils ();
use Sub::Install ();
use Sub::Exporter -setup => {
  exports => [ @UTILS, 'contains' ],
};

my %NEED_REF = (
  map { $_ => 1 }
    qw(
       insert_after
       insert_after_string
     ),
);

=head1 NAME

Object::Array::Plugin::ListMoreUtils

=head1 DESCRIPTION

Add methods to Object::Array corresponding to functions from List::MoreUtils.

=head1 METHODS

See List::MoreUtils for details of these methods (functions).

=head2 any

=head2 all

=head2 none

=head2 notall

=head2 true

=head2 false

=head2 firstidx

=head2 first_index

=head2 lastidx

=head2 last_index

=head2 insert_after

=head2 insert_after_string

=head2 apply

=head2 after

=head2 after_incl

=head2 before

=head2 before_incl

=head2 indexes

=head2 firstval

=head2 first_value

=head2 lastval

=head2 last_value

=head2 natatime

=head2 uniq

=head2 minmax

=head1 NEW METHODS

=head2 contains

  if ($arr->contains(1)) { ... }

Convenient wrapper around firstidx.  Uses C<==> to compare
references and numbers, C<eq> for everything else.

=cut

BEGIN {
  for my $util (@UTILS) {
    Sub::Install::install_sub({
      as   => $util,
      code => sub {
        my $self = shift;
        no strict 'refs';
        # use $self->ref explicitly because List::MoreUtils
        # segfaults otherwise (at least under 5.6.1) --
        # probably unfriendliness with overloading
        &{"List::MoreUtils::$util"}(
          @_, $NEED_REF{$util} ? $self->ref : $self->elements,
        );
      },
    });
  }
}

sub _is_number {
  my $val = shift;
  # XXX horrible, but catches cases like 5 <=> "5.00"
  use warnings FATAL => qw(numeric);
  eval { $val = 0 + $val };
  return $@ !~ /isn't numeric/;
}

sub contains {
  my ($self, $value) = @_;
  my $code;
  if (not defined $value) {
    $code = sub { not defined $_ };
  } elsif (ref($value) || _is_number($value)) {
    $code = sub { defined($_) && (ref($_) || _is_number($_)) && $_ == $value };
  } else {
    $code = sub { defined($_) && !ref($_) && $_ eq $value };
  }
  return $self->firstidx($code) != -1;
}

1;
