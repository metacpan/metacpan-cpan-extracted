package Moonshine::Bootstrap::Component::DropdownUl;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;

extends(
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::Component::LinkedLi',
    'Moonshine::Bootstrap::Component::SeparatorLi',
    'Moonshine::Bootstrap::Component::DropdownHeaderLi',
);

has(
    dropdown_ul_spec => sub {
        {
            tag            => { default => 'ul' },
            class_base     => { default => 'dropdown-menu' },
            alignment_base => { default => 'dropdown-menu-' },
            separators     => { type    => ARRAYREF, optional => 1 },
            headers        => { type    => ARRAYREF, optional => 1 },
        };
    }
);

sub dropdown_ul {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->dropdown_ul_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    if ( $build_args->{headers} ) {
        for ( @{ $build_args->{headers} } ) {
            my $index = delete $_->{index} or die "No index";
            splice @{ $base_element->{children} }, $index - 1, 0,
              $self->dropdown_header_li($_);
        }
    }

    if ( $build_args->{separators} ) {
        my $separator = $self->separator_li;
        for ( @{ $build_args->{separators} } ) {
            splice @{ $base_element->{children} }, $_ - 1, 0, $separator;
        }
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::DropdownUl

=head1 SYNOPSIS
    
=head2 dropdown_ul 
 
   $self->dropdown_ul(
        class => 'extra-css',
        alignment => 'right',
        separators => [4],
        headers => [
            {
                index => 4,
                data => 'Title',
            }
        ]
        items => [
            {
                heading => 1,
                data => 'Title',
            }
            {
                link => '#',
                data => 'Action',
            },
            {
                link => '#',
                data => 'Another',
            },
            {
                link => '#',
                data => 'Something else here',
            },
            {
                separator => 1
            },
            {
                link => '#',
                data => 'Separated link',
            }
        ],
    );

=head3 Options

=over

=item class 

defaults to dropdown-menu

=item aira_lebelledby

Required

=item children

Arrayref that gets used to build linked_li's 

=item Separators 

Add a divider to separate series of links in a dropdown menu

    <ul class="dropdown-menu" aria-labelledby="dropdownMenuDivider">
      ...
      <li role="separator" class="divider"></li>
      ...
    </ul> 
 
=item alignment

Change alignment of dropdown menu 
    
    <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dLabel">
        ...
    </ul>
 
=back

=head3 Sample Output

    <ul class="dropdown-menu" aria-labelledby="dropdownMenu1">
        <li><a href="#">Action</a></li>
        <li><a href="#">Another action</a></li>
        <li><a href="#">Something else here</a></li>
        <li role="separator" class="divider"></li>
        <li><a href="#">Separated link</a></li>
    </ul>

=cut
