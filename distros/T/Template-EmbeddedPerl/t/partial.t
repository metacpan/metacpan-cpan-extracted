use Test::Most;
use File::Spec;
use Template::EmbeddedPerl;

{
    package Local::Partial::ContextProbe;

    sub new { bless {name => $_[1]}, $_[0] }

    sub to_safe_string {
        my ($self) = @_;
        my $context = Template::EmbeddedPerl->_current_render_context('context_probe');
        $Local::Partial::captured_context = $context;
        $Local::Partial::captured_scope = $context->frame->current_scope;
        return $self->{name};
    }
}

my $template_directory = File::Spec->catdir(qw(t templates composition));
my $item_source = File::Spec->catfile($template_directory, qw(contacts item.epl));
my $engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    smart_lines => 1,
    auto_escape => 1,
);

my $page = $engine->from_string(<<'EPL', source => 'pages/contacts.epl');
<ul>
%= partial 'contacts/item', contact => {name => '<Jane>'}
</ul>
EPL

is(
    $page->render,
    "<ul>\n<li>&lt;Jane&gt;</li>\n</ul>\n",
    'partial output is escaped once',
);

my $missing_required = $engine->from_string(
    "<%= partial 'contacts/item' %>\n",
    source => 'pages/missing-required.epl',
);
throws_ok {
    $missing_required->render;
} qr/Missing required template argument 'contact' at \Q$item_source\E line 1/,
    'partial target validates required arguments';

my $unknown_argument = $engine->from_string(
    "<%= partial 'contacts/item', contact => {}, extra => 1 %>\n",
    source => 'pages/unknown-argument.epl',
);
throws_ok {
    $unknown_argument->render;
} qr/Unknown template argument 'extra' at \Q$item_source\E line 1/,
    'partial target validates unknown arguments';

my $view = bless {}, 'Local::Partial::View';
my $root_view = bless {}, 'Local::Partial::RootView';
my $context = $engine->_new_render_context(
    view => $view,
    root_view => $root_view,
    source => 'pages/outer.epl',
);
my $nested_page = $engine->from_string(
    "% args \$probe\n<%= partial 'contacts/item', contact => {name => \$probe} %>\n",
    source => 'pages/outer.epl',
    identifier => 'pages/outer',
);
my $probe = Local::Partial::ContextProbe->new('<Jane>');

is(
    $nested_page->_render_with_context(
        $context,
        {
            kind => 'root',
            identifier => 'pages/outer',
            source => 'pages/outer.epl',
        },
        probe => $probe,
    ),
    "<li>&lt;Jane&gt;</li>\n\n",
    'partial renders immediately in its parent output',
);
is($Local::Partial::captured_context->view, $view, 'partial inherits the current view');
is($Local::Partial::captured_context->root_view, $root_view, 'partial inherits the root view');
is($Local::Partial::captured_context->frame, $context->frame, 'partial shares its parent frame');
is($Local::Partial::captured_context->source, $item_source, 'partial context uses the target source');
is($Local::Partial::captured_scope->{kind}, 'partial', 'partial is the active render scope');
is($Local::Partial::captured_scope->{identifier}, 'contacts/item', 'scope keeps the partial identifier');
is($Local::Partial::captured_scope->{source}, $item_source, 'scope keeps the partial source');
is($Local::Partial::captured_scope->{view}, $view, 'scope keeps the inherited view');
is_deeply($Local::Partial::captured_scope->{layouts}, [], 'scope reserves layouts for later composition');
is($context->frame->current_scope, undef, 'nested render scopes are cleaned up');

throws_ok {
    $missing_required->_render_with_context(
        $context,
        {
            kind => 'root',
            identifier => 'pages/missing-required',
            source => 'pages/missing-required.epl',
        },
    );
} qr/Missing required template argument 'contact'/,
    'nested failures retain the target argument error';
is($context->frame->current_scope, undef, 'nested render scopes are cleaned up after errors');

my $invalid_identifier = $engine->from_string(
    '<% my $identifier = shift; %><%= partial $identifier %>',
    source => 'pages/invalid-identifier.epl',
);
for my $identifier (undef, []) {
    throws_ok {
        $invalid_identifier->render($identifier);
    } qr/Invalid partial identifier/,
        'partial requires a defined non-reference identifier';
}

my $missing_template = $engine->from_string(
    "<%= partial 'contacts/missing', contact => {} %>\n",
    source => 'pages/missing-template.epl',
);
throws_ok {
    $missing_template->render;
} qr/Template 'contacts\/missing' not found; searched: \Q@{[ File::Spec->catfile($template_directory, 'contacts', 'missing.epl') ]}\E/,
    'missing partial reports ordered template diagnostics';

done_testing;
