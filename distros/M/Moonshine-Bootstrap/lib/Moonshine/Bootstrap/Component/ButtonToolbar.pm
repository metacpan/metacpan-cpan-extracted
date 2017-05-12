package Moonshine::Bootstrap::Component::ButtonToolbar;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::ButtonGroup',
);

has(
    button_toolbar_spec => sub {
        {
            tag        => { default => 'div' },
            role       => { default => 'toolbar' },
            class_base => { default => 'btn-toolbar' },
            toolbar    => {
                type => ARRAYREF,
            },
        };
    }
);

sub button_toolbar {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->button_toolbar_spec,
        }
    );

    my $button_toolbar = Moonshine::Element->new($base_args);

    for ( @{ $build_args->{toolbar} } ) {
        $button_toolbar->add_child( $self->button_group($_) );
    }

    return $button_toolbar;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ButtonToolbar

=head1 SYNOPSIS

    $self->button_toolbar(
        toolbar => [ 
            { 
                group => [ 
                    {
                       data => 'one',
                    }
                ] 
            }, 
            {
                group => [
                    {
                        data => 'two',
                    }
                ]
            }
        ]
    );

=head3 Options

=over

=item role

=item class

=item toolbar

=back

=head3 Sample Output
    
    <div class="btn-toolbar" role="toolbar">
        <div class="btn-group" role="group">
              <button type="button" class="btn btn-default">one</button>
        </div> 
        <div class="btn-group" role="group">
              <button type="button" class="btn btn-default">one</button>
        </div>
    </div>

=cut

