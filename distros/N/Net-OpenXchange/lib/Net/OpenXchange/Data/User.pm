use Modern::Perl;
package Net::OpenXchange::Data::User;
BEGIN {
  $Net::OpenXchange::Data::User::VERSION = '0.001';
}

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: OpenXchange detailed user data

has timezone => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 611,
);

has login_info => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 615,
);

has locale => (
    traits => ['Net::OpenXchange::Attribute'],
    is     => 'rw',
    isa    => 'Str',
    ox_id  => 616,
);

1;


__END__
=pod

=head1 NAME

Net::OpenXchange::Data::User - OpenXchange detailed user data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Net::OpenXchange::Data::User is a role providing attributes for
L<Net::OpenXchange::Object|Net::OpenXchange::Object> packages.

=head1 ATTRIBUTES

=head2 login_info (DateTime)

User name

=head2 timezone (Str)

Selected timezone of this user, for example Europe/Berlin

=head2 locale (Str)

Selected locale of this user

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedUserData|http://oxpedia.org/wiki/index.php?title=HTTP_API#DetailedUserData>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

