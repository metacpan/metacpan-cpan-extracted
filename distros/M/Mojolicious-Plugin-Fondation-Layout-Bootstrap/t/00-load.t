use strict;
use warnings;
use Test::More;
use Mojolicious;

use_ok 'Mojolicious::Plugin::Fondation::Layout::Bootstrap';
isa_ok 'Mojolicious::Plugin::Fondation::Layout::Bootstrap', 'Mojolicious::Plugin';

# ── main.html.ep: head/css zone after Bootstrap, no hardcoded theme link ──

use Mojo::Base -signatures;
use FindBin;

my $share = "$FindBin::Bin/../share";

subtest 'main layout renders the head/css zone after Bootstrap' => sub {
    my $app = Mojolicious->new;
    push @{$app->renderer->paths}, "$share/templates";

    $app->helper(csrf_token => sub { 'stub-csrf' });
    $app->helper(has_helper  => sub ($c, $name) { 0 });
    $app->helper(l           => sub ($c, $key)  { $key });
    $app->helper(i18n_js     => sub { '' });
    $app->helper(asset       => sub ($c, $name) {
        $name =~ /\.css$/ ? qq{<link rel="stylesheet" href="/asset/$name">}
                          : qq{<script src="/asset/$name"></script>};
    });
    $app->helper(render_zone => sub ($c, $zone) {
        $zone eq 'head/css' ? '<link rel="stylesheet" href="/css/zone-head-css.css">' : '';
    });

    my $html = $app->build_controller->render_to_string(
        template => 'layouts/main',
        layout   => undef,
    );

    my $app_css = index $html, '/asset/app.css';
    my $zone    = index $html, 'zone-head-css.css';
    ok($app_css >= 0 && $zone > $app_css, 'head/css zone rendered after app.css');

    unlike($html, qr{org-theme\.css}, 'no hardcoded org-theme.css link in main layout');
};

done_testing;
