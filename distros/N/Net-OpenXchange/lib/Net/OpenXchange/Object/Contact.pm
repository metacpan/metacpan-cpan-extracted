use Modern::Perl;
package Net::OpenXchange::Object::Contact;
BEGIN {
  $Net::OpenXchange::Object::Contact::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: OpenXchange contact object

with qw(
  Net::OpenXchange::Object
  Net::OpenXchange::Data::Common
  Net::OpenXchange::Data::Contact
);

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Object::Contact - OpenXchange contact object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Object::Contact consumes the following roles. Look at their
documentation for provided methods and attributes.

=over 4

=item *

L<Net::OpenXchange::Object|Net::OpenXchange::Object>

=item *

L<Net::OpenXchange::Data::Common|Net::OpenXchange::Data::Common>

=back

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

