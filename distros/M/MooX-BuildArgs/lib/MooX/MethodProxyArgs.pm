package MooX::MethodProxyArgs;
use 5.008001;
use strictures 2;
our $VERSION = '0.07';

=head1 NAME

MooX::MethodProxyArgs - Invoke code to populate static arguments.

=head1 SYNOPSIS

    package Foo;
    use Moo;
    with 'MooX::MethodProxyArgs';
    has bar => (
        is => 'ro',
    );
    
    package main;
    
    sub divide {
        my ($class, $number, $divisor) = @_;
        return $number / $divisor;
    }
    
    my $foo = Foo->new( bar => ['$proxy', 'main', 'divide', 10, 2 ] );
    
    print $foo->bar(); # 5

=head1 DESCRIPTION

This module munges the class's input arguments by replacing any
method proxy values found with the result of calling the methods.

This is done using L<Data::MethodProxy>.  See that module for more
information on how method proxies work.

=cut

use Data::MethodProxy;

use Moo::Role;
use namespace::clean;

with 'MooX::BuildArgsHooks';

my $mproxy = Data::MethodProxy->new();

around TRANSFORM_BUILDARGS => sub{
    my ($orig, $class, $args) = @_;

    $args = $class->TRANSFORM_METHOD_PROXY_ARGS_BUILDARGS( $args );

    return $class->$orig( $args );
};

sub TRANSFORM_METHOD_PROXY_ARGS_BUILDARGS {
    my ($class, $args) = @_;

    return $mproxy->render( $args );
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

L<MooX::Rebuild>

=item *

L<MooX::SingleArg>

=back

=head1 AUTHORS AND LICENSE

See L<MooX::BuildArgs/AUTHORS> and L<MooX::BuildArgs/LICENSE>.

=cut

