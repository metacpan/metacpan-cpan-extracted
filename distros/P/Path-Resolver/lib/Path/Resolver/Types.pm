package Path::Resolver::Types 3.100455;
# ABSTRACT: types for use with Path::Resolver
use MooseX::Types -declare => [ qw(AbsFilePath) ];
use MooseX::Types::Moose qw(Str);

use namespace::autoclean;

use Path::Class::File;

#pod =head1 OVERVIEW
#pod
#pod This library will contain any new types needed for use with Path::Resolver.
#pod
#pod =head1 TYPES
#pod
#pod =head2 AbsFilePath
#pod
#pod This type validates Path::Class::File objects that are absolute paths and
#pod readable.  They can be coerced from strings by creating a new Path::Class::File
#pod from the string.
#pod
#pod =cut

subtype AbsFilePath,
  as class_type('Path::Class::File'),
  where { $_->is_absolute and -r "$_" };

coerce AbsFilePath, from Str, via { Path::Class::File->new($_) };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Types - types for use with Path::Resolver

=head1 VERSION

version 3.100455

=head1 OVERVIEW

This library will contain any new types needed for use with Path::Resolver.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 TYPES

=head2 AbsFilePath

This type validates Path::Class::File objects that are absolute paths and
readable.  They can be coerced from strings by creating a new Path::Class::File
from the string.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
