package Moonshine::Bootstrap::Component::BasicTemplate;

use Moonshine::Magic;
use Params::Validate qw/ARRAYREF/;
use Moonshine::Util;

lazy_components qw/head meta link script body title/;
extends 'Moonshine::Bootstrap::Component';

has(
    basic_template_spec => sub {
        {
            tag         => { default => 'html' },
            lang        => { default => 'en' },
            header      => { default => [ ], type => ARRAYREF },
            body        => { default => [ ], type => ARRAYREF },
        };
    }
);

sub basic_template {
    my ($self) = shift;

    my ( $base_args, $build_args ) = $self->validate_build(
        {
            params => $_[0] // {},
            spec => $self->basic_template_spec,
        }
    );

    unshift @{ $build_args->{header} }, (
        {
            action      => 'meta',
            charset     => 'utf-8',
        },
        {
            action      => 'meta',
            http_equiv  => 'X-UA-Compatible',
            content     => 'IE=edge',
        },
        {
            action      => 'meta',
            name        => 'viewport',
            content     => 'width=device-width, inline-scale=1',
        },
    );

    my $base_element = Moonshine::Element->new($base_args);
    
    $base_element->add_child( $self->head({ children => $build_args->{header} }) );
    $base_element->add_child( $self->body({ children => $build_args->{body} }) );

    return $base_element;    
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component::BasicTemplate

=head1 SYNOPSIS

    $self->basic_template({  });

returns a Moonshine::Element that renders too..

    <html lang="en">
        <head>
            ...
        </head>
        <body>
            ...
        </body>
    </html>

=cut
