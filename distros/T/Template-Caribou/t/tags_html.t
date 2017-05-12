use strict;
use warnings;

use Test::More tests => 43;

use Template::Caribou::Tags::HTML;

local *::RAW;
open ::RAW, '>', \my $raw;

for my $tag ( qw/
        p html head h1 h2 h3 h4 h5 h6 body emphasis div
        sup
        style title span li ol ul i b strong a 
        label link img section article
        table thead tbody th td
        fieldset legend form input select option button
        small
        textarea
    /) {

    is eval "$tag { }" => "<$tag />", $tag;
}

is eval "table_row { }" => "<tr />", "tr";



