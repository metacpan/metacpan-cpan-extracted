package Moonshine::Bootstrap::Component::ButtonGroup;

use Moonshine::Magic;
use Moonshine::Util;
use Params::Validate qw/ARRAYREF/;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::Button',
    'Moonshine::Bootstrap::Component::Dropdown',
);

has(
    button_group_spec => sub {
        {
            tag            => { default => 'div' },
            role           => { default => 'group' },
            class_base     => { default => 'btn-group' },
            sizing_base    => { default => 'btn-group-' },
            vertical       => 0,
            justified_base => { default => 'btn-group-justified' },
            nested         => {
                type     => ARRAYREF,
                optional => 1,
            },
            group => {
                type => ARRAYREF,
            }
        };
    }
);

sub button_group {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->button_group_spec,
        }
    );

    if ( $vertical = $build_args->{vertical} ) {
        $base_args->{class} =
          prepend_str( 'btn-group-vertical', $base_args->{class} );
    }

    my $button_group = Moonshine::Element->new($base_args);

    my %drop_down_args = ( class => 'btn-group', role => 'group' );
    for ( @{ $build_args->{group} } ) {
        if ( exists $_->{group} ) {
            $button_group->add_child( $self->button_group($_) );
        }
        elsif ( delete $_->{dropdown} ) {
            $button_group->add_child(
                $self->dropdown( { %{$_}, %drop_down_args } ) );
        }
        else {
            $button_group->add_child( $self->button($_) );
        }
    }

    for ( @{ $build_args->{nested} } ) {
        my $index = delete $_->{index};
        my $nested_button_group =
          delete $_->{dropdown}
          ? $self->dropdown( { %{$_}, %drop_down_args } )
          : $self->button_group($_);

        if ($index) {
            splice @{ $button_group->{children} }, $index - 1, 0,
              $nested_button_group;
        }
        else {
            push @{ $button_group->{children} }, $nested_button_group;
        }
    }

    return $button_group;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::ButtonGroup

=head1 SYNOPSIS

    $self->button_group(group => [{ }, { }, { }]);

=head3 Options

=over

=item group

Array of Hashes - each hash get sent to **button**
unless dropdown => 1 is set, then the args gets sent to dropdown.

=item sizing 

SCALAR that appends btn-group-%s - lg, sm, xs

=item nested

ArrayRef of Hashes, that can build nested button_groups

    nested => [ 
        {
             index => 3,
            dropdown => 1,
        },
        ...
    ],
   <div class="btn-group" role="group">
    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
      Dropdown
      <span class="caret"></span>
    </button>
    <ul class="dropdown-menu">
      <li><a href="#">Dropdown link</a></li>
      <li><a href="#">Dropdown link</a></li>
    </ul>
  </div>

=item vertical

Make a set of buttons appear vertically stacked rather than horizontally.

    vertical => 1
    <div class="btn-group btn-group-vertical" ...>
        ...
    </div>

=item justified

Make a group of buttons stretch at equal sizes to span the entire width of its parent.

    justified => 1
    <div class="btn-group btn-group-justified" ...>
         ...
    </div>

=back

=head3 Sample Output

    <div class="btn-group" role="group" aria-label="...">
          <button type="button" class="btn btn-default">Left</button>
          <button type="button" class="btn btn-default">Middle</button>
          <button type="button" class="btn btn-default">Right</button>
    </div>

=cut

