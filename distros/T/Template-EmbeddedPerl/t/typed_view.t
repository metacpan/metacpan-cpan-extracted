use Test::Most;
use File::Spec;
use Template::EmbeddedPerl;

{
    package Local::EasyView::HTML::Greeting;
    use Moo;

    has name => (is => 'ro', required => 1);
    has punctuation => (
        is => 'ro',
        default => sub { '!' },
        coerce => sub { $_[0] eq 'question' ? '?' : $_[0] },
        isa => sub {
            die "punctuation must be one character\n"
                unless defined($_[0]) && !ref($_[0]) && length($_[0]) == 1;
        },
    );
}

{
    package Local::EasyView::GreetingAdapter;
    use Moo;

    has name => (is => 'ro', required => 1);
    sub punctuation { '~' }
    sub template { 'html/greeting' }
}

{
    package Local::View::HTML::Contacts::Index;
    use Moo;

    has title => (is => 'ro', required => 1);
    has contacts => (is => 'ro', required => 1);

    sub capture_context {
        my ($self) = @_;
        $Local::View::captured_context =
            Template::EmbeddedPerl->_current_render_context('capture_context');
        return 'captured';
    }
}

{
    package Local::View::Explicit;
    use Moo;

    has title => (is => 'ro', required => 1);

    sub template { 'components/navigation' }
}

{
    package Local::View::MissingExplicit;
    use Moo;

    sub template { 'missing/explicit' }
}

{
    package Local::View::HTML::Page;
    use Moo;

    has title => (is => 'ro', required => 1);
    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);
}

{
    package Local::View::HTML::Navbar;
    use Moo;

    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);
}

{
    package Local::View::HTML::Contacts::Item;
    use Moo;

    has contact => (is => 'ro', required => 1);
    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);
}

{
    package Local::View::MissingWrapper;
    use Moo;

    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);

    sub template { 'missing/wrapper' }
}

{
    package Local::View::Collision;

    sub new { bless {}, $_[0] }
    sub template { 'components/collision' }
}

{
    package Local::View::CollisionLeaf;

    sub new { bless {}, $_[0] }
    sub template { 'components/collision_leaf' }
}

my $template_directory = File::Spec->catdir(qw(t templates views));
my $easy_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::EasyView',
);

is(
    $easy_engine->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada' %>},
        source => 'default-construction.epl',
    )->render,
    "<p>Ada!</p>\n",
    'a logical Moo view is constructed with new and its attribute default applies',
);

is(
    $easy_engine->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada', punctuation => 'question' %>},
        source => 'explicit-construction.epl',
    )->render,
    "<p>Ada?</p>\n",
    'explicit template arguments are passed through Moo coercion',
);

my $loaded_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Loaded::View',
);
{
    local @INC = (File::Spec->catdir(qw(t lib)), @INC);
    is(
        $loaded_engine->from_string(
            q{<%= view 'HTML::Notice', message => 'Loaded' %>},
            source => 'class-loading.epl',
        )->render,
        "<aside>Loaded</aside>\n",
        'a logical view class is required from its package path before construction',
    );
}

my @factory_calls;
my $engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::View',
    view_factory => sub {
        my ($class, $args, $context) = @_;
        my $call = {
            class => $class,
            args => {%$args},
            context => $context,
        };
        push @factory_calls, $call;
        my $view = $class->new(
            %$args,
            root => $context->root_view,
            parent => $context->view,
        );
        $call->{view} = $view;
        return $view;
    },
    auto_escape => 1,
);

throws_ok {
    $engine->render_view(Local::View::MissingExplicit->new);
} qr/Template 'missing\/explicit' not found; searched:/,
    'a missing explicit template fails without convention fallback';

throws_ok {
    Local::View::HTML::Contacts::Index->new(contacts => []);
} qr/Missing required arguments?: title/,
    'Moo rejects a missing required attribute before rendering';

my $root = Local::View::HTML::Contacts::Index->new(
    title => 'Contacts',
    contacts => [
        {name => 'Jane'},
        {name => 'John'},
    ],
);

is(
    $engine->render_view($root),
    "<section class=\"page\">\n"
        . "<header>Contacts</header>\n"
        . "<p>page-root=Contacts; page-parent=Contacts</p>\n"
        . "<nav>root=Contacts; parent=Contacts</nav>\n"
        . "\n"
        . "<main>\n"
        . "\n"
        . "  <h1>Contacts</h1>\n"
        . "  <p>root=Contacts</p>\n"
        . "<article>Jane; root=Contacts; parent=Contacts</article>\n"
        . "\n\n"
        . "</main>\n"
        . "</section>\n"
        . "\n"
        . "captured\n",
    'render_view composes a logical typed wrapper and leaf around a Moo root',
);
is($Local::View::captured_context->view, $root, 'root context view is the rendered object');
is($Local::View::captured_context->root_view, $root, 'root context root_view is the rendered object');
is(
    $Local::View::captured_context->frame->current_scope,
    undef,
    'typed root render scope is cleaned up after rendering',
);

my ($page_call) = grep { $_->{class} eq 'Local::View::HTML::Page' } @factory_calls;
my ($item_call) = grep { $_->{class} eq 'Local::View::HTML::Contacts::Item' } @factory_calls;
my ($navbar_call) = grep { $_->{class} eq 'Local::View::HTML::Navbar' } @factory_calls;

isa_ok($page_call->{view}, 'Local::View::HTML::Page', 'wrapper callback receives the constructed page');
is_deeply(
    $page_call->{args},
    {title => 'Contacts'},
    'view_factory receives only explicit constructor arguments',
);
is($page_call->{context}->view, $root, 'factory context exposes the caller view');
is($page_call->{context}->root_view, $root, 'factory context preserves the typed root');
is($page_call->{view}->root, $root, 'page receives the top-level root');
is($page_call->{view}->parent, $root, 'page receives the caller as parent');
is($item_call->{context}->view, $root, 'leaf rendered in wrapper body keeps the caller context');
is($item_call->{view}->root, $root, 'leaf receives the top-level root');
is($item_call->{view}->parent, $root, 'leaf receives the body caller as parent');
is($navbar_call->{context}->view, $page_call->{view}, 'wrapper template child sees the wrapper as caller');
is($navbar_call->{view}->root, $root, 'wrapper child receives the top-level root');
is($navbar_call->{view}->parent, $page_call->{view}, 'wrapper child receives the wrapper as parent');

my $preconstructed_item = Local::View::HTML::Contacts::Item->new(
    contact => {name => 'Prebuilt'},
    root => $root,
    parent => $root,
);
my $object_leaf = $engine->from_string(
    '%= view $_[0]',
    source => 'object-leaf.epl',
);
my $object_context = $engine->_new_render_context(
    view => $root,
    root_view => $root,
    source => 'object-leaf.epl',
);
my $build_count = scalar @factory_calls;
is(
    $object_leaf->_render_with_context(
        $object_context,
        {kind => 'root', identifier => 'object-leaf', source => 'object-leaf.epl'},
        $preconstructed_item,
    ),
    "<article>Prebuilt; root=Contacts; parent=Contacts</article>\n",
    'a preconstructed leaf view renders through the object path',
);
is(scalar @factory_calls, $build_count, 'a preconstructed view bypasses view_factory');

my $preconstructed_page = Local::View::HTML::Page->new(
    title => 'Object Page',
    root => $root,
    parent => $root,
);
my $object_wrapper = $engine->from_string(<<'EPL', source => 'object-wrapper.epl');
%= view $_[0], sub {
  <strong><%= $_[0]->title %>|<%= $self->title %></strong>
% }
EPL
my $page_build_count = grep { $_->{class} eq 'Local::View::HTML::Page' } @factory_calls;
like(
    $object_wrapper->_render_with_context(
        $engine->_new_render_context(view => $root, root_view => $root),
        {kind => 'root', identifier => 'object-wrapper', source => 'object-wrapper.epl'},
        $preconstructed_page,
    ),
    qr{<header>Object Page</header>.*<strong>Object Page\|Contacts</strong>}s,
    'an object wrapper callback receives the child while lexical self remains the caller',
);
is(
    scalar(grep { $_->{class} eq 'Local::View::HTML::Page' } @factory_calls),
    $page_build_count,
    'a preconstructed wrapper bypasses view_factory',
);

my $object_with_args = $engine->from_string(
    q{<%= view $_[0], title => 'Not allowed' %>},
    source => 'object-with-args.epl',
);
throws_ok {
    $object_with_args->render($preconstructed_item);
} qr/Preconstructed view objects do not accept constructor arguments/,
    'a preconstructed view rejects constructor arguments clearly';

my $logical_with_odd_args = $engine->from_string(
    q{<%= view 'HTML::Page', title => 'Odd', 'dangling' %>},
    source => 'logical-with-odd-args.epl',
);
$build_count = scalar @factory_calls;
throws_ok {
    $logical_with_odd_args->_render_with_context(
        $engine->_new_render_context(view => $root, root_view => $root),
        {kind => 'root', identifier => 'logical-with-odd-args', source => 'logical-with-odd-args.epl'},
    );
} qr/Odd constructor argument list for logical view 'HTML::Page'/,
    'a logical view rejects an odd constructor list';
is(scalar @factory_calls, $build_count, 'odd logical arguments fail before view_factory');

my $constructor_failure = $engine->from_string(
    q{<%= view 'HTML::Page' %>},
    source => 'constructor-failure.epl',
);
my $constructor_error;
eval {
    $constructor_failure->_render_with_context(
        $engine->_new_render_context(view => $root, root_view => $root),
        {
            kind => 'root',
            identifier => 'constructor-failure',
            source => 'constructor-failure.epl',
        },
    );
    1;
} or $constructor_error = $@;
like(
    $constructor_error,
    qr/Missing required arguments?: title/,
    'a nested Moo constructor failure preserves its original error',
);
like(
    $constructor_error,
    qr{Render stack:\n  root constructor-failure \(constructor-failure\.epl\)\n  view HTML::Page \(unknown\)\n\z},
    'a nested Moo constructor failure identifies the attempted logical view',
);

my $collision_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::View',
);
my $collision_root = $collision_engine->from_string(
    q{<%= view $_[0] %>},
    source => 'collision-root.epl',
);
like(
    $collision_root->render(Local::View::Collision->new),
    qr/\Acollision leaf\s*\z/,
    'logical names do not collide with active object identity keys',
);

my $invalid_child_target = $engine->from_string(
    q{<%= view $_[0] %>},
    source => 'invalid-child-target.epl',
);
my $scalar_target = 'HTML::Page';
for my $case (
    ['undefined target', undef],
    ['empty logical name', ''],
    ['hash reference', {}],
    ['array reference', []],
    ['scalar reference', \$scalar_target],
) {
    my ($description, $target) = @$case;
    $build_count = scalar @factory_calls;
    throws_ok {
        $invalid_child_target->_render_with_context(
            $engine->_new_render_context(view => $root, root_view => $root),
            {kind => 'root', identifier => 'invalid-child-target', source => 'invalid-child-target.epl'},
            $target,
        );
    } qr/\ALogical view target must be a blessed object or a non-empty logical name/,
        "$description is rejected with the typed view target contract";
    is(
        scalar @factory_calls,
        $build_count,
        "$description fails before view_factory",
    );
}

throws_ok {
    $easy_engine->from_string(
        q{<%= view '../Greeting', name => 'Ada' %>},
        source => 'invalid-logical-name.epl',
    )->render;
} qr/Invalid logical view name '\.\.\/Greeting'/,
    'logical names must be relative Perl package names';

my $no_namespace = Template::EmbeddedPerl->new(
    directories => [$template_directory],
);
throws_ok {
    $no_namespace->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada' %>},
        source => 'missing-view-namespace.epl',
    )->render;
} qr/Logical view 'HTML::Greeting' requires view_namespace/,
    'logical construction requires a configured namespace';

throws_ok {
    $easy_engine->from_string(
        q{<%= view 'HTML::Missing' %>},
        source => 'missing-view-class.epl',
    )->render;
} qr/Failed to load logical view 'HTML::Missing' as 'Local::EasyView::HTML::Missing'/,
    'class-loading errors identify logical and expanded names';

my $moo_constructor_template = $easy_engine->from_string(
    q{<%= view 'HTML::Greeting' %>},
    source => 'moo-constructor-error.epl',
);
my $moo_constructor_error;
eval { $moo_constructor_template->render; 1 } or $moo_constructor_error = $@;
like(
    $moo_constructor_error,
    qr/Failed to construct logical view 'HTML::Greeting'.*Missing required arguments?: name/s,
    'Moo constructor errors retain their original detail',
);
like(
    $moo_constructor_error,
    qr{Render stack:\n  root moo-constructor-error\.epl \(moo-constructor-error\.epl\)\n  view HTML::Greeting \(unknown\)\n},
    'a Moo constructor error identifies the attempted logical view',
);

throws_ok {
    $easy_engine->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada', punctuation => 'long' %>},
        source => 'moo-type-error.epl',
    )->render;
} qr/Failed to construct logical view 'HTML::Greeting'.*punctuation must be one character/s,
    'Moo isa failures retain their original detail';

my $bad_factory_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::EasyView',
    view_factory => sub { return {} },
);
my $bad_factory_template = $bad_factory_engine->from_string(
    q{<%= view 'HTML::Greeting', name => 'Ada' %>},
    source => 'bad-view-factory.epl',
);
my $bad_factory_error;
eval { $bad_factory_template->render; 1 } or $bad_factory_error = $@;
like(
    $bad_factory_error,
    qr/view_factory did not return a blessed view for 'HTML::Greeting'/,
    'view_factory must return a blessed object',
);
like(
    $bad_factory_error,
    qr{Render stack:\n  root bad-view-factory\.epl \(bad-view-factory\.epl\)\n  view HTML::Greeting \(unknown\)\n},
    'a bad factory result identifies the attempted logical view',
);

my $throwing_factory_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::EasyView',
    view_factory => sub { die "container unavailable\n" },
);
throws_ok {
    $throwing_factory_engine->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada' %>},
        source => 'throwing-view-factory.epl',
    )->render;
} qr/view_factory failed for logical view 'HTML::Greeting'.*container unavailable/s,
    'view_factory errors identify the operation and retain the original exception';

my $invalid_factory_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::EasyView',
    view_factory => 'not a callback',
);
throws_ok {
    $invalid_factory_engine->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada' %>},
        source => 'invalid-view-factory.epl',
    )->render;
} qr/view_factory must be a code reference/,
    'view_factory configuration is validated when logical construction uses it';

my $adapter_factory_engine = Template::EmbeddedPerl->new(
    directories => [$template_directory],
    view_namespace => 'Local::EasyView',
    view_factory => sub {
        my ($class, $args, $context) = @_;
        is($class, 'Local::EasyView::HTML::Greeting', 'factory receives the requested class');
        return Local::EasyView::GreetingAdapter->new(%$args);
    },
);
is(
    $adapter_factory_engine->from_string(
        q{<%= view 'HTML::Greeting', name => 'Ada' %>},
        source => 'adapter-view-factory.epl',
    )->render,
    "<p>Ada~</p>\n",
    'view_factory may return a different blessed class with its own template policy',
);

my $nested_wrappers = $engine->from_string(<<'EPL', source => 'nested-wrappers.epl');
%= view 'HTML::Page', title => 'One', sub {
%= view 'HTML::Page', title => 'Two', sub {
%= view 'HTML::Page', title => 'Three', sub {
%= view 'HTML::Contacts::Item', contact => $self->contacts->[1]
% }
% }
% }
EPL
my $nested_output = $nested_wrappers->_render_with_context(
    $engine->_new_render_context(view => $root, root_view => $root),
    {kind => 'root', identifier => 'nested-wrappers', source => 'nested-wrappers.epl'},
);
like(
    $nested_output,
    qr{<header>One</header>.*<header>Two</header>.*<header>Three</header>.*<article>John;}s,
    'three typed wrappers nest in order and yield an inner leaf view',
);
is(
    scalar(() = $nested_output =~ /<section class="page">/g),
    3,
    'each nested typed wrapper renders exactly once',
);

my $missing_wrapper = Local::View::MissingWrapper->new(root => $root, parent => $root);
my $failing_wrapper = $engine->from_string(<<'EPL', source => 'failing-wrapper.epl');
%= view $_[0], sub {
body that must be restored
% }
EPL
my $failure_context = $engine->_new_render_context(view => $root, root_view => $root);
throws_ok {
    $failing_wrapper->_render_with_context(
        $failure_context,
        {kind => 'root', identifier => 'failing-wrapper', source => 'failing-wrapper.epl'},
        $missing_wrapper,
    );
} qr/Template 'missing\/wrapper' not found/,
    'a wrapper template failure propagates';
is($failure_context->frame->default_body, '', 'a wrapper failure restores the previous body');

my $explicit = Local::View::Explicit->new(title => 'Navigation');
is(
    $engine->render_view($explicit),
    "<nav>Navigation</nav>\n",
    'an explicit template method bypasses convention lookup',
);

for my $invalid (undef, {}, 'Local::View::Explicit') {
    throws_ok {
        $engine->render_view($invalid);
    } qr/render_view requires a blessed view object/,
        'render_view rejects an unblessed value';
}

my $legacy = $engine->from_string(
    q{<%= defined($self) ? ref($self) : 'no self' %>|<%= ref($_[0]) %>|<%= $_[0]->title %>},
    source => 'legacy-object.epl',
);
is(
    $legacy->render($explicit),
    'no self|Local::View::Explicit|Navigation',
    'legacy rendering keeps a blessed object in positional arguments without inferring self',
);

done_testing;
