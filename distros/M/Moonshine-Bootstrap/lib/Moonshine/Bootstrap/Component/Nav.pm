package Moonshine::Bootstrap::Component::Nav;

use Moonshine::Magic;
use Moonshine::Util;
use Params::Validate qw/ARRAYREF/;

extends (
	'Moonshine::Bootstrap::Component',
	'Moonshine::Bootstrap::Component::NavItem',
);

has(
    nav_spec => sub {
        {
            tag => { default => 'ul' },
            class_base  => { default => 'nav' },
            switch_base => { default => 'nav-' },
            stacked => 0,
            justified_base => { default => 'nav-justified' },
            nav_items => { type => ARRAYREF, default => [ ] },
        };
    }
);

sub nav {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->nav_spec,
        }
    );

    if ( $build_args->{stacked} ) {
        $base_args->{class} = prepend_str('nav-stacked', $base_args->{class});
    }

    my $base_element = Moonshine::Element->new($base_args);

    for ( @{ $build_args->{nav_items} } ) {
        $base_element->add_child( 
            $self->nav_item($_)
        );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::Nav

=head1 SYNOPSIS
	
	$self->nav();

=head3 options

=over

=item class

=item switch

tabs or pills

=item nav_items

=item stacked

Pills are also vertically stackable. Just add 
    
    stacked => 1

=item justified

"Easily make tabs or pills equal widths of their parent at screen wider than 768pm". On smaller screens,
nav links become stacked.

    justified => 1

=back

=head3 renders

    <ul class="nav nav-tabs">
        <li role="presentation" class="active"><a href="#">Home</a></li>
        <li role="presentation"><a href="#">Profile</a></li>
        <li role="presentation"><a href="#">Messages</a></li>
    </ul>
=cut
