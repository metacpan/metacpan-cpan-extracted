package MooseX::Clone::Meta::Attribute::Trait::NoClone;
# ABSTRACT: A trait for attributes that should not be copied while cloning

our $VERSION = '0.06';

use Moose::Role;
use namespace::autoclean;

with qw(MooseX::Clone::Meta::Attribute::Trait::Clone::Base);

sub Moose::Meta::Attribute::Custom::Trait::NoClone::register_implementation { __PACKAGE__ }

sub clone_value {
    my ( $self, $target, $proto, %args ) = @_;

    # FIXME default cloning behavior works like this
    #if ( exists $args{init_arg} ) {
    #   $self->set_value($args{init_arg});
    #} else {
    # but i think this is more correct

    $self->clear_value($target);
    $self->initialize_instance_slot(
        $self->meta->get_meta_instance,
        $target,
        { exists $args{init_arg} ? ( $self->init_arg => $args{init_arg} ) : () },
    );
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Clone::Meta::Attribute::Trait::NoClone - A trait for attributes that should not be copied while cloning

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    with qw(MooseX::Clone);

    has _some_special_thingy => (
        traits => [qw(NoClone)],
    );

=head1 DESCRIPTION

Sometimes certain values should not be carried over when cloning an object.

This attribute trait implements just that.

=head1 METHODS

=over 4

=item clone_value

If the C<init_arg> param is set (that means an explicit value was given to
C<clone>) sets the attribute to that value.

Otherwise calls C<clear_value> and C<initialize_instance_slot>.

=back

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
