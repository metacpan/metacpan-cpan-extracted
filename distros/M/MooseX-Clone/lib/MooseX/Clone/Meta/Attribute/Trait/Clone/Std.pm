package MooseX::Clone::Meta::Attribute::Trait::Clone::Std;

our $VERSION = '0.06';

use Moose::Role;
use namespace::autoclean;

with qw(MooseX::Clone::Meta::Attribute::Trait::Clone::Base);

requires qw(clone_value_data);

sub clone_value {
    my ( $self, $target, $proto, %args ) = @_;

    if ( exists $args{init_arg} ) {
        $self->set_value( $target, $args{init_arg} );
    } else {
        return unless $self->has_value($proto);

        my $clone = $self->clone_value_data( scalar($self->get_value($proto)), %args );

        $self->set_value( $target, $clone );
    }
}

__PACKAGE__

__END__
