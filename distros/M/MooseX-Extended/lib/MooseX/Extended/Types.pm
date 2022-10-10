package MooseX::Extended::Types;

# ABSTRACT: Keep our type tools organized

use strict;
use warnings;
use Type::Library -base;
use Type::Utils -all;
use Type::Params ':all';

# EXPORT_OK, but not :all
use Types::Standard qw(
  slurpy
);

our $VERSION = '0.34';
our @EXPORT_OK;

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
    push @EXPORT_OK => (
        @Type::Params::EXPORT,
        @Type::Params::EXPORT_OK,
        @Types::Standard::EXPORT_OK,
    );
    our %EXPORT_TAGS = (
        all      => \@EXPORT_OK,
        Standard => [ Types::Standard->type_names ],
        Numeric  => [ qw/Num Int Bool/, Types::Common::Numeric->type_names ],
        String   => [ qw/Str/,          Types::Common::String->type_names ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Extended::Types - Keep our type tools organized

=head1 VERSION

version 0.34

=head1 SYNOPSIS

    use MooseX::Extended;
    use MooseX::Extended::Types;

    use MooseX::Extended::Types qw(
      ArrayRef
      Dict
      Enum
      HashRef
      InstanceOf
      Str
      compile
    );

As a convenience, if you're using L<MooseX::Extended>, you can do this:

    use MooseX::Extended types => [qw(
      ArrayRef
      Dict
      Enum
      HashRef
      InstanceOf
      Str
      compile
    )];

If you're brave:

    use MooseX::Extended types => ':all';

But that exports I<everything> and it's easy to have surprising conflicts.

=head1 DESCRIPTION

A basic set of useful types for C<MooseX::Extended>, as provided by
L<Type::Tiny>. Using these is preferred to using using strings due to runtime
versus compile-time failures. For example:

    # fails at runtime, if ->name is set
    param name => ( isa => 'str' );

    # fails at compile-time
    param name => ( isa => str );

=head1 TYPE LIBRARIES

We automatically include the types from the following:

=over

=item * L<Types::Standard>

You can import them individually or with the C<:Standard> tag:

    use MooseX::Extended::Types types => 'Str';
    use MooseX::Extended::Types types => [ 'Str', 'ArrayRef' ];
    use MooseX::Extended::Types types => ':Standard';

Using the C<:Standard> tag is equivalent to:

    use Types::Standard;

No import list is supplied directly to the module, so non-default type
functions must be asked for by name.

=item * L<Types::Common::Numeric>

You can import them individually or with the C<:Numeric> tag:

    use MooseX::Extended::Types types => 'Int';
    use MooseX::Extended::Types types => [ 'Int', 'NegativeOrZeroNum' ];
    use MooseX::Extended::Types types => ':Numeric';

Using the C<:Numeric> tag is equivalent to:

    use Types::Common::Numeric;

No import list is supplied directly to the module, so non-default type
functions must be asked for by name.

=item * L<Types::Common::String>

You can import them individually or with the C<:String> tag:

    use MooseX::Extended::Types types => 'NonEmptyStr';
    use MooseX::Extended::Types types => [ 'NonEmptyStr', 'UpperCaseStr' ];
    use MooseX::Extended::Types types => ':String';

Using the C<:String> tag is equivalent to:

    use Types::Common::String;

No import list is supplied directly to the module, so non-default type
functions must be asked for by name.

=back

=head1 EXTRAS

The following extra functions are exported on demand or if using the C<:all>
export tag (but you probably don't want to use that tag).

=head2 L<Type::Params>

=over

=item * C<compile>

=item * C<compile_named>

=item * C<multisig>

=item * C<validate>

=item * C<validate_named>

=item * C<compile_named_oo>

=item * C<Invocant>

=item * C<wrap_subs>

=item * C<wrap_methods>

=item * C<ArgsObject>

=back

=head2 L<Types::Standard>

=over 4

=item * C<slurpy>

=back

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
