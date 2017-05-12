package Moonshine::Bootstrap::Component::Navbar;

use Moonshine::Magic;
use Moonshine::Util;
use Params::Validate qw/ARRAYREF SCALAR/;

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Nav',
    'Moonshine::Bootstrap::Component::NavbarHeader',
    'Moonshine::Bootstrap::Component::NavbarCollapse',
);

has(
    navbar_spec => sub {
        {
            tag         => { default => 'nav' },
            mid         => 0,
            class_base  => { default => 'navbar' },
            switch      => { default => 'default' },
            switch_base => { default => 'navbar-' },
            navs        => { type    => ARRAYREF },
            fixed       => { type    => SCALAR, optional => 1 },
            fixed_base  => { default => 'navbar-fixed-' },
            static      => { type    => SCALAR, optional => 1 },
            static_base => { default => 'navbar-static-' },
        };
    },
);

sub navbar {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_spec,
        }
    );

    for (qw/fixed static/) {
        if ( my $class =
            join_class( $build_args->{ $_ . '_base' }, $build_args->{$_} ) )
        {
            $base_args->{class} = prepend_str( $class, $base_args->{class} );
        }
    }

    my $base_element = Moonshine::Element->new($base_args);

    my $container = $base_element->add_child(
        Moonshine::Element->new( { tag => 'div', class => 'container-fluid' } )
    );

    for my $nav ( @{ $build_args->{navs} } ) {
        given ( delete $nav->{nav_type} ) {
            when ('header') {
                $nav->{mid} = $build_args->{mid} if $build_args->{mid};
                $container->add_child( $self->navbar_header($nav) );
            }
            when ('collapse') {
                $nav->{id} = $build_args->{mid} if $build_args->{mid};
                $container->add_child( $self->navbar_collapse($nav) );
            }
            when ('nav') {
                $container->add_child( $self->nav($nav) );
            }
            when ('button') {
                $container->add_child( $self->navbar_button($nav) );
            }
            when ('form') {
                $container->add_child( $self->navbar_form($nav) );
            }
            when ('text') {
                $container->add_child( $self->navbar_text($nav) );
            }
            when ('text_link') {
                $container->add_child( $self->navbar_text_link($nav) );
            }
        }
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Navbar

=head1 SYNOPSIS

    $self->navbar({ data => 'Hey' });

returns a Moonshine::Element that renders too..


    <nav class="navbar navbar-default">
          <div class="container-fluid">
            <div class="navbar-header">
               <a class="navbar-brand" href="#">
                   <img alt="Brand" src="...">
               </a>
            </div>
          </div>
    </nav>

=cut

