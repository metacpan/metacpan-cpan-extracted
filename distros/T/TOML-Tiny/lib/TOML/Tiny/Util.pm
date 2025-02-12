package TOML::Tiny::Util;
# ABSTRACT: utility functions used by TOML::Tiny
$TOML::Tiny::Util::VERSION = '0.19';
use strict;
use warnings;
no warnings 'experimental';
use v5.18;

use TOML::Tiny::Grammar;

use parent 'Exporter';

our @EXPORT_OK = qw(
  is_strict_array
);

my @_type_map = (
  [ qr{Float},      'float' ],
  [ qr{Int},        'integer' ],
  [ qr{Boolean},    'bool' ],
  [ qr{^$Boolean},  'bool' ],
  [ qr{^$Float},    'float' ],
  [ qr{^$Integer},  'integer' ],
  [ qr{^$DateTime}, 'float' ],
);

sub is_strict_array {
  my $arr = shift;

  my @types = map{
    my $value = $_;
    my $type;

    my $ref = ref($value);
    if ($ref eq 'ARRAY') {
      $type = 'array';
    }
    elsif ($ref eq 'HASH') {
      $type = 'table';
    }
    # Do a little heuristic guess-work
    else {
      for my $pair (@_type_map) {
        if ( $ref =~ m{$pair->[0]} ) {
          $type = $pair->[1];
         }
         last;
      }
    }
    $type //= 'string';

    return $type;
  } @$arr;

  my $t = shift @types;

  for (@types) {
    return (undef, "expected value of type $t, but found $_")
      if $_ ne $t;
  }

  return (1, undef);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TOML::Tiny::Util - utility functions used by TOML::Tiny

=head1 VERSION

version 0.19

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
