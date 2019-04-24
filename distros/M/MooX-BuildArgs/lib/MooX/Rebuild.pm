package MooX::Rebuild;
our $VERSION = '0.08';

=encoding utf8

=head1 NAME

MooX::Rebuild - Rebuild your Moo objects.

=head1 SYNOPSIS

    package Foo;
    use Moo;
    with 'MooX::Rebuild';
    has get_bar => (
        is       => 'ro',
        init_arg => 'bar',
    );
    
    my $foo1 = Foo->new( bar => 'lala' );
    my $foo2 = $foo1->rebuild();
    print $foo2->get_bar(); # lala

=head1 DESCRIPTION

Make copies of Moo objects using the same arguments used to create
the original objects.

This Moo role depends on, and uses, the L<MooX::BuildArgs> role in
order to capture the original arguments used to create an object.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'MooX::BuildArgs';

=head1 METHODS

=head2 rebuild

    my $clone   = $object->rebuild();
    my $similar = $object->rebuild( %extra_args );

Creates a new instance in the same class as the source object and
using the same arguments used to make the source object.

=cut

sub rebuild {
    my $self = shift;
    my $class = ref( $self );

    my $args = $class->BUILDARGS( @_ );

    $args = {
        %{ $self->build_args() },
        %$args,
    };

    return $class->new( $args );
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

L<MooX::SingleArg>

=back

=head1 SUPPORT

See L<MooX::BuildArgs/SUPPORT>.

=head1 AUTHORS

See L<MooX::BuildArgs/AUTHORS>.

=head1 LICENSE

See L<MooX::BuildArgs/LICENSE>.

=cut

