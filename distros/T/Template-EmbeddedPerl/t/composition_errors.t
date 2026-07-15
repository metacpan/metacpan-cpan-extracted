use Test::Most;
use File::Path 'make_path';
use File::Spec;
use File::Temp 'tempdir';
use Scalar::Util 'refaddr';
use Template::EmbeddedPerl;

{
    package Local::CompositionErrors::View::HTML::Self;

    sub new { bless {}, $_[0] }
}

{
    package Local::CompositionErrors::View::HTML::Node;

    sub new {
        my ($class, $name, $child) = @_;
        return bless {name => $name, child => $child}, $class;
    }

    sub name { $_[0]->{name} }
    sub child { $_[0]->{child} }
}

{
    package Local::CompositionErrors::View::HTML::Explodes;

    sub new { bless {}, $_[0] }
}

{
    package Local::CompositionErrors::View::HTML::Wrapper;

    sub new { bless {}, $_[0] }
}

{
    package Local::CompositionErrors::View::HTML::Missing;

    sub new { bless {}, $_[0] }
}

{
    package Local::CompositionErrors::View::HTML::BrokenCompile;

    sub new { bless {}, $_[0] }
}

{
    package Local::CompositionErrors::View::HTML::BrokenRender;

    sub new { bless {}, $_[0] }
}

{
    package Local::CompositionErrors::VirtualLoader;

    our @ISA = ('Template::EmbeddedPerl');

    sub from_file {
        my ($proto, $identifier, @args) = @_;
        my $self = ref($proto) ? $proto : $proto->new(@args);
        push @{$self->{virtual_loads}}, $identifier;

        die "Virtual template '$identifier' failed to load\n"
            if $identifier eq 'virtual/fails';

        my $template = $self->{virtual_templates}{$identifier};
        die "Unknown virtual template '$identifier'\n" unless defined $template;

        return $self->from_string(
            $template,
            @args,
            source => "virtual://$identifier.epl",
            identifier => $identifier,
        );
    }
}

{
    package Local::CompositionErrors::VirtualView::HTML::Root;

    sub new { bless {name => 'root', child => $_[1]}, $_[0] }
    sub name { $_[0]->{name} }
    sub child { $_[0]->{child} }
}

{
    package Local::CompositionErrors::VirtualView::HTML::Child;

    sub new { bless {name => 'child'}, $_[0] }
    sub name { $_[0]->{name} }
}

{
    package Local::CompositionErrors::SourceObserverLoader;

    our @ISA = ('Template::EmbeddedPerl');

    sub from_file {
        my ($proto, $identifier, @args) = @_;
        my $self = ref($proto) ? $proto : $proto->new(@args);

        if ($identifier eq 'outer/with-source') {
            Template::EmbeddedPerl::from_file($self, $identifier, @args);
            Template::EmbeddedPerl::from_file($self, 'dependencies/same-engine', @args);
            die "same-engine observer loader failed\n";
        }

        if ($identifier eq 'outer/without-source') {
            Template::EmbeddedPerl::from_file(
                $self->{dependency_engine},
                'dependencies/other-engine',
                @args,
            );
            die "other-engine observer loader failed\n";
        }

        return $self->SUPER::from_file($identifier, @args);
    }
}

sub write_fixture {
    my ($root, $identifier, $content) = @_;
    my @parts = split m{/}, "$identifier.epl";
    my $file = File::Spec->catfile($root, @parts);
    my (undef, $directory) = File::Spec->splitpath($file);
    make_path($directory);
    open my $handle, '>', $file or die "Cannot write $file: $!";
    print {$handle} $content;
    close $handle or die "Cannot close $file: $!";
    return $file;
}

sub capture_failure {
    my ($callback) = @_;
    my $error;
    local $SIG{ALRM} = sub { die "render timed out\n" };
    local $SIG{__WARN__} = sub {
        die "uncontrolled recursion: $_[0]" if $_[0] =~ /Deep recursion/;
        warn $_[0];
    };
    alarm 3;
    eval { $callback->(); 1 } or $error = $@;
    alarm 0;
    return $error;
}

sub stack_section {
    my ($error) = @_;
    my ($stack) = $error =~ /^(Render stack:\n.*)\z/ms;
    return $stack;
}

sub assert_single_stack {
    my ($error, $expected, $description) = @_;
    is(scalar(() = $error =~ /^Render stack:$/mg), 1, "$description has one render stack");
    is(stack_section($error), $expected, "$description has the ordered render stack");
}

sub assert_frame_clean {
    my ($frame, $description) = @_;
    is_deeply($frame->render_stack, [], "$description clears the render stack");
    is($frame->default_body, '', "$description clears the default body");
    is($frame->content('css'), '', "$description clears named CSS content");
    is($frame->content('js'), '', "$description clears named JavaScript content");
}

my $directory = tempdir(CLEANUP => 1);
my $partial_self_source = write_fixture(
    $directory,
    'partials/self',
    "%= partial 'partials/self'\n",
);
my $layout_self_source = write_fixture(
    $directory,
    'layouts/self',
    "% layout 'layouts/self'\nbody\n",
);
my $view_self_source = write_fixture(
    $directory,
    'html/self',
    "%= view \$self\n",
);
write_fixture(
    $directory,
    'html/node',
    q{<%= $self->name %><%= $self->child ? view($self->child) : '' %>},
);
my $runtime_partial_source = write_fixture(
    $directory,
    'partials/runtime',
    "% args \$child\n%= view \$child\n",
);
my $broken_partial_source = write_fixture(
    $directory,
    'partials/broken_compile',
    "% if (\n",
);
my $runtime_view_source = write_fixture(
    $directory,
    'html/explodes',
    "before\n% die \"nested runtime failed\"\n",
);
my $failing_layout_source = write_fixture(
    $directory,
    'layouts/fails',
    "layout before\n% die \"layout runtime failed\"\n",
);
write_fixture($directory, 'layouts/caller', 'caller[<%= yield %>]');
write_fixture($directory, 'layouts/callback', 'callback[<%= yield %>]');
write_fixture($directory, 'html/wrapper', 'wrapper[<%= yield %>]');
my $broken_compile_source = write_fixture(
    $directory,
    'html/broken_compile',
    "% if (\n",
);
write_fixture(
    $directory,
    'html/broken_render',
    "% die \"child render failed\"\n",
);

my $last_probe_context;
my $engine = Template::EmbeddedPerl->new(
    directories => [$directory],
    view_namespace => 'Local::CompositionErrors::View',
    smart_lines => 1,
    helpers => {
        state_probe => sub {
            my $context = Template::EmbeddedPerl->_current_render_context('state_probe');
            $last_probe_context = $context;
            return join '|',
                scalar(@{$context->frame->render_stack}),
                $context->frame->default_body,
                $context->frame->content('css'),
                $context->frame->content('js');
        },
        transaction_probe => sub {
            my $context = Template::EmbeddedPerl->_current_render_context('transaction_probe');
            my $frame = $context->frame;
            return join '|',
                $frame->default_body,
                $frame->content('css'),
                $frame->content('js'),
                join(',', map { $_->[0] } @{$frame->current_scope->{layouts}});
        },
    },
);

my $known_good = $engine->from_string(
    '<%= state_probe %>',
    source => 'known-good.epl',
    identifier => 'known-good',
);

sub assert_engine_reusable {
    my ($failed_frame, $description) = @_;
    is($known_good->render, '1|||', "$description leaves the engine reusable");
    isnt(
        refaddr($last_probe_context->frame),
        refaddr($failed_frame),
        "$description uses a fresh top-level frame",
    );
    my $outside_error = capture_failure(sub {
        Template::EmbeddedPerl->_current_render_context('outside_probe');
    });
    like(
        $outside_error,
        qr/Template helper 'outside_probe' called outside render context/,
        "$description restores ACTIVE_RENDERER",
    );
}

my $partial_root_source = File::Spec->catfile($directory, qw(roots partial-self.epl));
my $partial_root = $engine->from_string(
    "%= partial 'partials/self'\n",
    source => $partial_root_source,
    identifier => 'roots/partial-self',
);
my $partial_context = $engine->_new_render_context(source => $partial_root_source);
$partial_context->frame->append_content('css', 'stale partial css');
my $partial_error = capture_failure(sub {
    $partial_root->_render_with_context(
        $partial_context,
        {
            kind => 'root',
            identifier => 'roots/partial-self',
            source => $partial_root_source,
        },
    );
});
like(
    $partial_error,
    qr/Render cycle detected: partial partials\/self -> partial partials\/self/,
    'a partial self-cycle is rejected before uncontrolled recursion',
);
assert_single_stack(
    $partial_error,
    "Render stack:\n"
        . "  root roots/partial-self ($partial_root_source)\n"
        . "  partial partials/self ($partial_self_source)\n",
    'partial cycle',
);
assert_frame_clean($partial_context->frame, 'partial cycle failure');
assert_engine_reusable($partial_context->frame, 'partial cycle failure');

my $layout_context = $engine->_new_render_context(source => $layout_self_source);
$layout_context->frame->append_content('js', 'stale layout js');
my $layout_error = capture_failure(sub {
    $engine->from_file('layouts/self')->_render_with_context(
        $layout_context,
        {
            kind => 'root',
            identifier => 'layouts/self',
            source => $layout_self_source,
        },
    );
});
like(
    $layout_error,
    qr/Render cycle detected: layout layouts\/self -> layout layouts\/self/,
    'a layout self-cycle is rejected during deferred layout application',
);
assert_single_stack(
    $layout_error,
    "Render stack:\n"
        . "  root layouts/self ($layout_self_source)\n"
        . "  layout layouts/self ($layout_self_source)\n",
    'layout cycle',
);
assert_frame_clean($layout_context->frame, 'layout cycle failure');
assert_engine_reusable($layout_context->frame, 'layout cycle failure');

my $self_view = Local::CompositionErrors::View::HTML::Self->new;
my $view_context = $engine->_new_render_context(
    view => $self_view,
    root_view => $self_view,
    source => $view_self_source,
);
$view_context->frame->append_content('css', 'stale view css');
my $view_error = capture_failure(sub {
    $view_context->render_view_object($self_view);
});
like(
    $view_error,
    qr/Render cycle detected: root Local::CompositionErrors::View::HTML::Self -> view Local::CompositionErrors::View::HTML::Self/,
    'a repeated root view object is rejected at its first nested render',
);
assert_single_stack(
    $view_error,
    "Render stack:\n"
        . "  root Local::CompositionErrors::View::HTML::Self ($view_self_source)\n",
    'typed view cycle',
);
assert_frame_clean($view_context->frame, 'typed view cycle failure');
assert_engine_reusable($view_context->frame, 'typed view cycle failure');

my $grandchild = Local::CompositionErrors::View::HTML::Node->new('grandchild');
my $child = Local::CompositionErrors::View::HTML::Node->new('child', $grandchild);
my $parent = Local::CompositionErrors::View::HTML::Node->new('parent', $child);
is(
    $engine->render_view($parent),
    'parentchildgrandchild',
    'distinct objects of one view class do not form a render cycle',
);

my $runtime_root_source = File::Spec->catfile($directory, qw(roots runtime.epl));
my $runtime_root = $engine->from_string(
    "%= partial 'partials/runtime', child => \$_[0]\n",
    source => $runtime_root_source,
    identifier => 'roots/runtime',
);
my $runtime_context = $engine->_new_render_context(source => $runtime_root_source);
my $exploding_view = Local::CompositionErrors::View::HTML::Explodes->new;
my $runtime_error = capture_failure(sub {
    $runtime_root->_render_with_context(
        $runtime_context,
        {
            kind => 'root',
            identifier => 'roots/runtime',
            source => $runtime_root_source,
        },
        $exploding_view,
    );
});
like($runtime_error, qr/nested runtime failed/, 'nested runtime diagnostics preserve the original message');
like(
    $runtime_error,
    qr/nested runtime failed at \Q$runtime_view_source\E line 2/,
    'nested runtime diagnostics preserve the exact failing source and line',
);
assert_single_stack(
    $runtime_error,
    "Render stack:\n"
        . "  root roots/runtime ($runtime_root_source)\n"
        . "  partial partials/runtime ($runtime_partial_source)\n"
        . "  view Local::CompositionErrors::View::HTML::Explodes ($runtime_view_source)\n",
    'nested runtime failure',
);
assert_frame_clean($runtime_context->frame, 'nested runtime failure');
assert_engine_reusable($runtime_context->frame, 'nested runtime failure');

my $layout_runtime_root_source = File::Spec->catfile($directory, qw(roots layout-runtime.epl));
my $layout_runtime_root = $engine->from_string(
    "% layout 'layouts/fails'\nbody\n",
    source => $layout_runtime_root_source,
    identifier => 'roots/layout-runtime',
);
my $layout_runtime_context = $engine->_new_render_context(source => $layout_runtime_root_source);
my $layout_runtime_error = capture_failure(sub {
    $layout_runtime_root->_render_with_context(
        $layout_runtime_context,
        {
            kind => 'root',
            identifier => 'roots/layout-runtime',
            source => $layout_runtime_root_source,
        },
    );
});
like(
    $layout_runtime_error,
    qr/layout runtime failed at \Q$failing_layout_source\E line 2/,
    'a deferred layout failure preserves its exact source and line',
);
assert_single_stack(
    $layout_runtime_error,
    "Render stack:\n"
        . "  root roots/layout-runtime ($layout_runtime_root_source)\n"
        . "  layout layouts/fails ($failing_layout_source)\n",
    'deferred layout runtime failure',
);
assert_frame_clean($layout_runtime_context->frame, 'deferred layout runtime failure');
assert_engine_reusable($layout_runtime_context->frame, 'deferred layout runtime failure');

my $callback_root_source = File::Spec->catfile($directory, qw(roots callback.epl));
my $callback_root = $engine->from_string(<<'EPL',
% content_for css => sub { raw 'callback css' }
%= view $_[0], sub {
% content_for js => sub { raw 'callback js' }
% die "wrapper callback failed"
% }
EPL
    source => $callback_root_source,
    identifier => 'roots/callback',
);
my $callback_context = $engine->_new_render_context(source => $callback_root_source);
my $callback_error = capture_failure(sub {
    $callback_root->_render_with_context(
        $callback_context,
        {
            kind => 'root',
            identifier => 'roots/callback',
            source => $callback_root_source,
        },
        $self_view,
    );
});
like($callback_error, qr/wrapper callback failed/, 'a typed wrapper callback failure propagates');
assert_single_stack(
    $callback_error,
    "Render stack:\n"
        . "  root roots/callback ($callback_root_source)\n",
    'typed wrapper callback failure',
);
assert_frame_clean($callback_context->frame, 'typed wrapper callback failure');
assert_engine_reusable($callback_context->frame, 'typed wrapper callback failure');

my $caught_callback_failure = $engine->from_string(<<'EPL',
% content_for css => sub { raw 'caller css' }
% layout 'layouts/caller'
% my $caught;
% eval {
%   view $_[0], sub {
%     content_for css => sub { raw 'callback css' }
%     content_for js => sub { raw 'callback js' }
%     layout 'layouts/callback'
%     die "caught callback failure"
%   };
%   1;
% } or $caught = $@;
%= transaction_probe
EPL
    source => 'roots/caught-callback.epl',
    identifier => 'roots/caught-callback',
);
my $caught_callback_context = $engine->_new_render_context;
my $caught_callback_output = $caught_callback_context->frame->with_body(
    'caller body',
    sub {
        return $caught_callback_failure->_render_with_context(
            $caught_callback_context,
            {
                kind => 'root',
                identifier => 'roots/caught-callback',
                source => 'roots/caught-callback.epl',
            },
            Local::CompositionErrors::View::HTML::Wrapper->new,
        );
    },
);
like(
    $caught_callback_output,
    qr/caller\[caller body\|caller css\|\|layouts\/caller\]/,
    'a caught wrapper callback failure restores body, content, and caller layouts',
);
is(
    $caught_callback_context->frame->content('css'),
    'caller css',
    'a caught callback failure preserves earlier caller content',
);
is(
    $caught_callback_context->frame->content('js'),
    '',
    'a caught callback failure removes callback content',
);

my $caught_child_failure = $engine->from_string(<<'EPL',
% content_for css => sub { raw 'caller css' }
% layout 'layouts/caller'
% my $caught;
% eval {
%   view $_[0], sub {
%     content_for css => sub { raw 'callback css' }
%     content_for js => sub { raw 'callback js' }
%     layout 'layouts/callback'
%     return raw 'callback body';
%   };
%   1;
% } or $caught = $@;
%= transaction_probe
EPL
    source => 'roots/caught-child.epl',
    identifier => 'roots/caught-child',
);
for my $case (
    ['lookup', Local::CompositionErrors::View::HTML::Missing->new],
    ['compile', Local::CompositionErrors::View::HTML::BrokenCompile->new],
    ['render', Local::CompositionErrors::View::HTML::BrokenRender->new],
) {
    my ($failure, $child) = @$case;
    my $context = $engine->_new_render_context;
    my $output = $context->frame->with_body(
        'caller body',
        sub {
            return $caught_child_failure->_render_with_context(
                $context,
                {
                    kind => 'root',
                    identifier => 'roots/caught-child',
                    source => 'roots/caught-child.epl',
                },
                $child,
            );
        },
    );
    like(
        $output,
        qr/caller\[caller body\|caller css\|\|layouts\/caller\]/,
        "a caught child $failure failure restores body, content, and caller layouts",
    );
    is(
        $context->frame->content('css'),
        'caller css',
        "a caught child $failure failure preserves earlier caller content",
    );
    is(
        $context->frame->content('js'),
        '',
        "a caught child $failure failure removes callback content",
    );
}

my $successful_transaction_context = $engine->_new_render_context;
my $successful_transaction_output = $successful_transaction_context->frame->with_body(
    'caller body',
    sub {
        return $caught_child_failure->_render_with_context(
            $successful_transaction_context,
            {
                kind => 'root',
                identifier => 'roots/successful-child',
                source => 'roots/caught-child.epl',
            },
            Local::CompositionErrors::View::HTML::Wrapper->new,
        );
    },
);
like(
    $successful_transaction_output,
    qr/caller\[callback\[caller body\|caller csscallback css\|callback js\|layouts\/caller,layouts\/callback\]\]/,
    'a successful wrapper transaction keeps callback content and layouts',
);
is(
    $successful_transaction_context->frame->content('css'),
    'caller csscallback css',
    'a successful wrapper transaction commits named content',
);

my $typed_root_compile_error = capture_failure(sub {
    $engine->render_view(Local::CompositionErrors::View::HTML::BrokenCompile->new);
});
like(
    $typed_root_compile_error,
    qr/\Q$broken_compile_source\E line 1/,
    'a broken typed root compile reports its resolved source and exact line',
);
assert_single_stack(
    $typed_root_compile_error,
    "Render stack:\n"
        . "  root Local::CompositionErrors::View::HTML::BrokenCompile ($broken_compile_source)\n",
    'broken typed root compile',
);

my $broken_partial_root_source = File::Spec->catfile($directory, qw(roots broken-partial.epl));
my $broken_partial_root = $engine->from_string(
    "%= partial 'partials/broken_compile'\n",
    source => $broken_partial_root_source,
    identifier => 'roots/broken-partial',
);
my $broken_partial_error = capture_failure(sub {
    $broken_partial_root->render;
});
like(
    $broken_partial_error,
    qr/\Q$broken_partial_source\E line 1/,
    'a broken nested partial compile reports its resolved source and exact line',
);
assert_single_stack(
    $broken_partial_error,
    "Render stack:\n"
        . "  root roots/broken-partial ($broken_partial_root_source)\n"
        . "  partial partials/broken_compile ($broken_partial_source)\n",
    'broken nested partial compile',
);

my $child_diagnostic_root_source = File::Spec->catfile($directory, qw(roots child-diagnostic.epl));
my $child_diagnostic_root = $engine->from_string(
    "%= view \$_[0]\n",
    source => $child_diagnostic_root_source,
    identifier => 'roots/child-diagnostic',
);
for my $case (
    [
        'missing child view lookup',
        Local::CompositionErrors::View::HTML::Missing->new,
        'Local::CompositionErrors::View::HTML::Missing',
        'unknown',
        undef,
    ],
    [
        'broken child view compile',
        Local::CompositionErrors::View::HTML::BrokenCompile->new,
        'Local::CompositionErrors::View::HTML::BrokenCompile',
        $broken_compile_source,
        qr/\Q$broken_compile_source\E line 1/,
    ],
) {
    my ($description, $child, $identifier, $source, $source_pattern) = @$case;
    my $error = capture_failure(sub {
        $child_diagnostic_root->render($child);
    });
    like($error, $source_pattern, "$description preserves the resolved source")
        if $source_pattern;
    assert_single_stack(
        $error,
        "Render stack:\n"
            . "  root roots/child-diagnostic ($child_diagnostic_root_source)\n"
            . "  view $identifier ($source)\n",
        $description,
    );
}

my $virtual_engine = Local::CompositionErrors::VirtualLoader->new(
    directories => [],
    view_namespace => 'Local::CompositionErrors::VirtualView',
    virtual_loads => [],
    virtual_templates => {
        'html/root' => q{<% layout 'virtual/layout' %>root(<%= $self->name %>|<%= context_probe %>|<%= partial 'virtual/partial' %>|<%= view $self->child %>)},
        'virtual/partial' => q{partial(<%= $self->name %>|<%= context_probe %>)},
        'html/child' => q{child(<%= $self->name %>|<%= context_probe %>)},
        'virtual/layout' => q{layout(<%= $self->name %>|<%= context_probe %>|<%= yield %>)},
    },
    helpers => {
        context_probe => sub {
            my $context = Template::EmbeddedPerl->_current_render_context('context_probe');
            return join '/',
                $context->view->name,
                $context->root_view->name,
                join('>', map { $_->{kind} } @{$context->frame->render_stack}),
                $context->source;
        },
    },
);
my $virtual_root = Local::CompositionErrors::VirtualView::HTML::Root->new(
    Local::CompositionErrors::VirtualView::HTML::Child->new,
);
is(
    $virtual_engine->render_view($virtual_root),
    'layout(root|root/root/root>layout/virtual://virtual/layout.epl|'
        . 'root(root|root/root/root/virtual://html/root.epl|'
        . 'partial(root|root/root/root>partial/virtual://virtual/partial.epl)|'
        . 'child(child|child/root/root>view/virtual://html/child.epl)))',
    'composition dispatches virtual root, partial, child, and layout templates with one lexical context frame',
);
is_deeply(
    $virtual_engine->{virtual_loads},
    ['html/root', 'virtual/partial', 'html/child', 'virtual/layout'],
    'every composition path dispatches once through the public virtual loader',
);

my $virtual_failure_root = $virtual_engine->from_string(
    q{<%= partial 'virtual/fails' %>},
    source => 'virtual-failure-root.epl',
    identifier => 'virtual-failure-root',
);
my $virtual_load_error = capture_failure(sub {
    $virtual_failure_root->render;
});
assert_single_stack(
    $virtual_load_error,
    "Render stack:\n"
        . "  root virtual-failure-root (virtual-failure-root.epl)\n"
        . "  partial virtual/fails (unknown)\n",
    'virtual loader failure',
);
is(
    scalar(grep { $_ eq 'virtual/fails' } @{$virtual_engine->{virtual_loads}}),
    1,
    'a failing virtual loader is invoked once for one attempted render entry',
);

my $same_engine_dependency_source = write_fixture(
    $directory,
    'dependencies/same-engine',
    'same engine dependency',
);
my $other_engine_directory = tempdir(CLEANUP => 1);
my $other_engine_dependency_source = write_fixture(
    $other_engine_directory,
    'dependencies/other-engine',
    'other engine dependency',
);
my $outer_with_source = write_fixture(
    $directory,
    'outer/with-source',
    'outer source',
);
my $source_observer_engine = Local::CompositionErrors::SourceObserverLoader->new(
    directories => [$directory],
    dependency_engine => Template::EmbeddedPerl->new(
        directories => [$other_engine_directory],
    ),
);
my $same_engine_observer_root = $source_observer_engine->from_string(
    q{<%= partial 'outer/with-source' %>},
    source => 'same-engine-observer-root.epl',
    identifier => 'same-engine-observer-root',
);
my $same_engine_observer_error = capture_failure(sub {
    $same_engine_observer_root->render;
});
like(
    $same_engine_observer_error,
    qr/same-engine observer loader failed/,
    'a custom outer loader failure is preserved after a same-engine dependency load',
);
assert_single_stack(
    $same_engine_observer_error,
    "Render stack:\n"
        . "  root same-engine-observer-root (same-engine-observer-root.epl)\n"
        . "  partial outer/with-source ($outer_with_source)\n",
    'same-engine nested source observation',
);
unlike(
    $same_engine_observer_error,
    qr/\Q$same_engine_dependency_source\E/,
    'a same-engine dependency source does not replace the outer attempted entry source',
);

my $other_engine_observer_root = $source_observer_engine->from_string(
    q{<%= partial 'outer/without-source' %>},
    source => 'other-engine-observer-root.epl',
    identifier => 'other-engine-observer-root',
);
my $other_engine_observer_error = capture_failure(sub {
    $other_engine_observer_root->render;
});
like(
    $other_engine_observer_error,
    qr/other-engine observer loader failed/,
    'a custom outer loader failure is preserved after an other-engine dependency load',
);
assert_single_stack(
    $other_engine_observer_error,
    "Render stack:\n"
        . "  root other-engine-observer-root (other-engine-observer-root.epl)\n"
        . "  partial outer/without-source (unknown)\n",
    'other-engine nested source observation',
);
unlike(
    $other_engine_observer_error,
    qr/\Q$other_engine_dependency_source\E/,
    'an other-engine dependency source does not populate the outer attempted entry source',
);

my $first_success = $engine->from_string(
    q{<% content_for css => sub { raw 'first css' }; %><%= yield 'css' %>},
    source => 'first-success.epl',
    identifier => 'first-success',
);
my $second_success = $engine->from_string(
    q{<%= yield 'css' %><%= has_content('css') ? 'leaked' : 'clean' %>},
    source => 'second-success.epl',
    identifier => 'second-success',
);
is($first_success->render, 'first css', 'the first successful top-level render contributes named content');
is($second_success->render, 'clean', 'named content does not leak between successful top-level renders');

done_testing;
