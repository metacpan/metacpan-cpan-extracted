package Moonshine::Bootstrap::Component::Breadcrumb;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

lazy_components qw/li/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::LinkedLi',
);

has(
    breadcrumb_spec => sub {
        {
            tag        => { default => 'ol' },
            class_base => { default => 'breadcrumb' },
            crumbs     => { type => ARRAYREF },
        };
    }
);

sub breadcrumb {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->breadcrumb_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for ( @{ $build_args->{crumbs} } ) {
        if ( $_->{active} ) {
            $base_element->add_child( $self->li($_) );
        }
        else {
            $base_element->add_child( $self->linked_li($_) );
        }
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Breadcrumb

=head1 SYNOPSIS

    $self->breadcrumb({ crumbs => [] });

returns a Moonshine::Element that renders too..

    <ol class="breadcrumb">
        <li><a href="#">Home</a></li>
        <li><a href="#">Library</a></li>
        <li class="active">Data</li>
    </ol>

=cut

