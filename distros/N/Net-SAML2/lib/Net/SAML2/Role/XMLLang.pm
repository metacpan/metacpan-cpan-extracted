package Net::SAML2::Role::XMLLang;
use Moose::Role;

our $VERSION = '0.82'; # VERSION

# ABSTRACT: Common behaviour for XML language settings

use namespace::autoclean;

has _lang => (
    isa     => 'Str',
    is      => 'ro',
    default => 'en',
    init_arg => 'lang',
);


sub lang {
  my $self = shift;
  return { 'xml:lang' => $self->_lang }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Role::XMLLang - Common behaviour for XML language settings

=head1 VERSION

version 0.82

=head1 CONSTRUCTOR ARGUMENTS

=over

=item B<lang>

Set the language, defaults to English (C<en>).

=back

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
