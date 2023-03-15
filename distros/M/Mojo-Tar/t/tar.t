use Mojo::Base -strict, -signatures;
use Test2::V0;

use Mojo::File qw(path);
use Mojo::Tar;

my $example = path(qw(t example.tar));
plan skip_all => 'Cannot open t/example.tar' unless -r "$example";

subtest 'constants' => sub {
  is Mojo::Tar::TAR_USTAR_PADDING_POS, 500, 'TAR_USTAR_PADDING_POS';
  is Mojo::Tar::TAR_USTAR_PADDING_LEN, 12,  'TAR_USTAR_PADDING_LEN';
};

subtest 'looks_like_tar' => sub {
  my $tar = Mojo::Tar->new;
  is $tar->looks_like_tar(''),                              0, 'short';
  is $tar->looks_like_tar('1' x Mojo::Tar->TAR_BLOCK_SIZE), 0, 'pad missing';

  my $header = Mojo::Tar::File->new->to_header;
  is $tar->looks_like_tar($header), 1, 'looks like tar';

  substr $header, 0, 3, 'xxx';
  is $tar->looks_like_tar($header), 0, 'invalid checksum';
};

subtest 'extract' => sub {
  my $tar = Mojo::Tar->new;
  my $n   = $tar->files->size;
  ok !$tar->is_complete, 'not complete';

  my $files = Mojo::Collection->new;
  $tar->on(extracted => sub ($tar, $file) { push @$files, $file });

  my $fh = $example->open('<');
  while (1) {
    sysread $fh, my ($chunk), int(448 + rand 128) or last;
    $tar->extract($chunk);
  }

  is $files->size,                  11, 'extracted all files';
  is $files->map('type')->to_array, [0,    0,  5, 5, 5, 5, 5, 5, 5, 0,  0],   'type';
  is $files->map('size')->to_array, [1427, 86, 0, 0, 0, 0, 0, 0, 0, 23, 409], 'size';
  ok $tar->is_complete, 'is complete';

  my $file = $files->first;
  is $file->path,                 'Makefile.PL', 'file path';
  isnt $file->asset->path,        $file->path,   'asset is a temp file';
  is length($file->asset->slurp), $file->size,   'extracted file has matching file size';

  $file = $files->grep(sub { $_->path =~ /\.txt$/ })->first;
  is $file->path,
    't/some/example/path/with/a/long/file/3ttakojrzqwvbamb00jfzjh9xur071ht2cqbsbw63bprfw69xnj4sqfqoyyyrsnip9re0y1foxsa7jc0yzyinvjngzg5udea.txt',
    'file path with prefix';

  is +Mojo::Tar::File->new->from_header($file->to_header)->path, $file->path,
    'to_header() with prefix';

  is $tar->files->size, $n + 11, 'files was modified';
};

subtest 'create' => sub {
  my $tar = Mojo::Tar->new;
  ok !$tar->is_complete, 'not complete';

  my @files;
  $tar->on(adding => sub ($tar, $file) { push @files, $file });
  $tar->on(added => sub ($tar, $file) { is $file, exact_ref($files[-1]), 'added' });

  my $cb = $tar->files(Mojo::File->new->child('t')->list->map('to_rel'))->create;
  my $n  = $tar->files->size;
  is ref($cb), 'CODE', 'got a callback from create()';

  my $content = '';
  while (length(my $chunk = $cb->())) {
    $content .= $chunk;
  }

  ok $tar->is_complete, 'is complete';
  is substr($content, -512 * 2), Mojo::Tar->TAR_BLOCK_PAD x 2, 'padded at the end';

  my $files_size = $tar->files->reduce(sub { $b->asset->stat->size + $a }, 0);
  ok $files_size < length($content), "tar size > $files_size";

  my $file = $tar->files->grep(sub { $_->path =~ /tar\.t$/ })->first;
  like $file->path,  qr{tar\.t$}, 'file path';
  like $file->group, qr{\w},      'file group';
  like $file->owner, qr{\w},      'file owner';
  is $file->size, -s __FILE__, 'file size';
  is $file->type, 0,           'file type';
  is $file->uid,  $<,          'file uid';
  ok $file->gid > 0,            'file gid';
  ok $file->mode >= 0600,       'file mode';
  ok $file->mtime > 1000000000, 'file mtime';

  is $tar->files->size, $n, 'files was not modified';
};

done_testing;
