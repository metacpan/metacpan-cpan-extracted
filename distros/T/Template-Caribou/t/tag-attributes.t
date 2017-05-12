use strict;
use warnings;

use Test::More tests => 3;

use Template::Caribou::Tags qw/ render_tag attr /;

local *::RAW;
open ::RAW, '>', \my $raw;

unlike  render_tag( 'div', sub { attr stuff => '"'  } ) => qr/"""/,
    'attribute with double quote';
like  render_tag( 'div', sub { attr stuff => "'"  } ) => qr/"'"/,
    'attribute with single quote';
unlike  render_tag( 'div', sub { attr stuff => q{'"} }) => qr/"'""/,
        'attribute with both';
