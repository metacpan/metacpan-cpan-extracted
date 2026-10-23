use Mojo::Base -strict, -signatures;
use Test::Mojo;
use Test::More;
use Mojo::File qw(curfile);
use Mojolicious;

my $files = curfile->sibling('files')->to_string;
my $templates = curfile->sibling('templates')->to_string;

sub tester(%config) {
    my $app = Mojolicious->new(mode => 'test');
    $app->static->paths([$files]);
    $app->renderer->paths([$templates]);
    $app->plugin(WebComponent => \%config);
    $app->routes->get('/helper' => sub ($c) {
        $c->render(text => join "\n",
            $c->component('my-component', {requestId => 'r'}),
            $c->component('my-component', {requestId => 'r', template => 'notes'}),
            $c->component('my-component', {requestId => 'r'}));
    });
    $app->routes->get('/page/:id' => sub ($c) {
        $c->render(text => $c->component('my-component', {requestId => 'r'}));
    });
    return Test::Mojo->new($app);
}

# the first request to a fresh app serves the script (route exists after register)
my $t = tester();
$t->get_ok('/component/x/my-component.js')->status_is(200)
    ->header_like('Content-Type' => qr{javascript})
    ->content_like(qr{This is a custom web component});

# a catch-all route declared before the plugin loads does not shadow the script route
{
    my $app = Mojolicious->new(mode => 'test');
    $app->static->paths([$files]);
    $app->renderer->paths([$templates]);
    $app->routes->any('/*any' => sub ($c) { $c->render(text => 'catchall') });
    $app->plugin('WebComponent');
    Test::Mojo->new($app)->get_ok('/component/x/my-component.js')->status_is(200)
        ->content_like(qr{custom web component});
}

# names that leave the component folder or are not .js are not served
for my $name (qw(..%2f..%2f..%2fsecret.js %2e%2e%2f%2e%2e%2f%2e%2e%2fsecret.js sub%2fmy-component.js my-component.txt .hidden.js)) {
    $t->get_ok("/component/x/$name")->status_is(404)->content_unlike(qr{SECRET-MARKER});
}

# a component below a sub folder is served with its own template
$t->get_ok(q{/component/x/sub/sub-box.js})->status_is(200)->content_like(qr{<p>sub template});
$t->get_ok(q{/component/x/sub/..%2f..%2fsecret.js})->status_is(404)->content_unlike(qr{SECRET-MARKER});

# unknown component is a 404, not a 500
$t->get_ok('/component/x/nope.js')->status_is(404);

# the template is one string literal: backtick, ${} and backslash stay data
$t->get_ok('/component/x/tick-box.js?template=tick-box')->status_is(200)
    ->content_unlike(qr{innerHTML = `})->content_like(qr{innerHTML = "});
SKIP: {
    my $node = `node --version 2>/dev/null`;
    skip 'node not installed', 1 unless $node;
    my $js = $t->tx->res->text;
    require File::Temp;
    my ($tfh, $tfile) = File::Temp::tempfile(SUFFIX => '.js', UNLINK => 1);
    binmode $tfh, ':utf8';
    print $tfh $js;
    close $tfh;
    is system('node', '--check', $tfile), 0, 'component script with backtick and backslash template parses';
}

$t->get_ok('/component/x/echo-box.js?template=echo-box&q=${alert(1)}%60;alert(1);%60')->status_is(200)
    ->content_unlike(qr{innerHTML = `})->content_like(qr{innerHTML = "});

# a template name outside the allowlist is not echoed or rendered
$t->get_ok('/component/x/my-component.js?template=%60;alert(1);%60')->status_is(200)
    ->content_unlike(qr{alert\(1\)})->content_like(qr{template not found});
$t->get_ok('/component/x/my-component.js?template=..%2f..%2fdefault%2findex')->status_is(200)
    ->content_unlike(qr{dashboard})->content_like(qr{template not found});
$t->get_ok('/component/x/my-component.js?template=missing')->status_is(200)
    ->content_like(qr{components/missing template not found});

# a non-ASCII template name is looked up, not rejected as invalid
$t->get_ok(q{/component/x/my-component.js?template=caf%C3%A9})->status_is(200)
    ->content_like(qr{template not found})->content_like(qr{components/café});

# template names that merely contain f, no or 0 are still templates
for my $name (qw(notes footer 10-grid)) {
    $t->get_ok("/component/x/my-component.js?template=$name")->status_is(200)
        ->content_like(qr{<p>\Q$name\E template});
}
# and the whole-value switches skip templating
for my $off (qw(false f no 0 FALSE)) {
    $t->get_ok("/component/x/my-component.js?template=$off")->status_is(200)
        ->content_unlike(qr{tmpl\.innerHTML});
}

# non-ASCII round-trips in the script file and in the template
$t->get_ok('/component/x/utf-box.js')->status_is(200)->content_type_like(qr{charset=UTF-8}i)
    ->content_like(qr{this\.label = 'café €'})->content_like(qr{café € in template});

# helper urls: no callback, no route captures, option scoped to its own call
$t->get_ok('/helper')->status_is(200);
my @urls = split /\n/, $t->tx->res->text;
is scalar(@urls), 3, 'three script tags';
unlike $urls[0], qr{cb=|CODE}, 'no callback in url';
unlike $urls[1], qr{CODE}, 'no callback in url';
like $urls[1], qr{template=notes}, 'option applies to its own call';
unlike $urls[2], qr{template}, 'option does not leak to the next call';
$t->get_ok('/page/7?a=1')->status_is(200)
    ->content_like(qr{a=1})->content_unlike(qr{CODE|cb=|req=|component=});

# the helper refuses a name the route would never serve
for my $bad (q{../x}, q{.hidden}, q{a b}, q{x/..}) {
    eval { $t->app->build_controller->component($bad) };
    like $@, qr{invalid component name}, "component '$bad' dies";
}
ok eval { $t->app->build_controller->component(q{sub/sub-box}); 1 }, q{subfolder name is accepted};

# a route of the app under the component path is not reached once the plugin is registered
{
    my $app = Mojolicious->new(mode => q{test});
    $app->static->paths([$files]);
    $app->routes->get(q{/component/x/my-component.js} => sub ($c) { $c->render(text => q{mine}) });
    $app->plugin(q{WebComponent});
    Test::Mojo->new($app)->get_ok(q{/component/x/my-component.js})->content_unlike(qr{^mine\z});
}

# config keys: path, javascript_path, template_path
my $alt = tester(path => '/wc', javascript_path => 'alt', template_path => 'alt-tpl');
$alt->get_ok('/wc/x/alt-box.js')->status_is(200)->content_like(qr{alt template});
$alt->get_ok('/component/x/alt-box.js')->status_is(404);
is $alt->app->component('alt-box', {requestId => 'q'}),
    "<script src='/wc/q/alt-box.js'></script>", 'helper uses the configured path';

# the helper name is configurable
{
    my $app = Mojolicious->new(mode => q{test});
    $app->static->paths([$files]);
    $app->renderer->paths([$templates]);
    $app->plugin(WebComponent => {helper => q{wc}});
    is $app->wc(q{my-component}, {requestId => q{q}}),
        "<script src='/component/q/my-component.js'></script>", q{helper name from config};
    ok !$app->renderer->helpers->{component}, q{default helper name is not registered};
    Test::Mojo->new($app)->get_ok(q{/component/x/my-component.js})->status_is(200)
        ->content_like(qr{custom web component});
}

# template lookup finds DATA templates and templates of any registered handler, without a warmup
{
    my $app = Mojolicious->new(mode => q{test});
    $app->static->paths([$files]);
    $app->renderer->paths([$templates]);
    $app->renderer->classes([q{main}]);
    $app->renderer->add_handler(up => sub ($r, $c, $output, $options) {
        $$output = Mojo::File->new($r->template_path($options))->slurp;
    });
    $app->plugin(q{WebComponent});
    my $t = Test::Mojo->new($app);
    $t->get_ok(q{/component/x/my-component.js?template=data-box})->status_is(200)
        ->content_like(qr{<p>from data section});
    $t->get_ok(q{/component/x/my-component.js?template=custom})->status_is(200)
        ->content_like(qr{<p>handled by up});
    $t->get_ok(q{/component/x/my-component.js?template=missing})->status_is(200)
        ->content_like(qr{missing template not found});
}

# the url carries a checksum of the served content: stable across requests and apps,
# new when the script, the template or a parameter changes
{
    my $url = sub ($app, $name, $opts = {}, $query = '') {
        my $c = $app->build_controller;
        $c->req->url->parse($query) if length $query;
        my $tag = $c->component($name, $opts);
        $tag =~ m{src='(/component/([0-9a-f]{40})/[^']+)'} or return;
        return wantarray ? ($1, $2) : $1;
    };
    my $app1 = tester()->app;
    my $app2 = tester()->app;
    my ($first, $sum) = $url->($app1, 'my-component');
    ok $sum, 'url has a 40 character checksum';
    is scalar $url->($app1, 'my-component'), $first, 'same url on the next request';
    is scalar $url->($app2, 'my-component'), $first, 'same url from another app instance';
    my (undef, $other) = $url->($app1, 'my-component', {template => 'notes'});
    isnt $other, $sum, 'other template, other checksum';
    # echo-box prints its q parameter, so q changes what is served
    my (undef, $q1) = $url->($app1, 'echo-box', {}, '/?q=one');
    (undef, $other) = $url->($app1, 'echo-box', {}, '/?q=two');
    isnt $other, $q1, 'a parameter the template uses, other checksum';
    (undef, $other) = $url->($app1, 'my-component', {}, '/?who=you');
    is $other, $sum, 'a parameter nothing uses, same checksum';
    (undef, $other) = $url->($app1, 'utf-box');
    isnt $other, $sum, 'other component, other checksum';

    # the query string is in a fixed order, or its url would differ from one process to the next
    like scalar $url->($app1, 'my-component', {}, '/?d=4&b=2&e=5&a=1&c=3'), qr{\?a=1&b=2&c=3&d=4&e=5\z},
        'parameters are sorted';

    # an edit of the script or of the template changes the checksum
    require File::Temp;
    my $dir = File::Temp->newdir;
    my $public = Mojo::File->new($dir, 'public');
    my $tpl = Mojo::File->new($dir, 'templates');
    # Mojo::File spew is not in the oldest supported Mojolicious
    my $write = sub ($file, $text) { open my $fh, '>', $file or die "$file: $!"; print $fh $text; close $fh };
    $public->child(qw(assets js components))->make_path;
    $tpl->child('components')->make_path;
    $write->($public->child(qw(assets js components edit-box.js)), "// v1\nlet tmpl;\n");
    $write->($tpl->child(qw(components edit-box.html.ep)), "<p>one</p>\n");
    my $app = Mojolicious->new(mode => 'test');
    $app->static->paths([$public->to_string]);
    $app->renderer->paths([$tpl->to_string]);
    $app->renderer->cache->max_keys(0);
    $app->plugin('WebComponent');
    my $v1 = $url->($app, 'edit-box');
    $write->($tpl->child(qw(components edit-box.html.ep)), "<p>two</p>\n");
    my $v2 = $url->($app, 'edit-box');
    isnt $v2, $v1, 'edited template, new url';
    $write->($public->child(qw(assets js components edit-box.js)), "// v2\nlet tmpl;\n");
    isnt scalar $url->($app, 'edit-box'), $v2, 'edited script, new url';
}

# cache headers: immutable for a matching checksum, no-cache otherwise
{
    my $t = tester();
    my $url = $t->app->build_controller->component('my-component') =~ m{src='([^']+)'} && $1;
    $t->get_ok($url)->status_is(200)
        ->header_is('Cache-Control' => 'public, max-age=31536000, immutable');
    $t->head_ok($url)->status_is(200)
        ->header_is('Cache-Control' => 'public, max-age=31536000, immutable');
    $t->get_ok('/component/' . ('0' x 40) . '/my-component.js')->status_is(200)
        ->header_is('Cache-Control' => 'no-cache')->content_like(qr{custom web component});
    my $pinned = $t->app->build_controller->component('my-component', {requestId => 'v1'}) =~ m{src='([^']+)'} && $1;
    is $pinned, '/component/v1/my-component.js', 'requestId overrides the checksum';
    $t->get_ok($pinned)->status_is(200)->header_is('Cache-Control' => 'no-cache');
    $t->get_ok('/component/x/nope.js')->status_is(404)
        ->header_isnt('Cache-Control' => 'public, max-age=31536000, immutable');
}

# a template that cannot render does not break the page that holds the helper
{
    my $app = Mojolicious->new(mode => 'test');
    $app->static->paths([$files]);
    $app->renderer->paths([$templates]);
    $app->plugin('WebComponent');
    $app->routes->get('/page' => sub ($c) {
        $c->render(text => $c->component('my-component', {template => 'broken'}));
    });
    Test::Mojo->new($app)->get_ok('/page')->status_is(200)
        ->content_like(qr{/component/unavailable/my-component\.js});
}

# a script without the `let tmpl;` marker gets the template just before its appendChild line
$t->get_ok('/component/x/append-box.js')->status_is(200)
    ->content_like(qr{tmpl\.innerHTML = "<p>append template</p>\\n";\s+shadowRoot\.appendChild\(tmpl\.content});

# the last of several template parameters wins
$t->get_ok('/component/x/my-component.js?template=notes&template=footer')->status_is(200)
    ->content_like(qr{<p>footer template</p>})->content_unlike(qr{notes template});

# the helper takes the name with or without .js, and template => undef switches templating off
{
    my $c = $t->app->build_controller;
    is "" . $c->component('my-component.js'), "" . $c->component('my-component'), 'the .js suffix is optional';
    my $off = "" . $c->component('my-component', {template => undef});
    like $off, qr{\?template=false'}, 'template => undef is carried as template=false';
    my ($src) = $off =~ m{src='([^']+)'};
    $t->get_ok($src)->status_is(200)->content_unlike(qr{tmpl\.innerHTML});
}

# values the helper writes into the tag cannot end the attribute or double a slash
{
    my $tag = sub ($base, $opts = {}) {
        my $app = Mojolicious->new(mode => 'test');
        $app->static->paths([$files]);
        $app->renderer->paths([$templates]);
        $app->plugin('WebComponent');
        my $c = $app->build_controller;
        $c->req->url->base->path->parse($base);
        return "" . $c->component('my-component', $opts);
    };
    my $sum = qr{[0-9a-f]{40}};
    like $tag->(q{/x'onload='y}), qr{\A<script src='/x&#39;onload=&#39;y/component/$sum/my-component\.js'></script>\z},
        'a quote in the base path is escaped';
    like $tag->('/prefix'), qr{\A<script src='/prefix/component/$sum/}, 'plain base path unchanged';
    like $tag->('/prefix/'), qr{\A<script src='/prefix/component/$sum/}, 'trailing slash of the base path is dropped';
    like $tag->('', {requestId => q{a'b c}}), qr{\A<script src='/component/a%27b%20c/my-component\.js'></script>\z},
        'requestId is percent-encoded';
    like $tag->('', {requestId => "\x{4e2d}"}), qr{/component/%E4%B8%AD/}, 'requestId is encoded as UTF-8';
    like $tag->('', {requestId => '0'}), qr{/component/0/}, 'a requestId of 0 is used';
    eval { $tag->('', {requestId => 'a/b'}) };
    like $@, qr{invalid requestId}, 'a requestId with a slash cannot be served and is refused';
    like $tag->('', {requestId => 'v2-test.1'}), qr{/component/v2-test\.1/}, 'a plain requestId is unchanged';

    # an encoded requestId is a url the route matches
    my $t = tester();
    $t->get_ok('/component/a%27b%20c/my-component.js')->status_is(200)->header_is('Cache-Control' => 'no-cache');
    $t->get_ok('/component/%E4%B8%AD/my-component.js')->status_is(200);
}

# registering twice with a custom helper name keeps one helper and one route
{
    my $app = Mojolicious->new(mode => 'test');
    my @log;
    $app->log->level('debug')->on(message => sub ($log, $level, @lines) { push @log, "$level: @lines" });
    $app->plugin(WebComponent => {helper => 'wc'});
    my $count = sub { scalar grep { ($_->name // '') eq 'webcomponent' } @{$app->routes->children} };
    is $count->(), 1, 'one route after the first registration';
    $app->plugin(WebComponent => {helper => 'wc'});
    is $count->(), 1, 'still one route after the second';
    ok scalar(grep { /Helper wc\(\) is already registered/ } @log), 'the second registration is logged';
}

# the helper name must be a plain word
for my $bad (q{a b}, q{x/y}, q{}, q{a-b}) {
    my $app = Mojolicious->new(mode => 'test');
    eval { $app->plugin(WebComponent => {helper => $bad}) };
    like $@, qr{invalid helper name}, "helper '$bad' is refused";
}

# a script that is not valid UTF-8 is a server error, and a missing one is logged
{
    require File::Temp;
    my $dir = File::Temp->newdir;
    my $dest = Mojo::File->new($dir, qw(assets js components))->make_path;
    open my $fh, '>:raw', $dest->child('bad-box.js') or die $!;
    print $fh "// \xff\xfe not utf-8\nlet tmpl;\n";
    close $fh;
    my $app = Mojolicious->new(mode => 'test');
    my @log;
    $app->log->level('debug')->on(message => sub ($log, $level, @lines) { push @log, "$level: @lines" });
    $app->static->paths(["$dir"]);
    $app->renderer->paths([$templates]);
    $app->plugin('WebComponent');
    my $t = Test::Mojo->new($app);
    $t->get_ok('/component/x/bad-box.js')->status_is(500);
    my $c = $app->build_controller;
    @log = ();
    $c->component('no-such-box');
    ok scalar(grep { /no-such-box\.js/ && /not found/ } @log), 'a missing script is logged';
}

done_testing;

__DATA__

@@ components/data-box.html.ep
<p>from data section</p>
