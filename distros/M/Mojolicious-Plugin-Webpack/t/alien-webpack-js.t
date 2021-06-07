use Mojo::Base -strict;
use Mojo::Alien::webpack;
use Mojo::File qw(path);
use Test::More;

plan skip_all => 'TEST_JS=1' unless $ENV{TEST_JS} or $ENV{TEST_ALL};
note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;

my $webpack   = Mojo::Alien::webpack->new->include(['js']);
my $index_js  = $webpack->assets_dir->make_path->child('index.js')->spurt(qq[console.log('built $^T');]);
my $dist_file = $webpack->config->dirname->child('dist', 'alien-webpack-js-t.development.js');

is $webpack->build, $webpack, 'build js';
ok -e $dist_file, 'built';
like $dist_file->slurp, qr{'built $^T'}, 'correct content';

done_testing;
