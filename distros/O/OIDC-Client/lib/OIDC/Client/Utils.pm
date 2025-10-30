package OIDC::Client::Utils;

use utf8;
use Moose;
use Moose::Exporter;
use MooseX::Params::Validate;

=encoding utf8

=head1 NAME

OIDC::Client::Utils - Utility functions

=head1 DESCRIPTION

Exports utility functions.

=cut

Moose::Exporter->setup_import_methods(as_is => [qw/get_values_from_space_delimited_string/]);


=head1 FUNCTIONS

=head2 get_values_from_space_delimited_string( $value )

Returns the values (arrayref) from a space-delimited string value.

=cut

sub get_values_from_space_delimited_string {
  my ($str) = pos_validated_list(\@_, { isa => 'Str', optional => 0 });
  return [ grep { $_ ne '' } split(/\s+/, $str) ];
}

1;
