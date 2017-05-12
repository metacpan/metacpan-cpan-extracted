package Moonshine::Bootstrap::Component::LinkedLi;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    linked_li_spec => sub {
        {
            tag  => { default => 'li' },
            link => 1,
            data => { build   => 1 },
        };
    }
);

sub linked_li {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->linked_li_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    $base_element->add_child(
        {
            tag  => 'a',
            href => $build_args->{link},
            data => $build_args->{data},
        }
    );

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::LinkedLi

=head1 SYNOPSIS

=head2 linked_li
    
	$self->linked_li( link => 'http://some.url', data => 'Action' )

=head3 Options

=over

=item Disabled

    $self->linked_li( disabled => 1, ... )
    <li class="disabled"><a href="#">Disabled link</a></li>

=item link

    $self->linked_li( link => "#", ... )
    <a href="#">

=item data

    $self->linked_li( data => [1, 2, 3], ... )
    123

=back

=head3 Sample Output

    <li><a href="http://some.url">Action</a></li>

=cut

	
