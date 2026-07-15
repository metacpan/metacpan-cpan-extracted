use strict;
use warnings;

BEGIN {
    require Cwd;
    require File::Basename;
    require File::Spec;

    my $test_file = Cwd::abs_path(__FILE__);
    my $root = Cwd::abs_path(File::Spec->catdir(
        File::Basename::dirname($test_file),
        File::Spec->updir,
    ));
    unshift @INC, File::Spec->catdir($root, 'lib');
}

use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use JSON::PP qw(decode_json);
use Symbol qw(gensym);
use Pod::Simple::HTML;
use Test::Most;
use Template::EmbeddedPerl;

my $test_file = abs_path(__FILE__);
my $test_root = abs_path(File::Spec->catdir(dirname($test_file), File::Spec->updir));
my $root = $test_root;
is(
    $root,
    abs_path(File::Spec->catdir(dirname($test_file), File::Spec->updir)),
    'cookbook test anchors the distribution root to its absolute test-file location',
);
is(
    abs_path($INC{'Template/EmbeddedPerl.pm'}),
    File::Spec->catfile($root, qw(lib Template EmbeddedPerl.pm)),
    'cookbook test loads Template::EmbeddedPerl from its distribution root',
);
my $untyped_root = File::Spec->catdir($root, qw(examples contacts untyped));
my $untyped_lib = File::Spec->catdir($untyped_root, 'lib');

unshift @INC, $untyped_lib;
require Contacts::Untyped::App;

my $expected_html = <<'HTML';
<!doctype html>
<html>
<head>
<title>Contacts</title>
<meta name="section" content="contacts">
</head>
<body>
<section class="page">
<main>
<h1>CONTACTS</h1>
<p class="badge">2 contacts</p>
<ul>
<li data-root="Contacts" data-parent="Contacts"><strong>&lt;Ada&gt;</strong> ada@example.test</li>
<li data-root="Contacts" data-parent="Contacts"><strong>Grace</strong> grace@example.test</li>
</ul>
</main>
</section>
</body>
</html>
HTML

sub run_script {
    my ($script, $working_directory) = @_;
    my $original_directory = getcwd;

    chdir $working_directory
        or die "Cannot change to $working_directory: $!";

    my $stderr = gensym;
    my ($stdin, $stdout);
    my $pid = open3($stdin, $stdout, $stderr, $^X, $script);
    close $stdin or die "Cannot close stdin for $script: $!";
    chdir $original_directory
        or die "Cannot change back to $original_directory: $!";

    local $/;
    my $output = <$stdout>;
    my $errors = <$stderr>;
    waitpid $pid, 0;

    return ($output // '', $errors // '', $?);
}

my $untyped = Contacts::Untyped::App->new(root => $untyped_root);
is($untyped->heading_calls, 0, 'lazy heading default has not run before rendering');
is($untyped->render, $expected_html, 'untyped Contacts application renders expected HTML');
is($untyped->heading_calls, 1, 'absent heading evaluates the lazy default once');

$untyped->render(heading => 'Directory');
is($untyped->heading_calls, 1, 'explicit heading bypasses the lazy default');

my ($documented_output, $documented_errors, $documented_status) = run_script(
    File::Spec->catfile(qw(examples contacts untyped app.pl)),
    $root,
);
is($documented_status, 0, 'documented untyped command exits successfully');
is($documented_errors, '', 'documented untyped command writes no errors');
is(
    $documented_output,
    $expected_html,
    'documented untyped command renders expected HTML',
);

my ($independent_output, $independent_errors, $independent_status) = run_script(
    File::Spec->catfile($untyped_root, 'app.pl'),
    File::Spec->tmpdir,
);
is($independent_status, 0, 'untyped command exits successfully outside the distribution');
is($independent_errors, '', 'untyped command writes no errors outside the distribution');
is(
    $independent_output,
    $expected_html,
    'untyped command renders expected HTML outside the distribution',
);

my $typed_root = File::Spec->catdir($root, qw(examples contacts typed));
my $typed_lib = File::Spec->catdir($typed_root, 'lib');
unshift @INC, $typed_lib;
require Contacts::Typed::App;

my $typed = Contacts::Typed::App->new(root => $typed_root);
my $typed_html = $typed->render;
is($typed_html, $expected_html, 'typed Contacts refactor preserves exact HTML');
is($typed_html, $untyped->render, 'typed and untyped applications have output parity');

my ($typed_documented_output, $typed_documented_errors, $typed_documented_status) = run_script(
    File::Spec->catfile(qw(examples contacts typed app.pl)),
    $root,
);
is($typed_documented_status, 0, 'documented typed command exits successfully');
is($typed_documented_errors, '', 'documented typed command writes no errors');
is(
    $typed_documented_output,
    $expected_html,
    'typed command-line example renders expected HTML',
);

my ($typed_independent_output, $typed_independent_errors, $typed_independent_status) = run_script(
    File::Spec->catfile($typed_root, 'app.pl'),
    File::Spec->tmpdir,
);
is($typed_independent_status, 0, 'typed command exits successfully outside the distribution');
is($typed_independent_errors, '', 'typed command writes no errors outside the distribution');
is(
    $typed_independent_output,
    $expected_html,
    'typed command renders expected HTML outside the distribution',
);

my $root_view = $typed->root_view;
my ($page_call) = grep {
    $_->{class} eq 'Contacts::Typed::View::HTML::Page'
} @{$typed->factory_calls};
ok($page_call, 'view factory constructs the typed wrapper');
is($page_call->{view}->root, $root_view, 'wrapper receives the typed root');
is($page_call->{view}->parent, $root_view, 'wrapper receives the caller as parent');

my @item_calls = grep {
    $_->{class} eq 'Contacts::Typed::View::HTML::ContactItem'
} @{$typed->factory_calls};
is(scalar @item_calls, 2, 'view factory constructs one typed item per contact');
is($item_calls[0]{view}->root, $root_view, 'typed item receives the root view');
is($item_calls[0]{view}->parent, $root_view, 'wrapper body retains caller parent scope');
ok(
    !(grep { $_->{class} eq 'Contacts::Typed::View::HTML::Badge' } @{$typed->factory_calls}),
    'preconstructed typed child bypasses the view factory',
);

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

sub malformed_labeled_verbatim_lines {
    my ($pod) = @_;
    my @lines = split /\n/, $pod, -1;
    my @malformed;

    for my $index (0 .. $#lines) {
        next unless $lines[$index] =~ /^B<(?:Fragment:|Complete scratch file:)/;
        push @malformed, $index + 1
            unless ($lines[$index + 1] // '') eq ''
                && ($lines[$index + 2] // '') =~ /^  \S/;
    }

    return \@malformed;
}

sub pod_html {
    my ($pod) = @_;
    my $html = '';
    my $parser = Pod::Simple::HTML->new;
    $parser->output_string(\$html);
    $parser->parse_string_document($pod);
    return $html;
}

sub write_fixture {
    my ($root, $identifier, $content) = @_;
    my @parts = split m{/}, "$identifier.epl";
    my $path = File::Spec->catfile($root, @parts);
    my (undef, $directory) = File::Spec->splitpath($path);

    make_path($directory);
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";

    return $path;
}

my $dist_ini = read_file(File::Spec->catfile($root, 'dist.ini'));
like(
    $dist_ini,
    qr/^\[MetaNoIndex\]\ndirectory = examples$/m,
    'distribution metadata excludes shipped examples from PAUSE indexing',
);

SKIP: {
    my $built_meta_path = $ENV{TEMPLATE_EMBEDDED_PERL_BUILT_META};
    skip 'built META.json path was not provided', 2 unless defined $built_meta_path;

    ok(-f $built_meta_path, 'built META.json exists');
    skip 'built META.json is unavailable', 1 unless -f $built_meta_path;
    my $built_meta = decode_json(read_file($built_meta_path));
    is_deeply(
        $built_meta->{no_index},
        {directory => ['examples']},
        'built metadata excludes the examples directory from indexing',
    );
}

my $typed_app_path = File::Spec->catfile(
    $typed_root, qw(lib Contacts Typed App.pm),
);
my $typed_app_source = read_file($typed_app_path);
unlike(
    $typed_app_source,
    qr/preamble\s*=>\s*['"]use v5\.40;/,
    'typed Contacts application does not require Perl 5.40 for templates',
);

my $typed_contact_list_path = File::Spec->catfile(
    $typed_root, qw(templates html contact_list.epl),
);
my $typed_contact_list = read_file($typed_contact_list_path);
unlike(
    $typed_contact_list,
    qr/sub\s*\(\s*\$page\s*\)/,
    'typed wrapper callback avoids version-specific signature syntax',
);
like(
    $typed_contact_list,
    qr/%\s+my\s+\(\$page\)\s*=\s*\@_;/,
    'typed wrapper callback unpacks its wrapper argument portably',
);
like(
    $typed_contact_list,
    qr/display_heading\s+\$page->title/,
    'typed wrapper callback uses its wrapper argument without changing output',
);

my $tutorial_path = File::Spec->catfile(
    $root, qw(lib Template EmbeddedPerl Tutorial.pod),
);
ok(-e $tutorial_path, 'installed tutorial POD exists');

my $tutorial = -e $tutorial_path ? read_file($tutorial_path) : '';
is_deeply(
    malformed_labeled_verbatim_lines($tutorial),
    [],
    "$tutorial_path separates labeled examples from verbatim blocks",
);
like(
    pod_html($tutorial),
    qr{<p><b>Fragment: application fixture</b></p>\s*<pre>\s*sub contacts \{},
    'rendered tutorial separates the fragment label from its code block',
);
for my $heading (
    'FIRST TEMPLATE',
    'THE CONTACTS APPLICATION',
    'SMART LINES AND NAMED ARGUMENTS',
    'DEFAULTS AND LAZY DEFAULTS',
    'ESCAPING HTML SAFELY',
    'PARTIALS',
    'LAYOUTS',
    'NAMED CONTENT',
    'APPLICATION HELPERS',
    'DIAGNOSING FAILURES',
    'REUSE AND PRODUCTION CONFIGURATION',
    'CHOOSING THE NEXT ABSTRACTION',
) {
    like($tutorial, qr/^=head1 \Q$heading\E$/m, "tutorial contains $heading");
}

like(
    $tutorial,
    qr{examples/contacts/untyped/app\.pl},
    'tutorial points to the runnable untyped application',
);
like(
    $tutorial,
    qr/^=head2 Set up the checked-in example$/m,
    'tutorial starts newcomer setup with a distinct section',
);
like(
    $tutorial,
    qr{examples/contacts/\n\s+untyped/\n\s+app\.pl\n\s+lib/\n\s+Contacts/\n\s+Untyped/\n\s+App\.pm\n\s+templates/\n\s+contacts/\n\s+item\.epl\n\s+layouts/\n\s+application\.epl\n\s+pages/\n\s+contacts\.epl},
    'tutorial shows the exact checked-in untyped example tree',
);
like(
    $tutorial,
    qr/\{name => '<Ada>', email => 'ada\@example\.test'\}/,
    'tutorial shows the in-memory contact fixture',
);
for my $fragment (
    'compile diagnostic',
    'runtime diagnostic',
    'warning diagnostic',
    'file-backed diagnostic',
    'composed render diagnostic',
) {
    like(
        $tutorial,
        qr/B<Fragment: \Q$fragment\E>/,
        "tutorial labels the $fragment snippet as incomplete",
    );
}
like(
    $tutorial,
    qr/Global symbol "\$missing".*\n\s*1: first\n\s*2: <%= \$missing %>/s,
    'tutorial shows the compile message with its nearby template excerpt',
);
like(
    $tutorial,
    qr/tutorial runtime at tutorial-runtime\.epl line 2.*Render stack:\n\s*root tutorial-runtime\.epl \(tutorial-runtime\.epl\)/s,
    'tutorial shows runtime source context and its render stack',
);
like(
    $tutorial,
    qr/tutorial warning at tutorial-warning\.epl line 2\..*\n\s*1: first\n\s*2: <% warn 'tutorial warning' %>/s,
    'tutorial shows warning output beside its nearby template excerpt',
);
like(
    $tutorial,
    qr/^=head2 Diagnose a file-backed template$/m,
    'tutorial includes a file-backed failure workflow',
);
like(
    $tutorial,
    qr/from_file\('pages\/broken'\).*root pages\/broken/s,
    'tutorial ties file-backed diagnostics to a resolved source and root frame',
);
like(
    $tutorial,
    qr/^=head2 Read a composed render stack$/m,
    'tutorial includes a composed render-stack workflow',
);
like(
    $tutorial,
    qr/partial partials\/broken \(/,
    'tutorial shows the nested partial in a composed render stack',
);
unlike(
    $tutorial,
    qr/use v5\.40/,
    'tutorial does not present Perl 5.40 as a template requirement',
);

my $compile_error = eval {
    Template::EmbeddedPerl->from_string(
        "first\n<%= \$missing %>\n",
        source => 'tutorial-compile.epl',
    );
    '';
} || $@;
like(
    $compile_error,
    qr/at tutorial-compile\.epl line 2/,
    'tutorial compile failure reports its template source and line',
);
like(
    $compile_error,
    qr/1: first\n2: <%= \$missing %>/,
    'tutorial compile failure includes a nearby template excerpt',
);

my $runtime_error = eval {
    Template::EmbeddedPerl->from_string(
        "first\n<% die 'tutorial runtime' %>\n",
        source => 'tutorial-runtime.epl',
    )->render;
    '';
} || $@;
like(
    $runtime_error,
    qr/tutorial runtime at tutorial-runtime\.epl line 2/,
    'tutorial runtime failure reports its template source and line',
);
like(
    $runtime_error,
    qr/Render stack:\n  root tutorial-runtime\.epl \(tutorial-runtime\.epl\)\n\z/,
    'tutorial runtime failure includes its root render stack frame',
);

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    Template::EmbeddedPerl->from_string(
        "first\n<% warn 'tutorial warning' %>\n",
        source => 'tutorial-warning.epl',
    )->render;
}
is(
    join('', @warnings),
    "tutorial warning at tutorial-warning.epl line 2.\n",
    'tutorial warning reports its exact template source and line',
);

my $diagnostic_directory = tempdir(CLEANUP => 1);
my $file_backed_source = write_fixture(
    $diagnostic_directory,
    'pages/broken',
    "before\n<% die 'file-backed runtime' %>\n",
);
my $file_backed_error = eval {
    Template::EmbeddedPerl->new(
        directories => [$diagnostic_directory],
        smart_lines => 1,
    )->from_file('pages/broken')->render;
    '';
} || $@;
like(
    $file_backed_error,
    qr/file-backed runtime at \Q$file_backed_source\E line 2\n\n1: before\n2: <% die 'file-backed runtime' %>\n\n\nRender stack:\n  root pages\/broken \(\Q$file_backed_source\E\)\n\z/,
    'file-backed diagnostics preserve the resolved path, excerpt, and root frame',
);

my $composed_root_source = write_fixture(
    $diagnostic_directory,
    'pages/contacts',
    "before\n%= partial 'partials/broken'\nafter\n",
);
my $composed_partial_source = write_fixture(
    $diagnostic_directory,
    'partials/broken',
    "child before\n<% die 'composed runtime' %>\n",
);
my $composed_error = eval {
    Template::EmbeddedPerl->new(
        directories => [$diagnostic_directory],
        smart_lines => 1,
    )->from_file('pages/contacts')->render;
    '';
} || $@;
like(
    $composed_error,
    qr/composed runtime at \Q$composed_partial_source\E line 2.*Render stack:\n  root pages\/contacts \(\Q$composed_root_source\E\)\n  partial partials\/broken \(\Q$composed_partial_source\E\)\n\z/s,
    'composed diagnostics retain ordered root and partial render-stack frames',
);

my $cookbook_path = File::Spec->catfile(
    $root, qw(lib Template EmbeddedPerl Cookbook.pod),
);
ok(-e $cookbook_path, 'installed cookbook POD exists');

my $cookbook = -e $cookbook_path ? read_file($cookbook_path) : '';
is_deeply(
    malformed_labeled_verbatim_lines($cookbook),
    [],
    "$cookbook_path separates labeled examples from verbatim blocks",
);
for my $heading (
    'WHICH DOCUMENT SHOULD I READ?',
    'RENDERING AND LOADING',
    'TEMPLATE INPUTS',
    'OUTPUT AND ESCAPING',
    'COMPOSITION',
    'SYNTAX AND FORMATTING',
    'HELPERS AND CONFIGURATION',
    'TESTING AND TROUBLESHOOTING',
) {
    like($cookbook, qr/^=head1 \Q$heading\E$/m, "cookbook contains $heading");
}

like(
    $cookbook,
    qr/L<Template::EmbeddedPerl::Tutorial>/,
    'cookbook links newcomers to the tutorial',
);
like(
    $cookbook,
    qr/L<Template::EmbeddedPerl::Cookbook::TypedViews>/,
    'cookbook links framework authors to typed views',
);

my $typed_views_path = File::Spec->catfile(
    $root, qw(lib Template EmbeddedPerl Cookbook TypedViews.pod),
);
ok(-e $typed_views_path, 'installed typed-view cookbook POD exists');

my $typed_views = -e $typed_views_path ? read_file($typed_views_path) : '';
is_deeply(
    malformed_labeled_verbatim_lines($typed_views),
    [],
    "$typed_views_path separates labeled examples from verbatim blocks",
);
for my $heading (
    'WHY INTRODUCE A TYPED VIEW?',
    'THE ROOT VIEW',
    'TYPED CHILD VIEWS',
    'WRAPPER VIEWS',
    'INJECTING ROOT AND PARENT',
    'COMPOSING THE VIEW TREE',
    'CHOOSING BETWEEN BOTH DESIGNS',
) {
    like($typed_views, qr/^=head1 \Q$heading\E$/m, "typed-view cookbook contains $heading");
}

like(
    $typed_views,
    qr/B<Experimental:> Typed view support, including C<render_view>, C<view>, C<view_namespace>, and C<view_factory>, may change as real-world integration needs become clearer\./,
    'typed-view POD carries the exact experimental notice',
);
unlike(
    $typed_views,
    qr/sub\s*\(\s*\$page\s*\)/,
    'typed-view POD avoids version-specific callback signature syntax',
);
like(
    $typed_views,
    qr/sub \{\n  % my \(\$page\) = \@_;.*display_heading \$page->title/s,
    'typed-view POD shows portable callback unpacking and meaningful wrapper use',
);
unlike(
    $typed_views,
    qr/Task 4(?: parity)? assertions/,
    'typed-view POD does not refer readers to internal task assertions',
);
like(
    $typed_views,
    qr/C<t\/cookbook_examples\.t>.*wrapper.*root.*parent/s,
    'typed-view POD points readers to the checked-in wrapper and identity tests',
);
unlike(
    $typed_views,
    qr/Both designs use the same templates, helpers, layouts, named content, escaping, and render engine\./,
    'typed-view POD does not claim the examples share one template tree or engine',
);
like(
    $typed_views,
    qr/equivalent separate template trees\s+and engine instances/,
    'typed-view POD accurately distinguishes the independent example implementations',
);

my $module = read_file(File::Spec->catfile(
    $root, qw(lib Template EmbeddedPerl.pm),
));
unlike(
    $module,
    qr{docs/cookbook/typed-views\.md},
    'main module POD has no stale typed-view Markdown link',
);
like(
    $module,
    qr/L<Template::EmbeddedPerl::Cookbook::TypedViews>/,
    'main module POD links to the installed typed-view cookbook',
);

ok(
    !-e File::Spec->catfile($root, qw(docs cookbook typed-views.md)),
    'old Markdown cookbook is removed after migration',
);

my $readme = read_file(File::Spec->catfile($root, 'README.mkdn'));
for my $document (
    'Template::EmbeddedPerl::Tutorial',
    'Template::EmbeddedPerl::Cookbook',
    'Template::EmbeddedPerl::Cookbook::TypedViews',
) {
    like($readme, qr/perldoc \Q$document\E/, "README points to $document with perldoc");
}
unlike(
    $readme,
    qr{docs/cookbook/typed-views\.md},
    'README no longer links to the pruned Markdown cookbook',
);

for my $relative (
    'examples/contacts/untyped/app.pl',
    'examples/contacts/untyped/lib/Contacts/Untyped/App.pm',
    'examples/contacts/untyped/templates/pages/contacts.epl',
    'examples/contacts/untyped/templates/contacts/item.epl',
    'examples/contacts/untyped/templates/layouts/application.epl',
    'examples/contacts/typed/app.pl',
    'examples/contacts/typed/lib/Contacts/Typed/App.pm',
    'examples/contacts/typed/lib/Contacts/Typed/View/HTML/ContactList.pm',
    'examples/contacts/typed/lib/Contacts/Typed/View/HTML/Page.pm',
    'examples/contacts/typed/lib/Contacts/Typed/View/HTML/ContactItem.pm',
    'examples/contacts/typed/lib/Contacts/Typed/View/HTML/Badge.pm',
    'examples/contacts/typed/templates/html/contact_list.epl',
    'examples/contacts/typed/templates/html/page.epl',
    'examples/contacts/typed/templates/contacts/item.epl',
    'examples/contacts/typed/templates/contacts/badge.epl',
    'examples/contacts/typed/templates/layouts/application.epl',
) {
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    ok(-e $path, "cookbook reference exists: $relative");
}

done_testing;
