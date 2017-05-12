#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Types;
{
  $Net::Gandi::Types::VERSION = '1.122180';
}

# ABSTRACT: Net::Gandi types

use MooseX::Types::Moose qw/Str ArrayRef HashRef/;
use MooseX::Types -declare => [qw(Client Apikey)];

class_type Client, { class => 'Net::Gandi::Client' };

subtype Apikey,
    as Str,
    where   { length($_) == 24 },
    message { "Apikey must be larger 24" };

1;

__END__
=pod

=head1 NAME

Net::Gandi::Types - Net::Gandi types

=head1 VERSION

version 1.122180

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

