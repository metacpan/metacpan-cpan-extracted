use Mojo::Base -strict, -signatures;
use Test2::V0;

use Mojo::File qw(path);
use Mojo::Tar;

my $example = path(qw(t example.tar));
plan skip_all => 'Cannot open t/example.tar' unless -r "$example";

subtest 'from_header and to_header' => sub {
  sysread $example->open('<'), my ($header), 512, 0 or die $!;
  my $file = Mojo::Tar::File->new->from_header($header);
  ok $file->checksum, 'correct checksum';
  is $file->gid,                  20,            'gid';
  is $file->group,                'staff',       'group';
  is sprintf('0%o', $file->mode), '0644',        'mode';
  is $file->mtime,                1678668004,    'mtime';
  is $file->owner,                'jhthorsen',   'owner';
  is $file->path,                 'Makefile.PL', 'path';
  is $file->size,                 1427,          'size';
  is $file->type,                 0,             'type';
  is $file->uid,                  501,           'gid';

  my $got = $file->to_header;
  for my $line (split /\n/, $Mojo::Tar::File::PACK_FORMAT) {
    my ($len, $pos, $name) = $line =~ /(\d+)\W+pos=(\d+)\W+name=(\w+)/ or next;
    is substr($got, 0, $len, ''), substr($header, 0, $len, ''), "header $name $pos / $len";
  }
};

done_testing;
