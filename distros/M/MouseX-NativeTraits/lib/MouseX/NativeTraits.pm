package MouseX::NativeTraits;
use 5.006_002;
use Mouse::Role;

our $VERSION = '1.09';

requires qw(method_provider_class helper_type);

#has default         => (
#    is       => 'bare', # don't create new methods
#    required => 1,
#);
has type_constraint => (
    is       => 'bare', # don't create new methods
    required => 1,
);

has method_provider => (
    is  => 'ro',
    isa => 'Object',

    builder => '_build_method_provider',
);

sub _build_method_provider{
    my($self) = @_;
    my $mpc = $self->method_provider_class;
    Mouse::Util::load_class($mpc);
    return $mpc->new(attr => $self);
}

before _process_options => sub {
    my ( $self, $name, $options ) = @_;

    my $type = $self->helper_type;

    $options->{isa} = $type
        if !exists $options->{isa};

    my $isa = Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint(
        $options->{isa} );

    ( $isa->is_a_type_of($type) )
        || $self->throw_error(
        "The type constraint for $name must be a subtype of $type but it's a $isa");

    $options->{default} = $self->_default_default
        if !exists $options->{default} && $self->can('_default_default');
};

around _canonicalize_handles => sub {
    my($next, $self) = @_;
    my $handles_ref = $self->handles;
    if( ref($handles_ref) ne 'HASH' ) {
        $self->throw_error(
            "The 'handles' option must be a HASH reference, not $handles_ref");
    }

    my $provider = $self->method_provider;

    my %handles;
    while(my($name, $to) = each %{$handles_ref}){
        $to = [$to] if !ref $to;
        $provider->has_generator($to->[0])
            or $self->throw_error("$to->[0] is an unsupported method type");
        $handles{$name} = $to;
    }

    return %handles;
};

around _make_delegation_method => sub {
    my( $next, $self, $handle_name, $method_to_call) = @_;
    return $self->method_provider->generate($handle_name, $method_to_call);
};

no Mouse::Role;
1;
__END__

=head1 NAME

MouseX::NativeTraits - Extend your attribute interfaces for Mouse

=head1 VERSION

This document describes MouseX::NativeTraits version 1.09.

=head1 SYNOPSIS

    package MyClass;
    use Mouse;

    has mapping => (
        traits    => ['Hash'],
        is        => 'rw',
        isa       => 'HashRef[Str]',
        default   => sub { +{} },
        handles   => {
            exists_in_mapping => 'exists',
            ids_in_mapping    => 'keys',
            get_mapping       => 'get',
            set_mapping       => 'set',
            set_quantity      => [ set => 'quantity' ],
        },
    );

=head1 DESCRIPTION

While L<Mouse> attributes provide a way to name your accessors, readers,
writers, clearers and predicates, MouseX::NativeTraits provides commonly
used attribute helper methods for more specific types of data.

As seen in the L</SYNOPSIS>, you specify the data structure via the
C<traits> parameter. These traits will be loaded automatically, so
you need not load MouseX::NativeTraits explicitly.

This extension is compatible with Moose native traits, although it
is not a part of Mouse core.

=head1 PARAMETERS

=head2 handles

This is like C<handles> in L<Mouse/has>, but only HASH references are
allowed.  Keys are method names that you want installed locally, and values are
methods from the method providers (below).  Currying with delegated methods
works normally for C<< handles >>.

=head1 NATIVE TRAITS

=head2 Array

Common methods for array references.

    has 'queue' => (
       traits     => ['Array'],
       is         => 'ro',
       isa        => 'ArrayRef[Str]',
       default    => sub { [] },
       handles    => {
           add_item  => 'push',
           next_item => 'shift',
       }
    );

See L<MouseX::NativeTraits::ArrayRef>.

=head2 Hash

Common methods for hash references.

    has 'options' => (
        traits    => ['Hash'],
        is        => 'ro',
        isa       => 'HashRef[Str]',
        default   => sub { {} },
        handles   => {
            set_option => 'set',
            get_option => 'get',
            has_option => 'exists',
        }
    );

See L<MouseX::NativeTraits::HashRef>.

=head2 Code

Common methods for code references.

    has 'callback' => (
       traits     => ['Code'],
       is         => 'ro',
       isa        => 'CodeRef',
       default    => sub { sub { 'called' } },
       handles    => {
           call => 'execute',
       }
    );

See L<MouseX::NativeTraits::CodeRef>.

=head2 Bool

Common methods for boolean values.

    has 'is_lit' => (
        traits    => ['Bool'],
        is        => 'rw',
        isa       => 'Bool',
        default   => 0,
        handles   => {
            illuminate  => 'set',
            darken      => 'unset',
            flip_switch => 'toggle',
            is_dark     => 'not',
        }
    );

See L<MouseX::NativeTraits::Bool>.

=head2 String

Common methods for string operations.

    has text => (
        traits    => ['String'],
        is        => 'rw',
        isa       => 'Str',
        default   => q{},
        handles   => {
            add_text     => 'append',
            replace_text => 'replace', # or replace_globally
        }
    );

See L<MouseX::NativeTraits::Str>.

=head2 Number

Common numerical operations.

    has value => (
        traits    => ['Number'],
        is        => 'ro',
        isa       => 'Int',
        default   => 5,
        handles   => {
            set => 'set',
            add => 'add',
            sub => 'sub',
            mul => 'mul',
            div => 'div',
            mod => 'mod',
            abs => 'abs',
        }
    );

See L<MouseX::NativeTraits::Num>.

=head2 Counter

Methods for incrementing and decrementing a counter attribute.

    has counter => (
        traits    => ['Counter'],
        is        => 'ro',
        isa       => 'Num',
        default   => 0,
        handles   => {
            inc_counter   => 'inc',
            dec_counter   => 'dec',
            reset_counter => 'reset',
        }
    );

See L<MouseX::NativeTraits::Counter>.

=head1 DEPENDENCIES

Perl 5.6.2 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Mouse>

L<MouseX::AttributeHelpers>

L<Moose>

L<Moose::Meta::Attribute::Native>

L<MooseX::AttributeHelpers>

=head1 AUTHORS

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

This module is based on Moose native traits written by Stevan Little and others.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx), mostly based on Moose, which is (c)
Infinity Interactive, Inc (L<http://www.iinteractive.com>).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
