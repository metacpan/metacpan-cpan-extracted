package Moonshine::Bootstrap::Component::NavbarHeader;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;
use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::LinkImage',
    'Moonshine::Bootstrap::Component::NavbarToggle',
    'Moonshine::Bootstrap::Component::NavbarBrand',
);

has(
    navbar_header_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'navbar-header' },
            headers    => {
                type  => ARRAYREF,
                build => 1,
            },
            mid => 0,
        };
    }
);

sub navbar_header {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_header_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for my $header ( @{ $build_args->{headers} } ) {
        given ( delete $header->{header_type} ) {
            when ('link_image') {
                $header->{class} = 'navbar-brand';
                $base_element->add_child( $self->link_image($header) );
            }
            when ('toggle') {
                $header->{data_target} = $build_args->{mid};
                $base_element->add_child( $self->navbar_toggle($header) );
            }
            when ('brand') {
                $base_element->add_child( $self->navbar_brand($header) );
            }
        }
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarHeader

=head1 SYNOPSIS

    $self->navbar_header({ class => 'search' });

returns a Moonshine::Element that renders too..

   <div class="navbar-header">
      <a class="navbar-brand" href="#">
        <img alt="Brand" src="...">
      </a>
    </div> 

=cut

