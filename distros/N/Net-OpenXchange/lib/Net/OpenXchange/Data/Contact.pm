use Modern::Perl;
package Net::OpenXchange::Data::Contact;
BEGIN {
  $Net::OpenXchange::Data::Contact::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: OpenXchange detailed contact data

use MooseX::Types::Email qw(EmailAddress);

has display_name => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 500,
);

has first_name => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 501,
);

has last_name => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 502,
);

has nickname => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 515,
);

has telephone_business1 => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 542,
);

has email1 => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => EmailAddress,
    ox_id  => 555,
);

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Data::Contact - OpenXchange detailed contact data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Data::Contact is a role providing attributes for
L<Net::OpenXchange::Object|Net::OpenXchange::Object> packages.

=head1 ATTRIBUTES

=head2 display_name (Str)

Display name of this contact

=head2 first_name (Str)

First name of this contact

=head2 last_name (Str)

Last name of this contact

=head2 nickname (Str)

Nick name of this contact

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedContactData|http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedContactData>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

