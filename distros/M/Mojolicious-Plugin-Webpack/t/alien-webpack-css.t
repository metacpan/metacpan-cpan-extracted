use Mojo::Base -strict;
use Mojo::Alien::webpack;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_CSS=1' unless $ENV{TEST_CSS} or $ENV{TEST_ALL};
note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;

my $webpack = Mojo::Alien::webpack->new->include(['css']);
$webpack->assets_dir->make_path;

my $index_css = $webpack->assets_dir->child('index.css')->spurt(qq[body { background: #fefefe; }\n]);
my $index_js  = $webpack->assets_dir->child('index.js')->spurt(qq[require('./index.css');]);
my $dist_file = $webpack->config->dirname->child('dist', 'alien-webpack-css-t.development.css');

is $webpack->build, $webpack, 'build css';
ok -e $dist_file, 'built';
like $dist_file->slurp, qr{background:\s*#fefefe}s, 'correct content';

done_testing;
