use Mojo::Base -strict;
use Mojo::ShareDir;
use Test::More;

my @base = $INC{'Mojo/ShareDir.pm'} =~ /\bblib\b/ ? qw(blib lib auto share dist Mojo-ShareDir) : qw(share);

subtest 'Find local share path by module name' => sub {
  my $share = Mojo::ShareDir->new('Mojo::ShareDir');
  my $path  = Mojo::File->new(@base)->to_abs;
  is $share, $path, 'found share for Mojo::ShareDir';
};

subtest 'Find local share path by dist name' => sub {
  my $share = Mojo::ShareDir->new('Mojo-ShareDir', 'whatever');
  my $path  = Mojo::File->new(@base, 'whatever')->to_abs;
  is $share, $path, 'got whatever for Mojo::ShareDir';

  $share = Mojo::ShareDir->new('Mojo::ShareDir', 'README.md');
  ok -e $share, 'got file for Mojo::ShareDir';
  like $share->slurp, qr{^thorsen\.pm\W*$}s, 'got content for share/README.md';
};

subtest 'Failed to find path for unknown module' => sub {
  eval { Mojo::ShareDir->new('No::Such::Module') };
  like $@, qr{Could not find dist path for "No::Such::Module"}, 'No::Such::Module';
};

done_testing;
