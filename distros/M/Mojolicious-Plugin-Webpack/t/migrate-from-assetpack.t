use lib '.';
use t::Helper;
use Mojo::File;

plan skip_all => 'TEST_ASSETPACK=1' unless $ENV{TEST_ASSETPACK} or $ENV{TEST_ALL};

my $cwd = t::Helper->cwd('migrate-from-assetpack');
$t::Helper::CLEANUP = 0;

cleanup();

ok !-e f('assets/entry-my-app.js'), 'entry-my-app.js does not exist';

note 'migrate';
$ENV{WEBPACK_CUSTOM_NAME} = '';
my $t = t::Helper->t(process => ['js']);

my $custom = f('assets/webpack.custom.js');
ok -e $custom, 'custom-my-app.js created';
like $custom->slurp, qr[config\.entry = \{\n    'my-app': '\./assets/entry-my-app\.js'\n  \}]s,
  'webpack.custom content';

my $entry = f('assets/entry-my-app.js');
ok -e $entry, 'entry-my-app.js created';
like $entry->slurp, qr{import "\./js/$_";}, "entry-my-app.js import $_" for qw(app.js include-some-file.js);

$t->get_ok($t->app->asset(url_for => 'my-app.js'))->status_is(200);

cleanup();

done_testing;

sub cleanup {
  note 'cleanup';
  unlink f($_) for qw(webpack.config assets/entry-my-app.js assets/webpack.custom.js);
}

sub f { Mojo::File::path(split '/', $_[0]) }
