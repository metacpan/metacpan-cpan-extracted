use Modern::Perl;
package Net::OpenXchange::Object::Folder;
BEGIN {
  $Net::OpenXchange::Object::Folder::VERSION = '0.001';
}

use Moose;
use namespace::autoclean;

# ABSTRACT: OpenXchange folder object

with qw(
  Net::OpenXchange::Object
  Net::OpenXchange::Data::CommonFolder
  Net::OpenXchange::Data::Folder
);

__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Object::Folder - OpenXchange folder object

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Object::Folder consumes the following roles. Look at their
documentation for provided methods and attributes.

=over 4

=item *

L<Net::OpenXchange::Object|Net::OpenXchange::Object>

=item *

L<Net::OpenXchange::Data::CommonFolder|Net::OpenXchange::Data::CommonFolder>

=back

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

