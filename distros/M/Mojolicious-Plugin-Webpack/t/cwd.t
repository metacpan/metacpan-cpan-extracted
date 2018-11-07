use Mojo::Base -strict;
use Test::More;
use Mojolicious::Plugin::Webpack;

my $cwd = Mojo::File->new;
eval { my $CWD = Mojolicious::Plugin::Webpack::CWD->new('nope') };
like $@, qr{chdir nope:}, 'cannot chdir to nope';

{
  my $script_dir = $cwd->child('script');
  my $CWD        = Mojolicious::Plugin::Webpack::CWD->new($script_dir);
  is +Mojo::File->new->to_string, $script_dir, 'chdir script';
}

is +Mojo::File->new->to_string, $cwd->to_string, 'chdir back';

done_testing;
