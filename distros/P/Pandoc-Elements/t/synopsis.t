use strict;
use Test::More;
use Pandoc::Elements;
use JSON;

# Use Test::Deep because it handles blessed structures
# with overloaded stringification correctly.

BEGIN {
    plan skip_all => 'Test::Deep not available' unless eval 'require Test::Deep; 1;';
    Test::Deep->import( qw[cmp_deeply noclass] );
}

my $ast = Document {
        title => MetaInlines [ Str 'Greeting' ]
    }, [
        Header( 1, attributes { id => 'de' }, [ Str 'Gruß' ] ),
        Para [ Str 'hello, world!' ],
    ], api_version => '1.17.0.4';

# note explain $ast->TO_JSON;

cmp_deeply $ast, noclass {   'blocks' => [
        {   'c' => [ 1, [ 'de', [], [] ], [ { 'c' => 'Gruß', 't' => 'Str' } ] ],
            't' => 'Header'
        },
        { 'c' => [ { 'c' => 'hello, world!', 't' => 'Str' } ], 't' => 'Para' }
    ],
    'meta' => {
        'title' =>
          { 'c' => [ { 'c' => 'Greeting', 't' => 'Str' } ], 't' => 'MetaInlines' }
    },
    'pandoc-api-version' => [ 1, 17, 0, 4 ]
};

my $json = JSON->new->utf8->convert_blessed->encode($ast);
cmp_deeply decode_json($json), noclass($ast), 'encode/decode JSON';
cmp_deeply Pandoc::Elements::pandoc_json($json), noclass($ast), 'pandoc_json';
$json = $ast->to_json;
cmp_deeply decode_json($json), noclass($ast), 'to_json';

eval { Pandoc::Elements->pandoc_json(".") };
like $@, qr{.+at.+synopsis.*\.t}, 'error in pandoc_json';

done_testing;

__DATA__
% Greeting
# Gruß {.de}
hello, world!
