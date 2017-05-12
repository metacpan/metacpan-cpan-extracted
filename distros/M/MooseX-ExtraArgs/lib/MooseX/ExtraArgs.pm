package MooseX::ExtraArgs;
{
  $MooseX::ExtraArgs::VERSION = '0.01';
}
use Moose ();
use Moose::Exporter;

=head1 NAME

MooseX::ExtraArgs - Save constructor arguments that were not consumed.

=head1 SYNOPSIS

Create a class that uses this module:

    package MyClass;
    use Moose;
    use MooseX::ExtraArgs;
    has foo => ( is=>'ro', isa=>'Str' );
    
    my $object = MyClass->new( foo => 32, bar => 16 );
    print $object->extra_args->{bar};

=head1 DESCRIPTION

This module provides access to any constructor arguments that were not assigned to an
attribute.  Where L<MooseX::StrictConstructor> does not allow any unknown arguments, this
module expects unknown arguments and saves them for later access.

This could be useful for proxy classes that expect extra arguments that will then be
used to pass as arguments to the underlying implementation.

=cut

Moose::Exporter->setup_import_methods(
    role_metaroles => {
        application_to_class => ['MooseX::ExtraArgs::Meta::ToClass'],
        application_to_role  => ['MooseX::ExtraArgs::Meta::ToRole'],
    },
    base_class_roles => ['MooseX::ExtraArgs::Meta::Object'],
);

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

