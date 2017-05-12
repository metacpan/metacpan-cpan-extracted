package MooseX::CoercePerAttribute;

use strict;
use 5.008_005;

our $VERSION = '1.001';

use Moose::Role;
use Moose::Util::TypeConstraints;
Moose::Util::meta_attribute_alias('CoercePerAttribute');

before _process_coerce_option => sub {
    my ($class, $name, $options) = @_;

    my $coercion = $options->{coerce};
    return unless $coercion && $coercion != 1;

    # Create an anonymous subtype of the TC object so as to not mess with the existing TC
    my $anon_subtype = $options->{type_constraint} = Moose::Meta::TypeConstraint->new(
        parent => $options->{type_constraint},
    );

    $class->throw_error(
        "Couldn't build coercion from supplyed arguments for ($name)",
        data => $coercion,
    ) unless ((ref $coercion) =~ /ARRAY|HASH/) && $anon_subtype;

    my @coercions;

    # NOTE: Depricated behavior. Just set it to the approved usage.
    # TODO: Remove in version 1.000
    if (ref $coercion eq 'HASH'){
        warn "The use of a HashRef for declaration of inline coercions is depricated. See perldoc MooseX::CoercePerAttribute. This feature will be removed in version 1.100 of MooseX::CoercePerAttribute";
        $coercion = [ 
            map { $_ => $coercion->{$_} } keys %$coercion,
        ];
    }

    if (ref $coercion eq 'ARRAY') {
        while (scalar @$coercion) {
            my $coerce_type = shift @$coercion;

            # The user can supply the coercion in its full form...
            if (ref $coerce_type eq 'CODE'){
                push @coercions, $coerce_type;
            }

            # Or they can give us the pieces to make the coercion from.
            if (!ref $coerce_type){
                my $via = shift @$coercion;

                # Create the coercion sub ref from the list of Type => via pairs.
                push @coercions, sub {
                    &coerce(shift, &from($coerce_type, &via($via)) )
                };
            }
        }
    }

    # Create each coercion object from a anonymous subtype
    for my $coercion (@coercions){
        $coercion->($anon_subtype) if ref $coercion eq 'CODE';
    }

    $class->throw_error(
        "Coerce for ($name) doesn't set a coercion for ($anon_subtype), see man MooseX::CoercePerAttribute for usage",
        data => $coercion
    ) unless $anon_subtype->has_coercion;
};

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::CoercePerAttribute - Define Coercions per attribute!

=head1 SYNOPSIS

    use MooseX::CoercePerAttribute;

    has foo => (isa => 'Str', is => 'ro', coerce => 1);
    has bar => (
        traits  => [CoercePerAttribute],
        isa     => Bar,
        is      => 'ro',
        coerce  => [
            Str => sub {
                my ($value, $options);
                ...
            },
            Int => sub {
                my ($value, $options);
                ...
            },
        ],
    );

    use Moose::Util::Types;

    has baz => (
        traits  => [CoercePerAttribute],
        isa     => Baz,
        is      => 'ro',
        coerce  => [
            sub {
                coerce $_[0], from Str, via {}
                }]
        );


=head1 DESCRIPTION

MooseX::CoercePerAttribute is a simple Moose Trait to allow you to define inline coercions per attribute.

This module allows for coercions to be declared on a per attribute bases. Accepting either an array of  Code refs of the coercion to be run or an HashRef of various arguments to create a coercion routine from.

=head1 USAGE

This trait allows you to declare a type coercion inline for an attribute. The Role will create an __ANON__ sub TypeConstraint object of the TypeConstraint in the attributes isa parameter. The type coercion can be supplied in one of two methods. The coercion should be supplied to the Moose Attribute coerce parameter.

1. The recomended usage is to supply a arrayref list declaring the types to coerce from and a subref to be executed in pairs.
    coerce => [$Fromtype1 => sub {}, $Fromtype2 => sub {}]

2. Alternatively you can supply and arrayref of coercion coderefs. These should be in the same format as defined in L<Moose::Util::TypeConstraints> and will be passed the __ANON__ subtype as its first argument. If you use this method then you will need to use Moose::Util::TypeConstraints in you module.
    coerce => [sub {coerce $_[0], from Str, via sub {} }]

NB: Moose handles its coercions as an array of possible coercions. This means that it will use the first coercion in the list that matches the criteria. In earlier versions of this module the coercions were supplied as a HASHREF. This behaviour is deprecated and will be removed in later versions as it creates an uncertainty over the order of usage.

=head1 AUTHOR

Mike Francis E<lt>ungrim97@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Mike Francis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::CoercePerAttribute


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-CoercePerAttribute>

=item * Meta CPAN

L<https://metacpan.org/module/MooseX::CoercePerAttribute>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-CoercePerAttribute/>

=back


=cut
