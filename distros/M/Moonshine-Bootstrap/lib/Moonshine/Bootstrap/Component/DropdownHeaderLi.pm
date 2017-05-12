package Moonshine::Bootstrap::Component::DropdownHeaderLi;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    dropdown_header_li_spec => sub {
        {
            tag        => { default => 'li' },
            class_base => { default => 'dropdown-header' },
        };
    }
);

sub dropdown_header_li {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->dropdown_header_li_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::DropdownHeaderLi

=head1 SYNOPSIS

=head2 dropdown_header_li

    $self->dropdown_header_li( data => 'Dropdown header' );

=head3 Options

=over

=item class

=item data

=back

=head3 Sample Output

    <li class="dropdown-header">Dropdown header</li>

=cut	
