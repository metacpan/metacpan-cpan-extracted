package MooseX::BuildArgs;

$MooseX::BuildArgs::VERSION = '0.07';

=head1 NAME

MooseX::BuildArgs - Save the original constructor arguments for later use.

=head1 SYNOPSIS

Create a class that uses this module:

    package MyClass;
    use Moose;
    use MooseX::BuildArgs;
    has foo => ( is=>'ro', isa=>'Str' );
    
    my $object = MyClass->new( foo => 32 );
    print $object->build_args->{foo};

=head1 DESCRIPTION

Sometimes it is very useful to have access to the contructor arguments before builders,
defaults, and coercion take affect.  This module provides a build_args hashref attribute
for all instances of the consuming class.  The build_args attribute contains all arguments
that were passed to the constructor.

A contrived case for this module would be for creating a clone of an object, so you could
duplicate an object with the following code:

    my $obj1 = MyClass->new( foo => 32 );
    my $obj2 = MyClass->new( $obj1->build_args() );
    print $obj2->foo();

=cut

use Moose ();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    role_metaroles => {
        application_to_class => ['MooseX::BuildArgs::Meta::ToClass'],
        application_to_role  => ['MooseX::BuildArgs::Meta::ToRole'],
    },
    base_class_roles => ['MooseX::BuildArgs::Meta::Object'],
);

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

