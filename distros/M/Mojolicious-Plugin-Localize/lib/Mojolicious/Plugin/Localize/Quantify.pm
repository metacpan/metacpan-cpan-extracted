package Mojolicious::Plugin::Localize::Quantify;
use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw/looks_like_number/;

# From http://search.cpan.org/~toddr/Locale-Maketext-1.26/lib/Locale/Maketext.pod
# >> The basic quant method that Locale::Maketext provides should be good for many languages. For some languages, it might be useful to modify it (or its constituent numerate method) to take a plural form in the two-argument call to quant (as in "[quant,_1,files]") if it's all-around easier to infer the singular form from the plural, than to infer the plural form from the singular. <<

our $RANGE_RE = qr/^\s*?([<>]?)\s*([-+]?\d+?)(?:\s*\.\.\s*([-+]?\d+))?\s*$/;

# Register the plugin
sub register {
  my ($self, $mojo) = @_;

  # Establish helper
  $mojo->helper(
    quant => sub {
      my $c = shift;
      my $num = shift;

      return '' unless looks_like_number $num;

      # Check for parameter hash
      my $param   = pop if $_[-1] && ref $_[-1] && ref $_[-1] eq 'HASH';
      my $default = shift;

      # There are no other dictionary entries
      return $default if !$param && @_ == 0;

      # Plural default value
      my $default_pl = shift;

      # Zero default value
      my $default_null = shift // $default;

      # It's a bit more complicated ...
      if ($param) {

        # Exact match found
        return $param->{$num} if exists $param->{$num};

        # Iterate over all parameters
        foreach (sort keys %$param) {
          next unless $_ =~ $RANGE_RE;

          # 'Littler than' or 'greater than'
          if ($1) {
            if ($1 eq '<') {
              return $param->{$_} if $num < $2;
            }
            else {
              return $param->{$_} if $num > $2;
            };
          }

          # Range
          elsif ($3) {
            return $param->{$_} if $num >= $2 && $num <= $3;
          };
        };

        # Check for 'even' value
        if ($num % 2 == 0) {
          return $param->{even} if exists $param->{even};
        }

        # Check for 'odd' value
        else {
          return $param->{odd} if exists $param->{odd};
        };
      };

      # Simple plural value
      if ($num > 1 || $num < -1) {
        return $default_pl // $default;
      }
      # Simple null value
      elsif ($num == 0) {
        return $default_null;
      };

      # Default value
      return $default;
    }
  );
};


1;


=pod

=head1 NAME

Mojolicious::Plugin::Localize::Quantify - Localize Quantifiable Expressions


=head1 SYNOPSIS

  my $g_counter = 5;

  # Get singular and plural expression, depending on number
  my $word = $c->quant($g_counter, 'guest', 'guests');

  # In templates
  %= quant $g_counter, 'guest', 'guests'


=head1 DESCRIPTION

L<Mojolicious::Plugin::Localize::Quantify> helps you to get countable expressions
of words depending on the number of units (e.g. singular or plural expressions).


=head1 METHODS

L<Mojolicious::Plugin::Localize::Quantify> inherits all methods
from L<Mojolicious::Plugin> and implements the following
new ones.


=head2 register

  # Mojolicious
  $mojo->plugin('Localize::Quantify');

  # Mojolicious::Lite
  plugin 'Localize::Quantify';

Called when registering the plugin.
The plugin is registered by L<Mojolicious::Plugin::Localize> by default.


=head1 HELPERS

=head2 quant

  my $number = 3;

  my $was = $c->quant($number, 'was', 'were');
  my $tree = $c->quant($number, 'tree', 'trees');
  print "There $was $number $tree.";
  # There were 3 trees.

  my $count = $c->quant($number, 'some', {
    0 => 'no',
    1 => 'one',
    2 => 'both',
    '3..11' => 'a few',
    12 => 'a dozen',
    '>50' => 'many'
  });
  print "There $was $count $tree.";
  # There were a few trees.

  # In templates
  %= quant $g_counter, 'guest', 'guests'

Return an expression based on a given number.

Expects at least 2 parameters: The number which the lookup is based on and
a default dictionary entry (e.g. a singular term).
This can be followed by two optional scalar parameters: the first optional
parameter is an entry chosen for all numerical values E<gt> 1 or E<lt> -1,
the second parameter is an entry chosen for the zero value.

A final hash reference can refine the lookup, overriding the given default parameters.
Supported keys for dictionary lookups are as follows:

=over 2

=item Exact Matches

  {
    2  => 'both',
    12 => 'dozens'
  }

=item Boundaries

  {
    '< 5'  => 'few',
    '> 14' => 'many'
  }

=item Ranges

  {
    '100 .. 999'   => 'hundreds',
    '1000 .. 9999' => 'thousands'
  }

=item Even/odd

  {
    even => 'robots',
    odd  => 'humans'
  }

=back

Exact matches have the highest precedence, followed by ranges and boundaries
in arbitrary order. Even and odd values will match before the default values.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Localize


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
