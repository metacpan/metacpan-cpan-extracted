#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::Image;
use DateTime;
use Tags::HTML::Image;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Image->new(
        'css' => $css,
        'tags' => $tags,
);

# Definition of image.
my $image = Data::Image->new(
        'author' => 'Zuzana Zonova',
        'comment' => 'Michal from Czechia',
        'dt_created' => DateTime->new(
                'day' => 1,
                'month' => 1,
                'year' => 2022,
        ),
        'height' => 2730,
        'size' => 1040304,
        'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
        'width' => 4096,
);

# Init.
$obj->init($image);

# Process HTML and CSS.
$obj->process;
$obj->process_css;

# Print out.
print "HTML:\n";
print $tags->flush;
print "\n\n";
print "CSS:\n";
print $css->flush;

# Output:
# HTML:
# <figure class="image">
#   <img alt="Michal from Czechia" src=
#     "https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg"
#     >
#   </img>
#   <figcaption>
#     Michal from Czechia
#   </figcaption>
# </figure>
# 
# CSS:
# .image img {
#         display: block;
#         height: 100%;
#         width: 100%;
#         object-fit: contain;
# }
# .image {
#         height: calc(100vh);
# }
# .image figcaption {
#         position: absolute;
#         bottom: 0;
#         background: rgb(0, 0, 0);
#         background: rgba(0, 0, 0, 0.5);
#         color: #f1f1f1;
#         width: 100%;
#         transition: .5s ease;
#         opacity: 0;
#         font-size: 25px;
#         padding: 12.5px 5px;
#         text-align: center;
# }
# figure.image:hover figcaption {
#         opacity: 1;
# }