#!/usr/bin/perl

use FindBin;
use lib ( "$FindBin::Bin/../lib" );
use strict;
use warnings;
use CSS::SpriteBuilder;

my $root = $FindBin::Bin;

my $builder = CSS::SpriteBuilder->new(
    source_dir     => "$root/public",
    output_dir     => "$root/public/sprites",
    css_url_prefix => '/sprites/',
);

$builder->build(config => \*DATA);
$builder->write_css("$root/public/css/sprite.css");
$builder->write_xml("$root/sprite.xml");

__DATA__
<root>

<sprites>
    <sprite file="sprite.png" layout="vertical">
        <image file="icons/small/Add.png"/>
        <image file="icons/medium/*.png"/>
        <image file="icons/small/Brick.png" is_repeat="1" is_background="1" css_selector=".bg-brick"/>
    </sprite>
</sprites>

</root>
