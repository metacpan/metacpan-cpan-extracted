package MooseX::ExpiredAttribute::Role::Meta::Attribute;

use Moose::Role;
use Moose::Util ();
use Time::HiRes ();
use MooseX::ExpiredAttribute::Role::Object ();

Moose::Util::meta_attribute_alias('Expired');

has 'expires'   => (
    is          => 'rw',
    isa         => 'Num',
);

after install_accessors => sub {
    my $self = shift;

    confess "The expired attribute '" . $self->name . "' should have builder or default coderef"
      unless $self->has_builder || $self->is_default_a_coderef;

    my $class_meta = $self->associated_class;
    my $orig_name  = $self->get_read_method;
    my $orig_meth  = $self->get_read_method_ref;

    Moose::Util::apply_all_roles( $class_meta->name, 'MooseX::ExpiredAttribute::Role::Object' )
      unless ( $class_meta->does_role( 'MooseX::ExpiredAttribute::Role::Object' ) );

    $class_meta->add_before_method_modifier( $orig_name, sub { _before_expired_accessor( $self, $orig_name, @_ ) } );
};

sub _before_expired_accessor {
    my ( $attr, $name, $self ) = @_;

    if ( ! exists $self->_expiration_time_for_attrs->{ $attr->name } || @_ == 4 ) {
        # If it's first time calling or it's writer - we set expired time in future
        $self->_expiration_time_for_attrs->{ $attr->name } = Time::HiRes::time() + $attr->expires;
    }
    elsif ( Time::HiRes::time() >= $self->_expiration_time_for_attrs->{ $attr->name } ) {
        # If value has expired we clear value = after 'before' modifiers Moose will call builder/default again
        $attr->clear_value( $self );
        $self->_expiration_time_for_attrs->{ $attr->name } = Time::HiRes::time() + $attr->expires;
    }
}

no Moose::Role;

1;
__END__

=pod

=head1 NAME

MooseX::ExpiredAttribute::Role::Meta::Attribute - the attached role to meta attribute objects (a trait)

This trait has alias as C<Expired>

=head1 DESCRIPTION

This role should be attached as I<trait> to attributes which should be have I<expired> capability.

=head1 EXAMPLE

    use MooseX::ExpiredAttribute;

    has 'config' => (
        traits   => [ qw( Expired ) ],
        is       => 'rw',
        isa      => 'HashRef',
        expires  => 5.5,
        lazy     => 1,
        builder  => '_build_config',
    );

Please read L<MooseX::ExpiredAttribute/SYNOPSIS> for more examples and how to use.

=head1 SEE ALSO

=over

=item L<MooseX::ExpiredAttribute>

=item L<MooseX::ExpiredAttribute::Role::Object>

=back

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.

=cut
