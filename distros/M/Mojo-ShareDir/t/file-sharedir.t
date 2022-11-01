use Mojo::Base -strict;
use Mojo::ShareDir;
use Test::More;

plan skip_all => 'File::ShareDir is not installed' unless eval 'require File::ShareDir;1';

subtest 'Find same path as File::ShareDir::dist_dir' => sub {
  my $share = Mojo::ShareDir->new('File-ShareDir');
  my $path  = File::ShareDir::dist_dir('File-ShareDir');
  is $path, $share, 'same dist result';
};

subtest 'Find same path as File::ShareDir::module_dir' => sub {
  local $TODO = 'Not supported';
  my $share = Mojo::ShareDir->new('File::ShareDir');
  my $path  = File::ShareDir::module_dir('File::ShareDir');
  is $path, $share, 'same module result';
};

done_testing;
