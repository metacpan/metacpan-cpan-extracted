use Mojo::Base -strict;
use Mojo::Alien::npm;
use Mojo::File qw(path);
use Test::More;

BEGIN { $ENV{MOJO_NPM_BINARY} = 'pnpm' }

plan skip_all => 'TEST_PNPM=1' unless $ENV{TEST_PNPM} or $ENV{TEST_ALL};
note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;
sub maybe (&) { local $TODO = 'MOJO_NPM_CLEAN=0' unless $ENV{MOJO_NPM_CLEAN}; shift->(); }

subtest 'basic' => sub {
  my $npm = Mojo::Alien::npm->new;
  is $npm->binary, 'pnpm',        'binary';
  is $npm->mode,   'development', 'mode';

  eval { $npm->install };
  maybe { like $@, qr{Can't install packages}, 'install' };

  eval { $npm->dependencies };
  maybe { like $@, qr{Can't get dependency info}, 'dependencies' };
};

subtest 'init' => sub {
  my $npm = Mojo::Alien::npm->new;
  maybe { ok !-r $npm->config, 'config does not exist' };
  is $npm->init, $npm, 'init';
  ok -r $npm->config, 'config created';
  is $npm->init, $npm, 'init can be called again';

  maybe {
    my @dependencies = keys %{$npm->dependencies};
    is_deeply \@dependencies, @dependencies ? [qw(jsonhtmlify)] : [], 'dependencies'
  };
};

subtest 'install' => sub {
  my $npm = Mojo::Alien::npm->new;
  is $npm->install,                                  $npm, 'install';
  is $npm->install('jsonhtmlify', {type => 'prod'}), $npm, 'install jsonhtmlify';

  my $dependencies = $npm->dependencies;
  is_deeply [grep {/jsonhtmlify/} keys %{$npm->dependencies}], [qw(jsonhtmlify)], 'dependencies';

  my $info = $dependencies->{jsonhtmlify};
  is $info->{type}, 'prod', 'jsonhtmlify type';
  ok $info->{required}, "jsonhtmlify required $info->{required}";
  ok $info->{version},  "jsonhtmlify version $info->{version}";
};

done_testing;
