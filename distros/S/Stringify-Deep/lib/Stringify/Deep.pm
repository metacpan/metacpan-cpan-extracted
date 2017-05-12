package Stringify::Deep;

use strict;
use warnings;

require Exporter;
use base 'Exporter';

our @EXPORT    = qw();
our @EXPORT_OK = qw(deep_stringify);

use Data::Structure::Util qw(get_refs unbless);
use Scalar::Util          qw(blessed);

our $VERSION = '0.02';

=head1 NAME

Stringify::Deep - Stringifies elements in data structures for easy serialization

=head1 SYNOPSIS

  my $struct = {
      foo => 1,
      bar => [ 1, 2, 7, {
          blah => $some_obj, # Object that's overloaded so it stringifies to "1234"
          foo  => [ 1, 2, 3, 4, 5 ],
      } ],
  };

  $struct = deep_stringify($struct);

  # $struct is now:
  # {
  #     foo => 1,
  #     bar => [ 1, 2, 7, {
  #        blah => "1234",
  #        foo  => [ 1, 2, 3, 4, 5 ],
  #     } ],
  # }

=head1 DESCRIPTION

Let's say that you have a complex data structure that you need to serialize using one of the dozens of tools available on the CPAN, but the structure contains objects, code references, or other things that don't serialize so nicely.

Given a data structure, this module will return the same data structure, but with all contained objects/references that aren't ARRAY or HASH references evaluated as a string.

=head1 FUNCTIONS

=head2 deep_stringify( $struct, $params )

Given a data structure, returns the same structure, but with all contained objects/references other than ARRAY and HASH references evaluated as a string.

Takes an optional hash reference of parameters:

=over 4

=item * B<leave_unoverloaded_objects_intact>

If this parameter is passed, Stringify::Deep will unbless and stringify objects that overload stringification, but will leave the data structure intact for objects that don't overload stringification.

=back

=cut

sub deep_stringify {
    my $struct  = shift;
    my $params  = shift || {};
    my $reftype = ref $struct || '';

    if ($reftype eq 'ARRAY') {
        for my $i (0..scalar(@$struct) - 1) {
            $struct->[$i] = deep_stringify($struct->[$i], $params);
        }
    } elsif ($reftype eq 'HASH') {
        for my $key (keys %$struct) {
            $struct->{$key} = deep_stringify($struct->{$key}, $params);
        }
    } else {
        if (blessed $struct) {
            my $overloaded = overload::Method( $struct, q{""} );
            if (!$overloaded and $params->{leave_unoverloaded_objects_intact}) {
                unbless $struct;
                $reftype = ref $struct || '';
            }
        }

        if ($reftype !~ /^(ARRAY|HASH)$/) {
            $struct = "$struct"
                if defined $struct;
        }
    }

    return $struct;
}

=head1 DEPENDENCIES

Data::Structure::Util, Scalar::Util

=head1 AUTHORS

Michael Aquilina <aquilina@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 Michael Aquilina.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

