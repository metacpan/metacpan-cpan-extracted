use strict;
use warnings;

use Test::More tests => 10;

use Template::Caribou::Tags qw/ render_tag attr /;

local *::RAW;
open ::RAW, '>', \my $raw;

is render_tag(
    'div', sub { "hello there" }
) => '<div>hello there</div>';

is render_tag(
    'div', sub { "hello there" }, sub { } 
) => '<div>hello there</div>';

is render_tag( 'div', 'X', sub { s/X/Y/ } ), '<div>Y</div>', 'grooming $_';
is render_tag( 'div', 'X', sub { $_{bar} = 'baz' } ), '<div bar="baz">X</div>', 'grooming %_';

use Template::Caribou::Tags
    mytag => { -as => 'foo' },
    mytag => { -as => 'bar', tag => 'bar' },
    mytag => { 
        -as => 'baz', 
        tag => 'zab',
        groom => sub { s//yay/ },
        class => 'quux',
        attr => { style => '!' },
    };

{
    package Bou; use Template::Caribou;
}

my $bou= Bou->new( indent => 0 );

is( $bou->render(sub{ foo {}  }) => '<div />' );
is( $bou->render(sub{ bar {}  }) => '<bar />' );
is( $bou->render(sub{ baz {}  }) => '<zab class="quux" style="!">yay</zab>' );

subtest 'with indentation' => sub {
    local $Template::Caribou::TAG_INDENT_LEVEL = 0.1;
    like foo {
            foo { 'one' };
            foo { 
                print 'two';
                foo { 'three' };
            }
        } 
    => qr/<div>\n  <div>one/;
};

subtest 'without indentation' => sub {
    local $Template::Caribou::TAG_INDENT_LEVEL = 0;
    like foo {
            foo { 'one' };
            foo { 
                print 'two';
                foo { 'three' };
            }
        } 
    => qr/<div><div>one/;
};

subtest 'attributes via %_' => sub {
    is render_tag( foo => sub {
            $_{foo} = 'bar';
            return;
    }) => '<foo foo="bar" />';

    is render_tag( foo => sub {
            $_{class}{one} = 1;
            $_{class}{two} = 1;
            return;
    }) => '<foo class="one two" />',
        'class as hash';

    is render_tag( foo => sub {
            $_{class}{one} = 1;
            $_{class}{two} = 0;
            return;
    }) => '<foo class="one" />',
        'class as hash with a false value';

    is render_tag( foo => sub {
            $_{class}{one} = 1;
            $_{class}{two} = 1;
            attr '+class' => 'three';
            return;
    }) => '<foo class="one three two" />',
        'class as hash *and* attr';

    is render_tag( foo => sub {
            attr class => 'potato mosquito';
            attr '+class' => 'tomato';
            $_{class}{avocado}++;
            delete $_{class}{avocado};
            attr '-class' => 'mosquito';
            return;
    }) => '<foo class="potato tomato" />',
        'class as hash *and* attr';
};
