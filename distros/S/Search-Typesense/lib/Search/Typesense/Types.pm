package Search::Typesense::Types;

# ABSTRACT: Types and type tools for Search::Typesense

use strict;
use warnings;
use Type::Library -base;
use Type::Utils -all;

# this gets us compile and compile_named
use Type::Params;

our $VERSION = '0.08';

our @EXPORT_OK;

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
    push @EXPORT_OK => (
        'compile',          # from Type::Params
        'compile_named',    # from Type::Params
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Typesense::Types - Types and type tools for Search::Typesense

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    package Search::Typesense;

    use Search::Typesense::Types qw(
      ArrayRef
      Dict
      Enum
      HashRef
      InstanceOf
      Str
      compile
    );

=head1 DESCRIPTION

This is an internal package for L<Search::Typesense>. It's probably overkill,
but if we want to be more strict later, this gives us the basics.

=head1 TYPE LIBRARIES

We automatically include the types from the following:

=over

=item * L<Types::Standard>

=item * L<Types::Common::Numeric>

=item * L<Types::Common::String>

=back

=head1 EXTRAS

The following extra functions are exported on demand or if use the C<:all> export tag.

=over

=item * C<compile>

See L<Type::Params>

=item * C<compile_named>

See L<Type::Params>

=item * C<slurpy>

See L<Types::Standard>

=back

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@allaroundtheworld.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
