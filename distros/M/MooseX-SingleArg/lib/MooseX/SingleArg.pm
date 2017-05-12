package MooseX::SingleArg;
{
  $MooseX::SingleArg::VERSION = '0.04';
}
use Moose ();
use Moose::Exporter;

=head1 NAME

MooseX::SingleArg - No-fuss instantiation of Moose objects using a single argument.

=head1 SYNOPSIS

    package Person;
    use Moose;
    
    use MooseX::SingleArg;
    
    single_arg 'name';
    
    has name => ( is=>'ro', isa=>'Str' );
    
    my $john = Person->new( 'John Doe' );
    print $john->name();

=head1 DESCRIPTION

This module allows Moose instances to be constructed with a single argument.
Your class or role must use this module and then use the single_arg method to
declare which attribute will be assigned the single argument value.

If the class is constructed using the typical argument list name/value pairs,
or with a hashref, then things work as is usual.  But, if the arguments are a
single non-hashref value then that argument will be assigned to whatever
attribute you have declared.

The reason for this module's existence is that when people want this feature
they usually find L<Moose::Cookbook::Basics::Recipe10> which asks that something
like the following be written:

    around BUILDARGS => sub{
        my $orig = shift;
        my $self = shift;
        
        if (@_==1 and ref($_[0]) ne 'HASH') {
            return $self->$orig( foo => $_[0] );
        }
        
        return $self->$orig( @_ );
    };

The above is complex boilerplate for a simple feature.  This module aims to make
it simple and fool-proof to support single-argument Moose object construction.

=head1 FORCING SINGLE ARG PROCESSING

An optional force parameter may be specified:

    single_arg name => (
        force => 1,
    );

This causes constructor argument processing to only work in single-argument mode.  If
more than one argument is passed then an error will be thrown.  The benefit of forcing
single argument processing is that hashrefs may now be used as the value of the single
argument when force is on.

=cut

use Carp qw( croak );

Moose::Exporter->setup_import_methods(
    with_meta => ['single_arg'],
    class_metaroles => {
        class => ['MooseX::SingleArg::Meta::Class'],
    },
    role_metaroles => {
        role                 => ['MooseX::SingleArg::Meta::Role'],
        application_to_class => ['MooseX::SingleArg::Meta::ToClass'],
        application_to_role  => ['MooseX::SingleArg::Meta::ToRole'],
    },
    base_class_roles => ['MooseX::SingleArg::Meta::Object'],
);

sub single_arg {
    my ($meta, $name, %args) = @_;

    my $class = $meta->name();
    croak "A single arg has already been declared for $class" if $meta->has_single_arg();

    $meta->single_arg( $name );

    foreach my $arg (keys %args) {
        my $method = $arg . '_single_arg';
        croak("Unknown single_arg argument $arg") if !$meta->can($method);
        $meta->$method( $args{$arg} );
    }

    return;
}

1;
__END__

=head1 SEE ALSO

L<MooseX::OneArgNew> solves the same problem that this module solves.  I considered using OneArgNew
for my own needs, but found it oddly combersom and confusing.  Maybe thats just me, but I hope that
this module's design is much simpler to comprehend and more natural to use.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

