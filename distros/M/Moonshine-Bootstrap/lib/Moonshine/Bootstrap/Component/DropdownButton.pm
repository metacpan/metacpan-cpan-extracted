package Moonshine::Bootstrap::Component::DropdownButton;

use Moonshine::Magic;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Caret',
    'Moonshine::Bootstrap::Component::Button'
);

has(
    dropdown_button_spec => sub {
        {
            switch     => { default => 'default', base => 1 },
            class_base => { default => 'dropdown-toggle' },
            id         => 1,
            split      => 0,
            data_toggle   => { default => 'dropdown' },
            aria_haspopup => { default => 'true' },
            aria_expanded => { default => 'true' },
            data          => 1,
        };
    }
);

sub dropdown_button {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->dropdown_button_spec,
        }
    );

    $build_args->{data} = delete $base_args->{data}
      if $build_args->{split};

    my $button = $self->button($base_args);

    $button->add_before_element(
        $self->button(
            { data => $build_args->{data}, class => $base_args->{class} }
        )
    ) if $build_args->{split};

    $button->add_child( $self->caret );
    return $button;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::DropdownButton

=head1 SYNOPSIS

    $self->dropdown_button({ class => "..." });

=head3 Options

=over

=item class 

defaults to 'default',

=item id

dropdown_button **requires** an Id

=item data_toggle

defaults to dropdown

=item aria_haspopup

defaults to true

=item aria_expanded 

defaults to true

=item data

is **required**

=item split

Create split dropdown button

    $self->dropdown_button({ split => 1 });

     <button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
        Dropdown
        <span class="caret"></span>
    </button> 

=back

=head3 Sample Output

    <button class="btn btn-default">Dropdown</button>
    <button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
        <span class="caret"></span>
    </button> 

=cut
