use strict;
use Test::More;
use Pandoc::Elements;

my $c = citation { 
        id => 'foo', 
        prefix => [ Str "see" ], 
        suffix => [ Str "p.", Space, Str "42" ]
    };

is_deeply $c, {
   citationId => 'foo',
   citationHash => 1,
   citationMode => NormalCitation,
   citationNoteNum => 0,
   citationPrefix => [ Str "see" ],
   citationSuffix => [ Str "p.", Space, Str "42" ],
};

done_testing;
