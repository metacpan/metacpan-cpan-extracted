package MooX::MethodProxyArgs;

$MooX::MethodProxyArgs::VERSION = '0.06';

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
use strictures 2;
use namespace::clean;

with 'MooX::BuildArgsHooks';

my $mproxy = Data::MethodProxy->new();

around TRANSFORM_BUILDARGS => sub{
    my ($orig, $class, $args) = @_;

    return $class->$orig(
        $mproxy->render( $args ),
    );
};

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

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 CONTRIBUTORS

=over

=item *

Peter Pentchev <roamE<64>ringlet.net>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

