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
    my ($quant, $type) = @_;
    my $inner = {
        plain => [ ['b', {}, 'this'], 'that' ],
        structure => [
            ['ul', {style => '{@list}'},
                ['li', {}, '{$item}'],
            ], '{# the inner list}',
        ],
        none => [],
    }->{$type} or die "Unknown type $type in dom()";
    return [ 'div', { },
        [ 'p', { style => "{^$quant func}" },
            @$inner,
        ],
        ['hr', {} ],
    ];
}

my $data = {
    func => sub {
        my (@nodes) = @_;
        my $count = scalar(@nodes);
        # We know this is an ArrayRef DOM here
        # list context!
        return ['h1', {}, "$count nodes"], ['nav', {}, @nodes];
    },
    list => [
        { item => 'eins' },
        { item => 'zwei' },
    ],
};

my @inner = (['b', {}, 'this'], 'that');

is_deeply( $template->process(dom('', 'plain'), $data), 
    [ 'div', {}, ['h1', {}, "1 nodes"], ['nav', {}, ['p', {}, @inner] ] , ['hr', {} ] ], 
    "Blank quantifier, plain"
);
is_deeply( $template->process(dom('+', 'plain'), $data), 
    [ 'div', {}, ['p', {}, ['h1', {}, "2 nodes"], ['nav', {}, @inner] ] , ['hr', {} ] ], 
    "Plus quantifier, plain"
);
is_deeply( $template->process(dom('-', 'plain'), $data), 
    [ 'div', {}, ['h1', {}, "2 nodes"], ['nav', {}, @inner], ['hr', {} ] ], 
    "Minus quantifier, plain"
);

# structure

@inner = ( ['ul', {}, ['li', {}, 'eins'], ['li', {}, 'zwei'], ], '' );

is_deeply( $template->process(dom('', 'structure'), $data), 
    [ 'div', {}, ['h1', {}, "1 nodes"], ['nav', {}, ['p', {}, @inner] ] , ['hr', {} ] ], 
    "Blank quantifier, structure"
);
is_deeply( $template->process(dom('+', 'structure'), $data), 
    [ 'div', {}, ['p', {}, ['h1', {}, "2 nodes"], ['nav', {}, @inner] ] , ['hr', {} ] ], 
    "Plus quantifier, structure"
);
is_deeply( $template->process(dom('-', 'structure'), $data), 
    [ 'div', {}, ['h1', {}, "2 nodes"], ['nav', {}, @inner], ['hr', {} ] ], 
    "Minus quantifier, structure"
);

# none

@inner = ();

is_deeply( $template->process(dom('', 'none'), $data), 
    [ 'div', {}, ['h1', {}, "1 nodes"], ['nav', {}, ['p', {}, @inner] ] , ['hr', {} ] ], 
    "Blank quantifier, none"
);
is_deeply( $template->process(dom('+', 'none'), $data), 
    [ 'div', {}, ['p', {}, ['h1', {}, "0 nodes"], ['nav', {}, @inner] ] , ['hr', {} ] ], 
    "Plus quantifier, none"
);
is_deeply( $template->process(dom('-', 'none'), $data), 
    [ 'div', {}, ['h1', {}, "0 nodes"], ['nav', {}, @inner], ['hr', {} ] ], 
    "Minus quantifier, none"
);


done_testing;


