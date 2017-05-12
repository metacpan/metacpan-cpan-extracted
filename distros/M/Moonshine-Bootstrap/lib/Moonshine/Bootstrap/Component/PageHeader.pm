package Moonshine::Bootstrap::Component::PageHeader;

use Moonshine::Magic;
use Params::Validate qw/HASHREF/;

lazy_components qw/h1 small div/;

extends 'Moonshine::Bootstrap::Component';

has(
    page_header_spec => sub {
        {
            tag        => { default => 'div' },
            class_base => { default => 'page-header' },
            header_tag => { default => 'h1' },
            header     => { type => HASHREF },
            small      => { type => HASHREF, optional => 1 },
        };
    }
);

sub page_header {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->page_header_spec,
        }
    );

    my $base_element = Moonshine::Element->new($base_args);

    my $tag = $build_args->{header_tag};
    my $header = $base_element->add_child( $self->$tag( $build_args->{header} ) );

    if ( $build_args->{small} ) {
        $header->add_child( $self->small($build_args->{small}) );
    }

    return $base_element;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::PageHeader

=head1 SYNOPSIS

    $self->page_header({ class => 'search' });

returns a Moonshine::Element that renders too..


    <div class="page-header">
        <h2>Example page header <small>Subtest for header</small></h2>
    </div>

=cut

