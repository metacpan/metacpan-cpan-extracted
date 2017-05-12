package Moonshine::Bootstrap::Component::NavItem;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

extends (
	'Moonshine::Bootstrap::Component',
	'Moonshine::Bootstrap::Component::LinkedLi',
	'Moonshine::Bootstrap::Component::DropdownUl',
);

has(
    nav_item_spec => sub {
        {
        	role     => { default => "presentation" },
            link     => { default => '#', base => 1 },
            disable  => { base => 1, optional => 1 },
            dropdown => { build => 1, type => HASHREF, optional => 1 } 
        };
    }
);

sub nav_item {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->nav_item_spec,
        }
    );

    my $li = $self->linked_li($base_args);

   	if ( my $dropdown = $build_args->{dropdown} ) {
        my $a = $li->children->[0];
        $a->set(
            {
                class         => 'dropdown-toggle',
                role          => 'button',
                aria_haspopup => 'true',
                aria_expanded => 'false',
                data_toggle   => 'dropdown'
            }
        );
        $li->add_child( $self->dropdown_ul($dropdown) );
    }

	return $li;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::NavItem

=head1 SYNOPSIS

    $self->nav_item;

=head3 options

=over

=item class

=item role 

=item link

=item active

=item data

=item disable

=item dropdown

=back

=head3 renders

    <li role="presentation" class="active"><a href="#">Home</a></li>

=cut

