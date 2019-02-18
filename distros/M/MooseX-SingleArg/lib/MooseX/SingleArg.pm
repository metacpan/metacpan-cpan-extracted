package MooseX::SingleArg;

$MooseX::SingleArg::VERSION = '0.09';

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
Your class or role must use this module and then use the single_arg sugar to
declare which attribute will be assigned the single argument value.

If the class is constructed using the typical argument list name/value pairs,
or with a hashref, then things work as is usual.  But, if the arguments are a
single non-hashref value then that argument will be assigned to whatever
attribute you have declared.

The reason for this module's existence is that when people want this feature
they usually find L<Moose::Cookbook::Basics::Person_BUILDARGSAndBUILD> which
asks that something like the following be written:

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        
        if ( @_ == 1 && ! ref $_[0] ) {
            return $class->$orig(ssn => $_[0]);
        }
        else {
            return $class->$orig(@_);
        }
    };

The above is complex boilerplate for a simple feature.  This module aims to make
it simple and fool-proof to support single-argument Moose object construction.

=head1 INIT_ARG BEHAVIOR

If setting a custom init_arg for an attribute which you will be assigning as the
single_arg then use the init_arg value, rather than the attribute key, for it.
For example:

    single_arg 'moniker';
    has name => ( is=>'ro', isa=>'Str', init_arg=>'moniker' );

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

use Moose ();
use Moose::Exporter;
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
for my own needs, but found it oddly cumbersome and confusing.  Maybe that's just me, but I hope that
this module's design is much simpler to comprehend and more natural to use.

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 CONTRIBUTORS

=over

=item *

Xavier Guimard <x.guimardE<64>free.fr>

=item *

Mohammad S Anwar <mohammad.anwarE<64>yahoo.com>

=back

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

