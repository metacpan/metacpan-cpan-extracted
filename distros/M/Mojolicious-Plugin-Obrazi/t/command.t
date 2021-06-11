use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::File qw(curfile path tempdir);
use Mojo::Util qw(encode decode);
use lib curfile->dirname->dirname->child('lib')->to_string;
my $t              = Test::Mojo->new('Mojolicious');
my $random_tempdir = tempdir('opraziXXXX', TMPDIR => 1, CLEANUP => 0);

my $COMMAND = 'Mojolicious::Command::Author::generate::obrazi';
require_ok($COMMAND);
my $command = $COMMAND->new();
isa_ok($command => 'Mojolicious::Command');
sub U {'UTF-8'}

# Help
my $help = sub {
  my $buffer = '';
  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    $t->app->start('generate', 'obrazi', '-h');
  }

  like $buffer => qr/myapp.pl generate obrazi --from --to/ => 'SYNOPSIS';
  like $buffer => qr/-f, --from/                           => 'SYNOPSIS --from';
  like $buffer => qr/-t, --to/                             => 'SYNOPSIS --to';
  like $buffer => qr/-x, --max/                            => 'SYNOPSIS --max';
  like $buffer => qr/-s, --thumbs/                         => 'SYNOPSIS --thumbs';
};

my $defaults = sub {

  is $command->from_dir   => path('./')->to_abs, 'from_dir is current dir';
  is $command->to_dir     => $t->app->home->child('public'), 'to_dir is app->home/public';
  is_deeply $command->max => {width => 1000, height => 1000},
    'max is 1000x1000';
  is_deeply $command->thumbs => {width => 100, height => 100},
    'thumbs is 100x100';
  like $command->description => qr/images$/, 'right description';
};
my $run = sub {
  my $from_dir = curfile->dirname->child('data/from');

  # Remove previously generated index file.
  unlink $from_dir->child($command->csv_filename);
  my $buffer = '';

  {
    open my $handle, '>', \$buffer;
    local *STDERR = $handle;
    $command->run('-f' => $from_dir, '-t' => $random_tempdir);
  }

  # note $buffer;
  like $buffer            => qr/warn.+?Skipping.+?loga4.png. Image error: iCCP/, 'right warning';
  like $buffer            => qr/loga16\.png/,                                    'right file';
  like decode(U, $buffer) => qr/Inspecting category мозайки/,                    'right category';
};
my $run_custom = sub {
  my $from_dir = curfile->dirname->child('data/from');

  # Remove previously generated index file.
  my $index_file = $from_dir->child($command->csv_filename);
  unlink $index_file;
  $random_tempdir->remove_tree();
  my $buffer = '';

  {
    open my $handle, '>', \$buffer;
    local *STDOUT = $handle;
    $command = $COMMAND->new();
    $command->log->handle(\*STDOUT);
    $command->run('-f' => $from_dir, '-t' => $random_tempdir, '--max' => '500x500', '--thumbs' => '120x120');
  }

  like $buffer            => qr/warn.+?Skipping.+?loga4.png. Image error: iCCP/, 'right warning';
  like $buffer            => qr/loga16\.png/,                                    'right file';
  like decode(U, $buffer) => qr/Inspecting category мозайки/,                    'right category';
  is_deeply $command->max => {width => 500, height => 500},
    'right max';
  is_deeply $command->thumbs => {width => 120, height => 120},
    'right thumbs';
  is $command->from_dir => $from_dir,       'right from_dir';
  is $command->to_dir   => $random_tempdir, 'right to_dir';

  my $index_content = decode U, path($index_file)->slurp;
  like $index_content => qr/
    монограм1\.png.+?
    1-7sbi9acdgbt_300x303\.png\,1-7sbi9acdgbt_119x120\.png/xsm, 'right calculate_max_and_thumbs';
  note 'to_dir:' . $command->to_dir;
};

subtest help       => $help;
subtest defaults   => $defaults;
subtest run        => $run;
subtest run_custom => $run_custom;

done_testing;

