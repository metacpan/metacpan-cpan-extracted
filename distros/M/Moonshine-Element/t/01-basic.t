use strict;
use warnings;

use Test::More; 
use feature qw/say/;

BEGIN {
    use_ok('UNIVERSAL::Object', 'patch_parent');
    use_ok('Moonshine::Element');
}
                                                       
my $element = Moonshine::Element->new({ tag => "table" });
                
is($element->{tag}, 'table', "$element->{tag} as expected");

is($element->has_tag, 1, "$element->{tag} exists");

eval { Moonshine::Element->new() };
my $exception = $@;
like($exception, qr/tag is required/, "Caught - $exception");

my $tag = $element->tag;

is($tag, 'table', "$tag as expected");

=pod
my $expected_attribute_list = [qw/class id style colspan rowspan onclick onchange type onkeyup
placeholder scope selected value autocomplete for onFocus onBlur href role width height data_toggle
data_placement title/];

is_deeply($element->{attribute_list}, $expected_attribute_list, "expected - $expected_attribute_list");
=cut

my $p_tag = Moonshine::Element->new({ tag => "p", data => ['one', 'two', 'three'] });

my $text = $p_tag->text;

is($text, 'one two three', $text);

my $render = $p_tag->render;

is($render, "<p>one two three</p>", "p tag - $render");

my $div_tag = Moonshine::Element->new({ tag => "div", class => "content" });

my $div_render = $div_tag->render;

is($div_render, '<div class="content"></div>', "div tag - $div_render");

$p_tag = $div_tag->add_child({ tag => "p", class => "p" });

$render = $p_tag->render;

is($render, '<p class="p"></p>', "p tag - $render");

$div_render = $div_tag->render;

is($div_render, '<div class="content"><p class="p"></p></div>', "div > p tag - $div_render");

my $p_before = $p_tag->add_before_element({ tag => 'p', class => 'first' });

$div_render = $div_tag->render;

is($div_render, '<div class="content"><p class="first"></p><p class="p"></p></div>', "div - div > p - $div_render");

my $p_before_before = $p_tag->add_before_element({ tag => 'p', class => 'second' });

$div_render = $div_tag->render;

is($div_render, '<div class="content"><p class="first"></p><p class="second"></p><p class="p"></p></div>', "div > p - p - p - $div_render");

my $p_after = $p_tag->add_after_element({ tag => "p", class => 'fourth' });

$div_render = $div_tag->render;

is($div_render, '<div class="content"><p class="first"></p><p class="second"></p><p class="p"></p><p class="fourth"></p></div>', 
    "div > p - p - p - $div_render");

my $p_after_before = $p_tag->add_after_element({ tag => "p", class => "threepointfour" });

$div_render = $div_tag->render;

is($div_render, 
    '<div class="content"><p class="first"></p><p class="second"></p><p class="p"></p><p class="threepointfour"></p><p class="fourth"></p></div>', 
    "div > p - p - p - $div_render");

my $p_after_after = $p_after->add_after_element({ tag => "p", class => "fifth" });

$div_render = $div_tag->render;

is($div_render,
 '<div class="content"><p class="first"></p><p class="second"></p><p class="p"></p><p class="threepointfour"></p><p class="fourth"></p><p class="fifth"></p></div>', 
    "div > p - p - p - $div_render");    

my $new_div = Moonshine::Element->new({ tag => 'div', class => 'two' });

ok($new_div->add_before_element({ tag => 'div', class => 'one' }));

$div_render = $new_div->render;

is($div_render,
    '<div class="one"></div><div class="two"></div>', "divs rendered - $div_render");

ok($new_div->add_after_element({ tag => 'div', class => 'three' }));

$div_render = $new_div->render;

is($div_render,
    '<div class="one"></div><div class="two"></div><div class="three"></div>', "divs rendered - $div_render");

my $array_div = Moonshine::Element->new({ tag => 'div', class => [ 'one', 'two', 'three' ] });

$div_render = $array_div->render;

is($div_render, '<div class="one two three"></div>', "okay one two three");

my $hash_div = Moonshine::Element->new({ 
    tag => 'div', 
    class => { 
        1 => 'for', 
        2 => 'special',
        3 => 'people', 
    }
});

$div_render = $hash_div->render;

is($div_render, '<div class="for special people"></div>', "okay sort the hash and join the values");

$hash_div->clear_class;
$div_render = $hash_div->render;
is($div_render, '<div></div>', "clear");

done_testing();
                                                            
1;
