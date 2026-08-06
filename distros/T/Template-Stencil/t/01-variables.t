use Test::More;
use Template::Stencil;

plan skip_all => 'render API lands in phase 07'
    unless Template::Stencil->can('new');

my $stencil = Template::Stencil->new(
	template_dir => 't/template',
	wrapper => 'wrapper.tmpl',
);

my $template1 = q|{% welcome %}
{% include header.tmpl %}
{% for item in items %}
	{% set item_loop = loop %}
	{% for inner in item.inner %}
		<div {% if loop.first %}class="first"{% else %}class="other"{% end %} data-item-loop="{% item_loop.index %}" data-inner-loop="{% loop.index %}">
			{% inner %}
		</div>
	{% end %}
	{% if loop.last %}
		<p>{% loop.index %} last item_loop only once</p>
	{% end %}
{% end %}
|;

my $html = $stencil->render($template1, {
	js_scripts => ['lala.js'],
	page => { header => 'This is a header', number => [ 3 ] },
	welcome => 'Welcome',
	items => [
		{
			inner => [ 'one', 'two', 'three' ]
		},
		{
			inner => [ 'four', 'five', 'six' ]
		},
	]
});

my $html2 = $stencil->render('t/template/loops', {
	js_scripts => ['lala.js'],
	page => { header => 'This is a header', number => [ 3 ] },
	welcome => 'Welcome',
	items => [
		{
			inner => [ 'one', 'two', 'three' ]
		},
		{
			inner => [ 'four', 'five', 'six' ]
		},
	]
});

is($html, $html2, 'rendering from string and file should be the same');

# The full expected output, auto-escaping and wrapper accounted for,
# pretty-formatted via Eshu (the ' > ' in header.tmpl is literal
# template text, so it is not escaped).
SKIP: {
    skip 'Eshu required for the pretty golden', 1
        unless eval { require Eshu; 1 };
    my $expected = do {
        open my $fh, '<', 't/corpus/variables.golden' or die $!;
        local $/;
        <$fh>;
    };
    is($stencil->render($template1, {
        js_scripts => ['lala.js'],
        page => { header => 'This is a header', number => [ 3 ] },
        welcome => 'Welcome',
        items => [
            { inner => [ 'one', 'two', 'three' ] },
            { inner => [ 'four', 'five', 'six' ] },
        ],
    }, { pretty => 1 }), $expected, 'full expected HTML, prettified');
}

done_testing;
