package Stringify::Deep;

use strict;
use warnings;

require Exporter;
use base 'Exporter';

our @EXPORT    = qw();
our @EXPORT_OK = qw(deep_stringify);

use Data::Structure::Util qw(unbless);
use Ref::Util             qw(is_blessed_ref);

our $VERSION = '0.03';

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
    return unless defined $struct;

    my $params  = shift || {};
    my $reftype = ref $struct || '';

    if ($reftype eq 'HASH') {
        for my $key (keys %$struct) {
            $struct->{$key} = deep_stringify($struct->{$key}, $params);
        }
        return $struct;
    }

    if ($reftype eq 'ARRAY') {
        for my $i (0..scalar(@$struct) - 1) {
            $struct->[$i] = deep_stringify($struct->[$i], $params);
        }
        return $struct;
    }

    if (
        $reftype &&
        $params->{leave_unoverloaded_objects_intact} &&
        is_blessed_ref($struct) &&
        ! overload::Method($struct, q{""})
    ) {
        unbless $struct;
        $reftype = ref $struct || '';
        if ($reftype =~ /^(ARRAY|HASH)$/) {
            return $struct;
        }
    }

    return "$struct";
}

=head1 DEPENDENCIES

Data::Structure::Util, Scalar::Util

=head1 AUTHORS

Michael Aquilina <aquilina@cpan.org>

Thanks to LARRYL (Larry Leszczynski) for his patch contributing performance improvements.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2018 Michael Aquilina.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;


