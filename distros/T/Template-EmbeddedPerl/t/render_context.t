use Test::Most;
use Template::EmbeddedPerl;
use Template::EmbeddedPerl::RenderContext;

my $engine = Template::EmbeddedPerl->new(
    prepend => 'my $prepended = shift;',
);

is(
    $engine->from_string('<%= $prepended %>:<%= shift %>')->render('first', 'second'),
    'first:second',
    'context argument is hidden from prepend, shift, and legacy @_',
);

my $first = $engine->_new_render_context;
my $second = $engine->_new_render_context;
isnt($first->frame, $second->frame, 'top-level contexts never share frames');

my $view = bless {}, 'Local::View';
my $child = $first->with(view => $view, source => 'child.epl');
is($child->engine, $first->engine, 'child keeps engine');
is($child->frame, $first->frame, 'child shares frame');
is($child->view, $view, 'child changes current view');
is($child->source, 'child.epl', 'child changes source');

done_testing;
