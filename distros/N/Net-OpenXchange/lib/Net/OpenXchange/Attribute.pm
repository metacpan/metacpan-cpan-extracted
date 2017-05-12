use Modern::Perl;
package Net::OpenXchange::Attribute;
BEGIN {
  $Net::OpenXchange::Attribute::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Attribute trait for OpenXchange objects

has ox_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Attribute - Attribute trait for OpenXchange objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

This trait is used for all attributes that map to OpenXchange's attributes.

=head1 SYNOPSIS

    package Net::OpenXchange::Data::MyFields;
    use Moose::Role;

    has myfield => (
        traits => ['Net::OpenXchange::Attribute'],
        is => 'rw',
        isa => 'Str',
        ox_id => 400,
    );

=head1 ATTRIBUTES

=head2 ox_id

ID of this attribute used by the OpenXchange API. Tables with these IDs can be
found at L<http://oxpedia.org/wiki/index.php?title=HTTP_API|http://oxpedia.org/wiki/index.php?title=HTTP_API>.

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

