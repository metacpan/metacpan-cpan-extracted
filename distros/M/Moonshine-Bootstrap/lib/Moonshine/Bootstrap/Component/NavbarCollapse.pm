package Moonshine::Bootstrap::Component::NavbarCollapse;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::NavbarNav',
    'Moonshine::Bootstrap::Component::NavbarButton',
    'Moonshine::Bootstrap::Component::NavbarForm',
    'Moonshine::Bootstrap::Component::NavbarText',
    'Moonshine::Bootstrap::Component::NavbarTextLink',
);

has(
    navbar_collapse_spec => sub {
        {
            tag        => { default => 'div' },
            id         => 1,
            class_base => { default => 'collapse navbar-collapse' },
            navs       => {
                type => ARRAYREF,
            }
        };
    }
);

sub navbar_collapse {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_collapse_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    for my $nav ( @{ $build_args->{navs} } ) {
        given ( delete $nav->{nav_type} ) {
            when ('nav') {
                $base_element->add_child( $self->navbar_nav($nav) );
            }
            when ('button') {
                $base_element->add_child( $self->navbar_button($nav) );
            }
            when ('form') {
                $base_element->add_child( $self->navbar_form($nav) );
            }
            when ('text') {
                $base_element->add_child( $self->navbar_text($nav) );
            }
            when ('text_link') {
                $base_element->add_child( $self->navbar_text_link($nav) );
            }
        }
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarCollapse

=head1 SYNOPSIS

    $self->navbar_collapse({ navs => [ ] });

returns a Moonshine::Element that renders too..

   <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
    
        ...
   
	 </nav> 
	
=cut

