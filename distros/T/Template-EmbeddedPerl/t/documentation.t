use strict;
use warnings;

use File::Path 'make_path';
use File::Spec;
use File::Temp 'tempdir';
use Moo;
use Test::Most;
use Template::EmbeddedPerl;

my $cookbook = File::Spec->catfile(
    qw(lib Template EmbeddedPerl Cookbook TypedViews.pod),
);
ok(-e $cookbook, 'the installed typed-view cookbook is present');

sub read_document {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

sub markdown_notice_follows_heading {
    my ($path, $heading, $expected) = @_;
    my $content = read_document($path);
    $content =~ /^\Q$heading\E[ \t]*\R((?:[ \t]*\R)*(?:>[^\r\n]*(?:\R|$))+)/m
        or return;
    my $notice = $1;
    $notice =~ s/^>[ \t]?//gm;
    $notice =~ s/\s+/ /g;
    $notice =~ s/^\s+|\s+$//g;
    return $notice eq $expected;
}

sub pod_notice_follows_heading {
    my ($path, $heading, $expected) = @_;
    my $content = read_document($path);
    $content =~ /^\Q$heading\E[ \t]*\R(?:[ \t]*\R)*([^\r\n]*(?:\R[^\r\n]+)*)/m
        or return;
    my $notice = $1;
    $notice =~ s/\s+/ /g;
    $notice =~ s/^\s+|\s+$//g;
    return $notice eq $expected;
}

my $markdown_notice = q{**Experimental:** Typed view support, including }
    . q{`render_view`, `view`, `view_namespace`, and `view_factory`, may change }
    . q{as real-world integration needs become clearer.};
my $pod_notice = q{B<Experimental:> Typed view support, including }
    . q{C<render_view>, C<view>, C<view_namespace>, and C<view_factory>, may change }
    . q{as real-world integration needs become clearer.};

ok(
    markdown_notice_follows_heading(
        'README.mkdn',
        '## render\\_view',
        $markdown_notice,
    ),
    'README marks typed views as experimental',
);

ok(
    pod_notice_follows_heading(
        $cookbook,
        '=head1 DESCRIPTION',
        $pod_notice,
    ),
    'cookbook marks typed views as experimental',
);

ok(
    pod_notice_follows_heading(
        File::Spec->catfile(qw(lib Template EmbeddedPerl.pm)),
        '=head2 render_view',
        $pod_notice,
    ),
    'module POD marks typed views as experimental',
);

sub write_template {
    my ($directory, $identifier, $content) = @_;
    my @parts = split m{/}, $identifier;
    my $file = pop @parts;
    my $path = File::Spec->catfile($directory, @parts, "$file.epl");
    my ($volume, $directories) = File::Spec->splitpath($path);
    make_path($directories);
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
}

{
    package Documentation::View::HTMLPage::ContactList;
    use Moo;

    has title => (is => 'ro', required => 1);
    has prebuilt_item => (is => 'ro', required => 1);
}

{
    package Documentation::View::HTMLPage::Shell;
    use Moo;

    has title => (is => 'ro', required => 1);
    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);
}

{
    package Documentation::View::HTML::Navbar;
    use Moo;

    has active => (is => 'ro', required => 1);
    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);

    sub template { 'components/navbar' }
}

{
    package Documentation::View::HTML::ContactItem;
    use Moo;

    has label => (is => 'ro', required => 1);
    has root => (is => 'ro');
    has parent => (is => 'ro');

    sub template { 'components/contact_item' }
}

{
    package Documentation::View::HTML::ZeroFactoryPage;
    use Moo;

    has title => (is => 'ro', required => 1);
}

{
    package Documentation::View::HTML::ZeroFactoryItem;
    use Moo;

    has label => (is => 'ro', required => 1);

    sub template { 'components/zero_factory_item' }
}

{
    package Documentation::View::HTML::HelperMatrix;
    use Moo;

    has title => (is => 'ro', required => 1);
}

{
    package Documentation::View::HTML::HelperWrapper;
    use Moo;

    has title => (is => 'ro', required => 1);
    has root => (is => 'ro', required => 1);
    has parent => (is => 'ro', required => 1);
}

my $temporary = tempdir(CLEANUP => 1);
my $first = File::Spec->catdir($temporary, 'first');
my $second = File::Spec->catdir($temporary, 'second');

write_template($first, 'pages/index', <<'EPL');
% args $name, $title = 'Directory One', $subtitle = sub {
%   record_default($name);
%   return "Welcome, $name";
% }
% layout 'layouts/application', title => $title
<%= content_for 'css', sub { '<meta name="theme" content="first">' } %>
<%= content_replace 'css', sub { '<link href="/contacts.css">' } %>
<main><h1><%= $subtitle %></h1><ul><%= partial 'contacts/item', name => $name %></ul></main>
EPL

write_template($first, 'layouts/application', <<'EPL');
% args $title = 'Default'
<!doctype html><title><%= $title %></title><head>
% if (has_content 'css') {
<%= yield 'css' %>
% } else {
<meta name="theme" content="default">
% }
</head><body><%= yield %></body>
EPL

write_template($first, 'contacts/item', <<'EPL');
% args $name
<li><%= $name %></li>
EPL

write_template($second, 'pages/index', '<p>second directory</p>');

write_template($first, 'html_page/contact_list', <<'EPL');
<section class="contacts" data-source="convention"><%= view 'HTML::Navbar', active => 'contacts' %><%= view $self->prebuilt_item %><%= view 'HTML::ContactItem', label => '<Logical>' %><%= view 'HTMLPage::Shell', title => "Shell " . $self->title, sub { %><p>body-self=<%= $self->title %>; callback=<%= $_[0]->title %></p><% } %></section>
EPL

write_template($first, 'html_page/shell', <<'EPL');
<article data-source="convention" data-wrapper="<%= $self->title %>"><h1><%= $self->title %></h1><%= yield %><%= view 'HTML::Navbar', active => 'wrapper' %></article>
EPL

write_template($first, 'components/navbar', <<'EPL');
<nav data-source="object"><%= $self->active %> root=<%= $self->root->title %> parent=<%= $self->parent->title %></nav>
EPL

write_template($first, 'components/contact_item', <<'EPL');
<li class="contact" data-source="object"><%= typed_label $self->label %> root=<%= $self->root ? $self->root->title : 'none' %> parent=<%= $self->parent ? $self->parent->title : 'none' %></li>
EPL

write_template($first, 'html/zero_factory_page', <<'EPL');
<section class="zero-factory"><%= view 'HTML::ZeroFactoryItem', label => $self->title %></section>
EPL

write_template($first, 'components/zero_factory_item', <<'EPL');
<span class="zero-factory-item"><%= $self->label %></span>
EPL

write_template(
    $first,
    'html/helper_matrix',
    q{<% layout 'typed/helper_layout' %><root><%= typed_label 'root:' . $self->title %>|<%= partial 'typed/helper_partial' %>|<%= view 'HTML::HelperWrapper', title => 'wrapped', sub { %><%= typed_label 'body:' . $self->title %><% } %></root>},
);
write_template(
    $first,
    'html/helper_wrapper',
    q{<wrapper><%= typed_label 'wrapper:' . $self->title %>|<%= yield %></wrapper>},
);
write_template(
    $first,
    'typed/helper_partial',
    q{<partial><%= typed_label 'partial:' . $self->title %></partial>},
);
write_template(
    $first,
    'typed/helper_layout',
    q{<layout><%= typed_label 'layout:' . $self->title %>|<%= yield %></layout>},
);

my $lazy_default_calls = 0;
my $untyped_engine = Template::EmbeddedPerl->new(
    directories => [$first, $second],
    auto_escape => 1,
    smart_lines => 1,
    helpers => {
        record_default => sub { $lazy_default_calls++ },
    },
);

is(
    $untyped_engine->from_file('pages/index')->render(name => '<Ada>'),
    "<!doctype html><title>Directory One</title><head>\n<link href=\"/contacts.css\">\n</head><body>\n\n"
        . "<main><h1>Welcome, &lt;Ada&gt;</h1><ul><li>&lt;Ada&gt;</li>\n</ul></main>\n</body>\n",
    'untyped page uses the first directory, content replacement, has_content, layout, and a once-escaped partial',
);
is($lazy_default_calls, 1, 'an absent lazy argument is evaluated once');
$untyped_engine->from_file('pages/index')->render(
    name => 'Ada',
    title => 'Provided',
    subtitle => undef,
);
is($lazy_default_calls, 1, 'an explicit undef does not evaluate a lazy argument default');

my $zero_factory_engine = Template::EmbeddedPerl->new(
    directories => [$first, $second],
    auto_escape => 1,
    smart_lines => 1,
    view_namespace => 'Documentation::View',
);

is(
    $zero_factory_engine->render_view(
        Documentation::View::HTML::ZeroFactoryPage->new(title => '<Simple>'),
    ),
    "<section class=\"zero-factory\"><span class=\"zero-factory-item\">&lt;Simple&gt;</span>\n</section>\n",
    'logical children without a view factory receive only their explicitly supplied template arguments',
);

my @factory_calls;
my $typed_engine = Template::EmbeddedPerl->new(
    directories => [$first, $second],
    auto_escape => 1,
    smart_lines => 1,
    view_namespace => 'Documentation::View',
    helpers => {
        typed_label => sub {
            my ($engine, $label) = @_;
            return uc $label;
        },
    },
    view_factory => sub {
        my ($class, $args, $context) = @_;
        my $view = $class->new(
            %$args,
            root => $context->root_view,
            parent => $context->view,
        );
        push @factory_calls, {
            class => $class,
            args => {%$args},
            context => $context,
            view => $view,
        };
        return $view;
    },
);

is(
    $typed_engine->render_view(
        Documentation::View::HTML::HelperMatrix->new(title => 'Root'),
    ),
    '<layout>LAYOUT:ROOT|<root>ROOT:ROOT|<partial>PARTIAL:ROOT</partial>|'
        . '<wrapper>WRAPPER:WRAPPED|BODY:ROOT</wrapper></root></layout>',
    'helpers work with typed self in roots, partials, layouts, wrapper bodies, and wrapper templates',
);

my $root = Documentation::View::HTMLPage::ContactList->new(
    title => 'Contacts',
    prebuilt_item => Documentation::View::HTML::ContactItem->new(
        label => '<Prebuilt>',
    ),
);

is(
    $typed_engine->render_view($root),
    "<section class=\"contacts\" data-source=\"convention\"><nav data-source=\"object\">contacts root=Contacts parent=Contacts</nav>\n"
        . "<li class=\"contact\" data-source=\"object\">&lt;PREBUILT&gt; root=none parent=none</li>\n"
        . "<li class=\"contact\" data-source=\"object\">&lt;LOGICAL&gt; root=Contacts parent=Contacts</li>\n"
        . "<article data-source=\"convention\" data-wrapper=\"Shell Contacts\"><h1>Shell Contacts</h1><p>body-self=Contacts; callback=Shell Contacts</p>"
        . "<nav data-source=\"object\">wrapper root=Contacts parent=Shell Contacts</nav>\n</article>\n</section>\n",
    'render_view and nested view apply object template and convention precedence',
);

my ($root_navbar) = grep {
    $_->{class} eq 'Documentation::View::HTML::Navbar'
        && $_->{view}->active eq 'contacts'
} @factory_calls;
my ($wrapper) = grep {
    $_->{class} eq 'Documentation::View::HTMLPage::Shell'
} @factory_calls;
my ($wrapper_navbar) = grep {
    $_->{class} eq 'Documentation::View::HTML::Navbar'
        && $_->{view}->active eq 'wrapper'
} @factory_calls;

is($root_navbar->{view}->root, $root, 'logical root child receives the typed root identity');
is($root_navbar->{view}->parent, $root, 'logical root child receives the caller as parent');
is($wrapper->{view}->root, $root, 'logical wrapper receives the typed root identity');
is($wrapper->{view}->parent, $root, 'logical wrapper receives the body caller as parent');
is($wrapper_navbar->{context}->view, $wrapper->{view}, 'wrapper template scopes nested view construction to the wrapper');
is($wrapper_navbar->{view}->parent, $wrapper->{view}, 'wrapper template child receives the wrapper as parent');
ok(
    !(grep { $_->{view} == $root->prebuilt_item } @factory_calls),
    'preconstructed child bypasses the view factory',
);

done_testing;
