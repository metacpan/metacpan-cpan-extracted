package MyTags;

use strict;
use warnings;

use Template::Caribou::Utils;

use parent 'Exporter';

our @EXPORT = qw/ my_img /;


sub my_img(&) { render_tag( 'img', sub {
    die "img needs a 'src'" unless $_[0]->{src};
}, shift ) };

1;
