package Moonshine::Bootstrap::Component::Dropdown;

use Moonshine::Magic;
use Params::Validate qw/HASHREF SCALAR/;
use Moonshine::Util;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::DropdownButton',
    'Moonshine::Bootstrap::Component::DropdownUl',
);

has(
    dropdown_spec => sub {
        {
            tag    => { default => 'div' },
            dropup => 0,
            button => { type    => HASHREF },
            ul     => { type    => HASHREF },
            mid    => { type    => SCALAR },
        };
    }
);

sub dropdown {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->dropdown_spec,
        }
    );

    my $drop_class = $build_args->{dropup} ? 'dropup' : 'dropdown';
    $base_args->{class} = append_str( $drop_class, $base_args->{class} );

    my $base_element = Moonshine::Element->new($base_args);

    $base_element->add_child(
        $self->dropdown_button(
            { %{ $build_args->{button} }, id => $build_args->{mid} }
        )
    );

    $base_element->add_child(
        $self->dropdown_ul(
            {
                %{ $build_args->{ul} }, aria_labelledby => $build_args->{mid}
            }
        )
    );

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Dropdown

=head1 SYNOPSIS
    
    $self->dropdown({
        mid => 'somethingUnique',
        button => {},
        ul => {},
        dropup => 1,
    });

=head3 options

=over

=item mid

Id that is used to link the button and hidden list

=item button

Used to create the button, check dropdown_button for options.

=item ul

Hidden list, that will be shown on click, check dropdown_ul for options.

=item dropup

Change position of dropdown menu via base_element div class - dropdown, dropup, 

=back

=head3 Sample Output

    <div class="dropdown">
      <button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
        Dropdown
        <span class="caret"></span>
      </button>
      <ul class="dropdown-menu" aria-labelledby="dropdownMenu1">
        <li><a href="#">Action</a></li>
        <li><a href="#">Another action</a></li>
        <li><a href="#">Something else here</a></li>
        <li role="separator" class="divider"></li>
        <li><a href="#">Separated link</a></li>
      </ul>
    </div>

=cut


