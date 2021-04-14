package OpenAPI::Generator::Util;

use strict;
use warnings;

use Carp;
use Exporter qw(import);

our @EXPORT_OK = qw(
  merge_definitions
);

sub merge_definitions {

  my(@definitions) = @_;

  croak 'no definitions to merge' unless @definitions;

  if (scalar @definitions == 1) {
    return $definitions[0];
  }

  my %common_def;

  for my $def (@definitions) {

    # paths
    while (my($path, $path_schema) = each %{$def->{paths}}) {
      while (my($method, $method_schema) = each %{$path_schema}) {
        if (exists $common_def{paths}{$path}{$method}) {
          croak "$method $path duplicates";
        }
        $common_def{paths}{$path}{$method} = $method_schema;
      }
    }

    # comp param
    while (my($param, $param_schema) = each %{$def->{components}{parameters}}) {
      if (exists $common_def{components}{parameters}{$param}) {
        croak "param $param duplicates"
      }
      $common_def{components}{parameters}{$param} = $param_schema;
    }

    # comp schemas
    while (my($comp, $comp_schema) = each %{$def->{components}{schemas}}) {
      if (exists $common_def{components}{schemas}{$comp}) {
        croak "schema $comp duplicates"
      }
      $common_def{components}{schemas}{$comp} = $comp_schema;
    }

    # comp security
    while (my($security, $security_schema) = each %{$def->{components}{securitySchemes}}) {
      if (exists $common_def{components}{securitySchemes}{$security}) {
        croak "security $security duplicates"
      }
      $common_def{components}{securitySchemes}{$security} = $security_schema;
    }
  }

  return \%common_def;
}

1

__END__

=head1 NAME

OpenAPI::Generator::Util - subroutines to manipulate openapi schemes

=head1 SYNOPSIS

  # merge definitions
  my $merged_def = merge_definitions(@definitions);

=head1 SUBROUTINES

=over 4

=item merge_definitions(@definitions)

Merge several OpenAPI definitions into one big. Be careful with duplicate routes and components

=back

=head1 AUTHOR

Anton Fedotov, C<< <tosha.fedotov.2000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<https://github.com/doojonio/OpenAPI-Generator/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc OpenAPI::Generator::Util

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Anton Fedotov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)