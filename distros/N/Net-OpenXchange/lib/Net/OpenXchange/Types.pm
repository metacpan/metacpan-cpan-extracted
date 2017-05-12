use Modern::Perl;
package Net::OpenXchange::Types;
BEGIN {
  $Net::OpenXchange::Types::VERSION = '0.001';
}

# ABSTRACT: Moose type library for Net::OpenXchange

use MooseX::Types -declare => [qw(JSONXSBool JSONPPBool)];

use MooseX::Types::Moose qw(Bool);

class_type JSONXSBool, { class => 'JSON::XS::Boolean' };
class_type JSONPPBool, { class => 'JSON::PP::Boolean' };

coerce Bool, from JSONXSBool, via { 0 + $_ };

coerce Bool, from JSONPPBool, via { 0 + $_ };

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Types - Moose type library for Net::OpenXchange

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Types is an internal module for Net::OpenXchange providing a
bunch of Moose types and coercions.

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

