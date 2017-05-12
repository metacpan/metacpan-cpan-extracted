#
# Tests for list limits
#
use strict;
use warnings;

use Test::More tests => 5;
use Template::Flute;

my ( $spec, $html, $flute, $out, $images );

$spec = q{<specification>
<list name="images" iterator="images">
    <param name="image" target="src" field="image_url" />
</list>
</specification>
};

$html = q{<div class="images">
    <img class="image" src="/images/bottle.jpg" />
</div>
};

$images = [
    { image_url => '/images/bottle1.jpg' },
    { image_url => '/images/bottle2.jpg' },
    { image_url => '/images/bottle3.jpg' },
];

$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    values        => { images => $images },
);

$out = $flute->process;
like( $out, qr{/images/bottle3.jpg}, q{list no limit} );
unlike( $out, qr{/images/bottle.jpg}, q{list no limit} );

$spec = q{<specification>
<list name="images" iterator="images" limit="1">
    <param name="image" target="src" field="image_url" />
</list>
</specification>
};
$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    values        => { images => $images },
);
$out = $flute->process;
like( $out, qr{/images/bottle1.jpg}, q{list with limit} );
unlike( $out, qr{/images/bottle.jpg}, q{list with limit} );
unlike( $out, qr{/images/bottle2.jpg}, q{list with limit} );
