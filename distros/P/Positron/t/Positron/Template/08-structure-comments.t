#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Tests of the switching mechanism

my $template = Positron::Template->new();

sub dom {
    my ($quant) = @_;
    return [ 'div', { },
        [ 'span', { style => "{/$quant Remove this}" },
           [ 'b', {}, "Remove me" ], 
           " please",
        ],
        ['hr', {} ],
    ];
}

is_deeply( $template->process(dom(''), {}), 
    ['div', {}, ['hr', {}] ],
    "Blank quantifier"
);
is_deeply( $template->process(dom('-'), {}), 
    ['div', {}, ['hr', {}] ],
    "Minus quantifier (unchanged)"
);
is_deeply( $template->process(dom('+'), {}), 
    ['div', {}, ['span', {},], ['hr', {}] ],
    "Plus quantifier (keeps node)"
);
is_deeply( $template->process(dom('*'), {}), 
    ['div', {}, ['b', {}, "Remove me"], " please", ['hr', {}] ],
    "Star quantifier (keeps contents)"
);

done_testing;


