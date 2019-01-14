use Mojo::Base -strict;
use Test::More;
use Mojolicious::Plugin::Webpack::Builder;

my $cwd = Mojo::File->new;
eval { my $CWD = Mojolicious::Plugin::Webpack::CWD->new('nope') };
like $@, qr{chdir nope:}, 'cannot chdir to nope';

{
  my $lib_dir = $cwd->child('lib');
  my $CWD     = Mojolicious::Plugin::Webpack::CWD->new($lib_dir);
  is +Mojo::File->new->to_string, $lib_dir, 'chdir lib';
}

is +Mojo::File->new->to_string, $cwd->to_string, 'chdir back';

done_testing;
