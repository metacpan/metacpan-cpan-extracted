package Moonshine::Bootstrap::Component::FormGroup;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

use feature 'switch';
no if $] >= 5.017011, warnings => 'experimental::smartmatch';


extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::SubmitButton',
    'Moonshine::Bootstrap::Component::Input',
);

has(
    form_group_spec => sub {
        {
            tag     => { default => 'div' },
            class_base => { default => 'form-group' },
            fields  => {
                type    => ARRAYREF,
                build   => 1,
            }
        };
    }
);

sub form_group {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->form_group_spec,
        }
    );

    my $form_group = Moonshine::Element->new($base_args);

    for my $field ( @{ $build_args->{fields} } ) {
        given ( delete $field->{field_type} ) {
            when ( 'text' ) {
                $form_group->add_child( $self->input($field) );
            }
            when ( 'submit' ) {
                $form_group->add_child( $self->submit_button($field) );
            }
        }
    }

    return $form_group;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::FormGroup

=head1 SYNOPSIS

    $self->form_group({ class => 'search' });

returns a Moonshine::Element that renders too..

    <span class="form_group"></span>

=cut

