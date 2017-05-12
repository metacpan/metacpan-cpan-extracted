use strict;
use warnings;
package Test::Deep::Type; # git description: v0.007-3-g1a9faf7
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: A Test::Deep plugin for validating type constraints
# KEYWORDS: testing tests plugin types

our $VERSION = '0.008';

use Exporter 5.57 'import';
our @EXPORT = qw(is_type);

sub is_type($)
{
    return Test::Deep::Type::Object->new($_[0]);
}

package # hide from PAUSE
    Test::Deep::Type::Object;

our $VERSION = '0.008';

use parent 'Test::Deep::Cmp';
use Scalar::Util ();
use Try::Tiny ();

sub init
{
    my ($self, $type) = @_;
    $self->{type} = $type;
}

sub descend
{
    my ($self, $got) = @_;
    return $self->_is_type($self->{type}, $got);
}

sub diag_message
{
    my ($self, $where) = @_;
    my $name = $self->_type_name($self->{type});
    return 'Validating ' . $where . ' as a'
        . (defined $name ? ' ' . $name : 'n unknown')
        . ' type';
}

# we do not define a diagnostics sub, so we get the one produced by deep_diag
# showing exactly what part of the data structure failed. This calls renderGot
# and renderVal:

sub renderGot
{
    my $self = shift;   # my $got = shift;
    return defined $self->{error_message} ? $self->{error_message} : 'failed';
}

sub renderExp
{
    my $self = shift;
    return 'no error';
}

sub _is_type
{
    my ($self, $type, $got) = @_;

    if (eval { $type->can('validate') })
    {
        $self->{error_message} = $type->validate($got);
        return !defined($self->{error_message});
    }

    # last ditch effort - use the type as a coderef
    if (__isa_coderef($type))
    {
        return Try::Tiny::try {
            $type->($got)
        } Try::Tiny::catch {
            chomp($self->{error_message} = $_);
            undef;
        };
    }

    # for now, stringy types are not supported. If a known Moose type, use
    # Moose::Util::TypeConstraints::find_type_constraint('typename').

    $self->{error_message} = "Can't figure out how to use '$type' as a type";
    return;
}

sub _type_name
{
    my ($self, $type) = @_;

    # use $type->name if we can
    my $name = eval { $type->name };
    return $name if $name;

    # ...or stringify, if possible
    return "$type" if overload::Method($type, '""');

    # ...or its package name, if it has one
    my $class = Scalar::Util::blessed($type);
    return $class if defined $class;

    # plain old subref perhaps?
    return;
}

sub __isa_coderef
{
    ref $_[0] eq 'CODE'
        or (Scalar::Util::reftype($_[0]) || '') eq 'CODE'
        or overload::Method($_[0], '&{}')
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::Type - A Test::Deep plugin for validating type constraints

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;
    use Test::Deep::Type;
    use MooseX::Types::Moose 'Str';

    cmp_deeply(
        {
            message => 'ack I am slain',
            counter => 123,
        },
        {
            message => is_type(Str),
            counter => is_type(sub { die "not an integer" unless int($_[0]) eq $_[0] }),
        },
        'message is a plain string, counter is a number',
    );

=head1 DESCRIPTION

This is a L<Test::Deep> plugin that
provides the sub C<is_type> to indicate that the data
being tested must validate against the passed type. This is an actual type
I<object>, not a string name -- for example something provided via
L<MooseX::Types>, or a plain old coderef that returns a bool (such as what
might be used in a L<Moo> type constraint).

=head1 FUNCTIONS

=head2 C<is_type>

Exported by default; to be used within a L<Test::Deep> comparison function
such as L<cmp_deeply|Test::Deep/COMPARISON FUNCTIONS>.
As this module aims to be a solution for many popular
type systems, we attempt to use the type in multiple ways:

=over 4

=item L<MooseX::Types>/L<Moose::Meta::TypeConstraint>-style types:

If the C<validate> method exists, it is invoked on the type object with the
data as its parameter (which should return C<undef> on success, and the error
message on failure).

=item coderef/L<Moo>-style types:

If the type appears to be or act like a coderef (either a coderef, blessed or
unblessed, or possesses a coderef overload) the type is invoked as a sub, with
the data as its parameter. Its return value is treated as a boolean; if it
also dies with a message describing the failure, this message is used in the
failure diagnostics.

L<Type::Tiny> types fall into this category, and are fully supported.

=back

=for Pod::Coverage descend
diag_message
init
renderExp
renderGot

=head1 CAVEATS

Regular strings describing a type under a particular system
(e.g. L<Moose>, L<Params::Validate>) are not currently supported.

=head1 SEE ALSO

=over 4

=item *

L<Test::Deep>

=item *

L<Test::TypeConstraints>

=item *

L<Test::Type>

=item *

L<Test::Deep::Matcher>

=item *

L<MooseX::Types>

=item *

L<Moose::Meta::TypeConstraint>

=item *

L<Moo>

=item *

L<Type::Tiny>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Deep-Type>
(or L<bug-Test-Deep-Type@rt.cpan.org|mailto:bug-Test-Deep-Type@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/perl-qa.html>.

There is also an irc channel available for users of this distribution, at
L<C<#perl> on C<irc.perl.org>|irc://irc.perl.org/#perl-qa>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Graham Knop

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
