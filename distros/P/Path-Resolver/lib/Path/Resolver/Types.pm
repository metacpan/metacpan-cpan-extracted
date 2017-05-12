package Path::Resolver::Types;
{
  $Path::Resolver::Types::VERSION = '3.100454';
}
# ABSTRACT: types for use with Path::Resolver
use MooseX::Types -declare => [ qw(AbsFilePath) ];
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

use Path::Class::File;


subtype AbsFilePath,
  as class_type('Path::Class::File'),
  where { $_->is_absolute and -r "$_" };

coerce AbsFilePath, from Str, via { Path::Class::File->new($_) };

1;

__END__

=pod

=head1 NAME

Path::Resolver::Types - types for use with Path::Resolver

=head1 VERSION

version 3.100454

=head1 OVERVIEW

This library will contain any new types needed for use with Path::Resolver.

=head1 TYPES

=head2 AbsFilePath

This type validates Path::Class::File objects that are absolute paths and
readable.  They can be coerced from strings by creating a new Path::Class::File
from the string.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
