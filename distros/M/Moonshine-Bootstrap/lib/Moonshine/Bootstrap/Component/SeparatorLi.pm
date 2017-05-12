package Moonshine::Bootstrap::Component::SeparatorLi;

use Moonshine::Magic;

extends 'Moonshine::Bootstrap::Component';

has(
    separator_li_spec => sub {
        {
            tag        => { default => 'li' },
            role       => { default => 'separator' },
            class_base => { default => 'divider' },
        };
    }
);

sub separator_li {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->separator_li_spec,
        }
    );

    return Moonshine::Element->new($base_args);
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::SeparatorLi

=head1 SYNOPSIS
	
	$self->separator_li;

=head3 options

=over

=item role

=back

=head3 Sample Output

    <li role="separator" class="divider"></li>

=cut
