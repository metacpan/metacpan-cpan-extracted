use Test::Most;
use File::Spec;
use Template::EmbeddedPerl;
use Template::EmbeddedPerl::RenderFrame;
use Template::EmbeddedPerl::SafeString;

{
    package Local::Layout::ScopeProbe;

    sub new { bless {}, $_[0] }

    sub to_safe_string {
        my $context = Template::EmbeddedPerl->_current_render_context('layout_scope_probe');
        $Local::Layout::captured_stack = [
            map { $_->{kind} } @{$context->frame->render_stack}
        ];
        return 'Scoped';
    }
}

my $template_directory = File::Spec->catdir(qw(t templates composition));
my $engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    smart_lines => 1,
    auto_escape => 1,
    helpers => {
        inspect_safe => sub {
            my ($engine, $value) = @_;
            return Template::EmbeddedPerl::SafeString::is_safe($value)
                ? 'safe'
                : 'unsafe';
        },
    },
);

my $single = $engine->from_string(<<'EPL', source => 'pages/contacts.epl');
% layout 'layouts/application', title => 'Contacts'
<main>Contacts</main>
EPL

my $single_output = "<!doctype html><title>Contacts</title><body><main>Contacts</main>\n</body>\n";
is($single->render, $single_output, 'a layout wraps the rendered body');
is($single->render, $single_output, 'layout state does not leak between top-level renders');

my $args_then_layout = $engine->from_string(<<'EPL', source => 'pages/args-layout.epl');
% args $title
% layout q(layouts/application), title => $title
<main>Contacts</main>
EPL
is(
    $args_then_layout->render(title => 'Contacts'),
    $single_output,
    'an args rewrite preserves the following smart layout directive',
);

my $default_title = $engine->from_string(<<'EPL', source => 'pages/default-title.epl');
% layout 'layouts/application'
body
EPL
is(
    $default_title->render,
    "<!doctype html><title>Default</title><body>body\n</body>\n",
    'layout target applies its default arguments',
);

my $override_title = $engine->from_string(<<'EPL', source => 'pages/override-title.epl');
% layout 'layouts/application', title => 'Custom'
body
EPL
is(
    $override_title->render,
    "<!doctype html><title>Custom</title><body>body\n</body>\n",
    'layout arguments override target defaults',
);

my $nested = $engine->from_string(
    "% layout 'layouts/outer'\n% layout 'layouts/inner'\nbody",
    source => 'pages/nested.epl',
);
is($nested->render, 'outer(inner(body))', 'the first declared layout is outermost');

my $independent_args = $engine->from_string(
    "% layout 'layouts/application', title => 'Outer'\n"
        . "% layout 'layouts/application', title => 'Inner'\n"
        . 'body',
    source => 'pages/independent-layout-args.epl',
);
is(
    $independent_args->render,
    '<!doctype html><title>Outer</title><body>'
        . '<!doctype html><title>Inner</title><body>body</body>' . "\n"
        . '</body>' . "\n",
    'each layout declaration keeps independent named arguments',
);

my $with_partial = $engine->from_string(<<'EPL', source => 'pages/partial-layout.epl');
% layout 'layouts/application', title => 'Contacts'
<ul>
%= partial 'contacts/item', contact => {name => '<Jane>'}
</ul>
EPL
is(
    $with_partial->render,
    "<!doctype html><title>Contacts</title><body><ul>\n"
        . "<li>&lt;Jane&gt;</li>\n</ul>\n</body>\n",
    'partials compose inside layouts without double escaping',
);

my $empty_yield = $engine->from_string(
    '<%= inspect_safe(yield) %>',
    source => 'pages/empty-yield.epl',
);
is($empty_yield->render, 'safe', 'yield without a body returns an empty safe value');

my $scope_probe = $engine->from_string(<<'EPL', source => 'pages/scope-probe.epl');
% layout 'layouts/application', title => Local::Layout::ScopeProbe->new
body
EPL
$scope_probe->render;
is_deeply(
    $Local::Layout::captured_stack,
    ['root', 'layout'],
    'the originating scope remains active while its layout is applied',
);

my $frame = Template::EmbeddedPerl::RenderFrame->new;
my $ok = eval {
    $frame->with_body('outer', sub {
        is($frame->default_body, 'outer', 'with_body exposes its body dynamically');
        $frame->with_body('inner', sub { die "body failure\n" });
    });
    1;
};
ok(!$ok, 'with_body propagates callback exceptions');
like($@, qr/body failure/, 'with_body preserves the callback exception');
is($frame->default_body, '', 'with_body restores the previous body after an exception');

done_testing;
