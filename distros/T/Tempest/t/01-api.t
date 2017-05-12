#!perl -w

use Test::More 'no_plan';

BEGIN {
    use_ok( 'Tempest' );
}

## check regular methods
ok( defined(&Tempest::new), 'constructor' );

ok( defined(&Tempest::render), 'render method' );

## check static methods

ok( defined(&Tempest::version), 'version static method' );

ok( defined(&Tempest::api_version), 'api version static method' );

ok( defined(&Tempest::has_image_lib), 'supported libraries static method' );

## check getters and setters for instance properties
@props = (
    'input_file',
    'output_file',
    'coordinates',
    'plot_file',
    'color_file',
    'overlay',
    'opacity',
    'image_lib',
);

foreach $propname (@props) {
    eval("ok( defined(&Tempest::get_$propname), '$propname getter');");
    eval("ok( defined(&Tempest::set_$propname), '$propname setter');");
}

## check that constants exist and that they have the expected values
%consts = (
    'LIB_MAGICK' => 'Image::Magick',
    'LIB_GMAGICK' => 'Graphics::Magick',
    'LIB_GD' => 'GD',
);

foreach $constname (keys(%consts)) {
    eval("ok( defined(&Tempest::$constname), '$constname constant' );");
    if(eval("defined(&Tempest::$constname)")) {
        eval("is(Tempest::$constname, '$consts{$constname}', '$constname constant value');");
    }
}
