package MooseX::Blessed::Reconstruct;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: A L<Data::Visitor> for creating Moose objects from blessed placeholders
$MooseX::Blessed::Reconstruct::VERSION = '1.01';
use Moose 1.05;

use Carp qw(croak);

use Class::MOP 0.93;
use Module::Runtime;
use Data::Visitor 0.21; # n-arity visit

use Scalar::Util qw(reftype);

use namespace::clean -except => 'meta';

extends qw(Data::Visitor);

has load_classes => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

before visit_object => sub {
    my ( $v, $obj ) = @_;

    return unless $v->load_classes;

    Module::Runtime::use_package_optimistically(ref $obj);
};

sub visit_object {
	my ( $v, $obj ) = @_;

	my $meta = Class::MOP::get_metaclass_by_name(ref $obj);

    return ref $meta ? $v->visit_object_with_meta($obj, $meta)
                     : $v->visit_ref($obj);
}

sub visit_object_with_meta {
	my ( $v, $obj, $meta ) = @_;

	my $instance = $meta->get_meta_instance->create_instance;

	$v->_register_mapping( $obj => $instance );

	my $args = $v->prepare_args( $meta, $obj );

	$meta->new_object( %$args, __INSTANCE__ => $instance );

	return $instance;
}

my %refmap = (
    HASH   => sub { %{ $_[0] } },
    ARRAY  => sub { @{ $_[0] } },
    SCALAR => sub { ${ $_[0] } },
);

sub prepare_args {
	my ( $v, $meta, $obj ) = @_;

    my $f = $refmap{ reftype $obj } or croak "unknown ref type $obj";

    return $meta->name->BUILDARGS($v->visit($f->($obj)));
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Blessed::Reconstruct - A L<Data::Visitor> for creating Moose objects from blessed placeholders

=head1 VERSION

version 1.01

=head1 SYNOPSIS

	use MooseX::Blessed::Reconstruct;


	my $obj = bless( {
		init_arg_foo => "Blah",
		arf => "yay",
	}, "Foo" );

	my $proper = MooseX::Blessed::Reconstruct->new->visit($obj);


	# equivalent to:

	my $proper = Foo->meta->new_object(%$obj);

	# but recursive (and works with shared references)

=head1 DESCRIPTION

The purpose of this module is to "fix up" blessed data into a real Moose
object.

=head1 METHODS

See L<Data::Visitor>

=head2 new 

Constructor. 

=head3 arguments

=over

=item load_classes 

If C<true> (which is the default), we will try to require its class 
when the target object is C<visit>ed. 

=back

=head2 load_classes 

Read/write accessor to the C<load_classes> attribute.
If C<true>, we try to require its class when a target object is C<visit>ed. 

=head2 visit_object $object

Calls L<Class::MOP/load_class> on the C<ref> of $object.

If there's a metaclass, calls C<visit_object_with_meta>, otherwise C<visit_ref>
is used to walk the object brutishly.

Returns a deep clone of the input structure with all the L<Moose> objects
reconstructed "properly".

=head2 visit_object_with_meta $obj, $meta

Uses the metaclass C<$meta> to create a new instance, registers the instance
with L<Data::Visitor>'s cycle tracking, and then inflates it using
L<Moose::Meta::Class/new_object>.

=head2 prepare_args $obj

Collapses $obj into key value pairs to be used as init args to
L<Moose::Meta::Class/new_object>.

=head1 AUTHORS

=over 4

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Jonathan Rockway <jrockway@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2014 by Infinity Interactive, Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
