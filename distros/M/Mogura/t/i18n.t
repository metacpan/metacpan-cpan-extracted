use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use File::Temp qw(tempdir);
use Mojo::JSON qw(from_json);
use lib 'lib';
use Mogura::Server;
use Mogura::Server::I18N;

# A missing key or placeholder would otherwise surface only during an action.
my $english = Mogura::Server::I18N::messages('en');
my $japanese = Mogura::Server::I18N::messages('ja');
is_deeply([sort keys %$english], [sort keys %$japanese], 'Both catalogs cover the same messages');
my @mismatched;
for my $key (sort keys %$english) {
    my @en = sort $english->{$key} =~ /(\{[a-z_]+\})/g;
    my @ja = sort $japanese->{$key} =~ /(\{[a-z_]+\})/g;
    push @mismatched, $key if join(',', @ja) ne join(',', @en);
}
is_deeply(\@mismatched, [], 'Both catalogs preserve all interpolation values');
my $root = tempdir(CLEANUP => 1);
require './t/lib/server-fixture.pl';
my $store = Mogura::Server::Store->new(state => $root)->initialize;
$store->register('fixture', 'a' x 64);
my $diagnostic = 'Unsupported or unknown partition: /dev/example1 <unsafe>';
save_inventory(
    $store,
    {
        updated_at => time,
        errors => [],
        disks => [{name => '/dev/example', targets => [], reasons => [$diagnostic]}]
    }
);
my $id = 'a' x 32;
my $scan = {
    id => $id,
    tags => ['日本語 <script>'],
    note => 'Original 日本語 note',
    created_at => '2026-11-07T12:34:56Z',
    started_at => '2026-11-07T12:35:00Z',
    finished_at => '2026-11-07T12:40:00Z',
    target => {
        disk => {name => '/dev/sdb', serial => 'ABC', wwn => '0x123'},
        partition => {name => '/dev/sdb1'}
    },
    syft_version => '1.55.0',
    grype_version => '0.121.0',
    status => 'failed',
    phase => 'sbom',
    failed_phase => 'sbom',
    cleanup_status => 'needs_cleanup',
    error => 'Original diagnostic <script>',
};
seed_scan($store, $scan);
$scan = $store->get($id);
seed_artifact($store, $id, 'syft', '{"artifacts":[]}');
my $app = Mogura::Server->new(store => $store);
$app->log->level('error');
my $t = Test::Mojo->new($app);
$t->get_ok('/')
    ->status_is(200)
    ->header_is('Content-Language', 'en')
    ->element_exists('html[lang="en"]')
    ->text_is('h1', 'Scan');
$t->get_ok('/' => {'Accept-Language' => 'ja-JP,en;q=0.8'})
    ->status_is(200)
    ->header_is('Content-Language', 'en')
    ->text_is('h1', 'Scan')
    ->text_is('select[name="lang"] option:first-child', 'English');
$t->get_ok('/?lang=../../ja' => {'Accept-Language' => 'fr'})
    ->status_is(200)
    ->header_is('Content-Language', 'en');
$t->get_ok('/inventory' => {Cookie => 'mogura_language=../../ja', 'Accept-Language' => 'ja'})
    ->status_is(200)
    ->header_is('Content-Language', 'en');

for my $locale (qw(en ja)) {
    my $messages = Mogura::Server::I18N::messages($locale);
    $t->get_ok("/?lang=$locale")
        ->status_is(200)
        ->header_is('Content-Language', $locale)
        ->element_exists("html[lang=\"$locale\"]")
        ->element_exists_not('input[name="clone"]')
        ->element_exists("select[name=\"lang\"] option[value=\"$locale\"][selected]")
        ->text_is('h1', $messages->{scan})
        ->content_like(qr/\Q$messages->{unsupported_partition}\E: \/dev\/example1 &lt;unsafe&gt;/);
    like(
        $t->tx->res->headers->set_cookie,
        qr/mogura_language=$locale;.*path=\//i,
        'Preference persists for the whole application'
    );
    my $client = from_json($t->tx->res->dom->at('script[src="/i18n.js"]')->attr('data-messages'));
    is(
        $client->{save_failed},
        $messages->{save_failed},
        'JavaScript receives the same locale as the page'
    );
    my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
    my $opposite = $locale eq 'en' ? 'ja' : 'en';
    $t->get_ok('/history?tag=example&page=2' => {'Accept-Language' => $opposite})
        ->status_is(200)
        ->header_is('Content-Language', $locale)
        ->text_is('h1', $messages->{history});
    my $switch = $t->tx->res->dom->at('[data-language-form]');
    is($switch->attr('action'), '/history', 'Language form stays on the current page');
    is($switch->at('input[name="tag"]')->attr('value'),
        'example', 'Switch preserves history filter');
    is($switch->at('input[name="page"]')->attr('value'), '2', 'Switch preserves history page');
    $t->get_ok('/inventory')->status_is(200)->header_is('Content-Language', $locale);
    $t->post_ok("/scans/$id/note" => form => {csrf_token => $csrf, note => 'x' x 2001})
        ->status_is(400)
        ->content_is($messages->{note_limit});
    $t->post_ok('/scans')->status_is(403)->content_is($messages->{invalid_csrf});
    $t->get_ok("/scans/$id/results/syft")
        ->status_is(409)
        ->json_is('/error', $messages->{create_list_first});
    $t->get_ok("/scans/$id")
        ->status_is(200)
        ->content_like(qr/\Q$messages->{do_not_disconnect}\E/)
        ->content_like(qr/Original diagnostic &lt;script&gt;/)
        ->content_unlike(qr/<script>/);
    my $dom = $t->tx->res->dom;
    my %rows = map { $_->all_text => $_->next->all_text } $dom->find('dl dt')->each;
    my $day = $locale eq 'en' ? '11/07/2026,' : '2026/11/07';

    for my $pair (
        [scan_started_utc => "$day 12:35:00"],
        [scan_finished_utc => "$day 12:40:00"],
        [disk => '/dev/sdb'],
        [root_device => '/dev/sdb1'],
        [serial_number => 'ABC'],
        [wwn => '0x123'],
        [syft_version => '1.55.0'],
        [grype_version => '0.121.0']
        )
    {
        is($rows{$messages->{$pair->[0]}}, $pair->[1], "$pair->[0] has its own labeled row");
    }
    my $date = $locale eq 'ja' ? '2026/11/07 12:34:56' : '11/07/2026, 12:34:56';
    like($t->tx->res->text, qr/\Q$date\E/,
        'Display date follows the selected locale and keeps UTC');
    $t->get_ok("/scans/$id/download/metadata")
        ->status_is(200)
        ->json_is('/created_at', $scan->{created_at})
        ->json_is('/note', $scan->{note});
    $t->get_ok('/missing-page')->status_is(404)->text_is('h1', $messages->{not_found});
}
is_deeply($store->get($id), $scan, 'Language changes leave the stored scan and annotations intact');

done_testing;
