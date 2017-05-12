package MyWebPage;

use strict;
use warnings;

use Moose::Role;

use Template::Caribou::Utils;
use Template::Caribou::Tags::HTML;

template page => sub {
    my ( $self, %arg ) = @_;

    html {
        head { };
        body {
            show( $arg{inner} || 'main' );
        }
    };
};

1;
