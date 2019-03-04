package MooX::SingleArg;
use 5.008001;
use strictures 2;
our $VERSION = '0.07';

=head1 NAME

MooX::SingleArg - Support single-argument instantiation.

=head2 SYNOPSIS

    package Foo;
    use Moo;
    with 'MooX::SingleArg';
    Foo->single_arg('bar');
    has bar => ( is=>'ro' );
    
    my $foo = Foo->new( 'goo' );
    print $foo->bar(); # goo

=cut

use Class::Method::Modifiers qw( install_modifier );
use Carp qw( croak );

use Moo::Role;
use namespace::clean;

with 'MooX::BuildArgsHooks';

around NORMALIZE_BUILDARGS => sub{
    my ($orig, $class, @args) = @_;

    @args = $class->NORMALIZE_SINGLE_ARG_BUILDARGS( @args );

    return $class->$orig( @args );
};

sub NORMALIZE_SINGLE_ARG_BUILDARGS {
    my ($class, @args) = @_;

    # Force force_single_arg to be set as we want it immutable
    # on this class once the first object has been instantiated.
    $class->force_single_arg( 0 ) if !defined $class->force_single_arg();

    croak "No single_arg was declared for the $class class" unless $class->has_single_arg();

    return( @args ) if @args!=1;

    return( @args ) unless ref($args[0]) ne 'HASH' or $class->force_single_arg();

    return( $class->single_arg() => $args[0] );
}

=head1 CLASS ARGUMENTS

=head2 single_arg

    __PACKAGE__->single_arg( 'foo' );

Use this to declare the C<init_arg> of the single argument.

=cut

sub single_arg {
    my ($class, $value) = @_;

    install_modifier(
        $class, 'around', 'single_arg' => sub{
            if (@_>2) { croak "single_arg has already been set to $value on $class" }
            return $value;
        },
    ) if defined $value;

    return $value;
}

=head2 force_single_arg

    __PACKAGE__->force_single_arg( 1 );

Causes single-argument processing to happen even if a hashref
is passed in as the single argument.

=cut

sub force_single_arg {
    my ($class, $value) = @_;

    install_modifier(
        $class, 'around', 'force_single_arg' => sub{
            if (@_>2) { croak "force_single_arg has already been set to $value on $class" }
            return $value;
        },
    ) if defined $value;

    return $value;
}

=head1 CLASS METHODS

=head2 has_single_arg

Returns true if L</single_arg> has been called.

=cut

sub has_single_arg {
    my $class = shift;
    return defined( $class->single_arg() ) ? 1 : 0;
}

1;
__END__

=head1 SEE ALSO

=over

=item *

L<MooX::BuildArgs>

=item *

L<MooX::BuildArgsHooks>

=item *

L<MooX::MethodProxyArgs>

=item *

L<MooX::Rebuild>

=back

=head1 AUTHORS AND LICENSE

See L<MooX::BuildArgs/AUTHORS> and L<MooX::BuildArgs/LICENSE>.

=cut

