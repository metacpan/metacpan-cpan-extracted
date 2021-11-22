package welcome::index;

use Mojo::Base 'Mojo::Leds::Page';

sub render_json {
    return { welcome => 1 };
}

1;
