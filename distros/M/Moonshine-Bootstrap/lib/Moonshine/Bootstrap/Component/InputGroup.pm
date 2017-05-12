package Moonshine::Bootstrap::Component::InputGroup;

use Moonshine::Magic;
use Moonshine::Util;
use Params::Validate qw/HASHREF/;

lazy_components('label');

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::InputGroupAddon'
);

has(
    input_group_spec => sub {
        {
            tag            => { default => 'div' },
            mid            => 1,
            lid            => 0,
            sizing_base    => { default => 'input-group-' },
            class_base     => { default => 'input-group' },
            label          => { type => HASHREF, optional => 1, build => 1 },
            left           => { type => HASHREF, optional => 1 },
            right          => { type => HASHREF, optional => 1 },
            input            => { type => HASHREF, default => { } },
        };
    }
);

sub input_group {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->input_group_spec,
        }
    );

    my $input_group = Moonshine::Element->new($base_args);

    if ( $build_args->{label} ) {
        $label = $input_group->add_before_element(
            $self->label( $build_args->{label} )
        );
    }
    
    if ( $build_args->{left} ) {
        $build_args->{left}->{id} = $build_args->{mid};
        $input_group->add_child(
            $self->input_group_addon( $build_args->{left} )
        );
    }

    if ( my $lid = $build_args->{lid} ) {
        $build_args->{input}->{id} = $lid;
        $label->for($lid);
    }

    $build_args->{input}->{aria_describedby} = $build_args->{mid};
    $input_group->add_child( $self->input( $build_args->{input} ) );

    if ( $build_args->{right} ) {
        $build_args->{right}->{id} = $build_args->{mid};
        $input_group->add_child(
            $self->input_group_addon( $build_args->{right} )
        );
    }

    return $input_group;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::InputGroup

=head1 SYNOPSIS

   $self->input_group({
        mid => 'basic-addon1',
        placeholder => 'Username',
        left => {
            data => '@'
        }
    });

=head3 options

=over

=item label

    $self->input_group({ label => { data => 'some text' } });
    <label>some text .... </label

=item mid

Used to map addon and input.

=item lid

Used to map label to input.

    <label for="lid">
    <input id="lid">

=item placeholder

=item left

=item right

=item sizing

=back

=head3 Sample Output

    <div class="input-group">
        <span class="input-group-addon" id="basic-addon1">@</span>
        <input type="text" class="form-control" placeholder="Username" aria-describedby="basic-addon1">
    </div>

=cut


