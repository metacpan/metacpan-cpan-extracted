package MooX::BuildArgs;

$MooX::BuildArgs::VERSION = '0.06';

=head1 NAME

MooX::BuildArgs - Save instantiation arguments for later use.

=head1 SYNOPSIS

    package Foo;
    use Moo;
    with 'MooX::BuildArgs';
    has bar => (is => 'ro');
    
    my $foo = Foo->new( bar => 32 );
    print $foo->build_args->{bar}; # 32

=head1 DESCRIPTION

It is often useful to be able to access the arguments that were
used to create an object in their unadulterated form, before any
coercions or init_args have changed them.  This L<Moo> role
provides the arguments via the L</build_args> attribute.

Note that no attempt is made to weaken the args.  So, if you use
this module and you have attributes with C<weak_ref> set the
references will not be weakened within L</build_args>.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'MooX::BuildArgsHooks';

around FINALIZE_BUILDARGS => sub{
    my ($orig, $class, $args) = @_;

    $args = $class->$orig( $args );

    return $class->FINALIZE_BUILD_ARGS_BUILDARGS( $args );
};

sub FINALIZE_BUILD_ARGS_BUILDARGS {
    my ($class, $args) = @_;

    $args->{_build_args} = { %$args };

    return $args;
}

=head1 ATTRIBUTES

=head2 build_args

    my $args_hashref = $object->build_args();

Returns a hashref containing the captured arguments.

=cut

has build_args => (
    is       => 'ro',
    init_arg => '_build_args',
);

1;
__END__

=head1 SEE ALSO

=over

=item *

L<MooX::BuildArgsHooks>

=item *

L<MooX::MethodProxyArgs>

=item *

L<MooX::Rebuild>

=item *

L<MooX::SingleArg>

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 CONTRIBUTORS

=over

=item *

Peter Pentchev <roamE<64>ringlet.net>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

