use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'Iconify';

my $t = Test::Mojo->new;

get '/icon_1' => 'icon_1';
$t->get_ok('/icon_1')->status_is(200)->content_like(qr{<span class="iconify" data-icon="logos:perl"></span>});

get '/icon_2' => 'icon_2';
$t->get_ok('/icon_2')->status_is(200)->element_exists('[data-icon]')->element_exists('[data-height]')
    ->element_exists('[data-width]');

get '/icon_3' => 'icon_3';
$t->get_ok('/icon_3')->status_is(200)->element_exists('#perl-logo')->element_exists('[data-icon]');

done_testing();

__DATA__

@@ icon_1.html.ep

%= icon 'logos:perl'

@@ icon_2.html.ep

%= icon 'logos:perl', size => 32

@@ icon_3.html.ep

%= icon 'logos:perl', id => "perl-logo"
