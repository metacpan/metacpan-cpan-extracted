package Moonshine::Bootstrap::Component::NavbarForm;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

lazy_components qw/form/;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::SubmitButton',
    'Moonshine::Bootstrap::Component::FormGroup',
);

has(
    navbar_form_spec => sub {
        {
               alignment_base => { default => 'navbar-' },
            class_base     => { default => 'navbar-form' },
            role           => 0,
            fields         => {
                type  => ARRAYREF,
                build => 1,
            } 
        };
    }
);

sub navbar_form {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->navbar_form_spec,
        }
    );

    my $form = $self->form($base_args);

    for my $field ( @{ $build_args->{fields} } ) {
        given ( delete $field->{field_type} ) {
            when ('submit_button') {
                $form->add_child( $self->submit_button( $field ) );
            }
            when ('form_group') {
                $form->add_child( $self->form_group($field) );
            }
        }
    }

    return $form
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavbarForm

=head1 SYNOPSIS

    $self->navbar_form({ ... });

returns a Moonshine::Element that renders too..

    <form class="navbar-form navbar-left" role="search">
        <div class="form-group">
            <input type="text" class="form-control" placeholder="Search">
        </div>
        <button type="submit" class="btn btn-default">Submit</button>
    </form>

=cut

