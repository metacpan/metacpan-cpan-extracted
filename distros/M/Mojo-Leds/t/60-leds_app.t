use Mojo::Base -strict;

use Mojolicious::Command::Author::generate::leds_app;

use Test::More;
use Test::Mojo;

use Mojo::File qw(path tempdir);

my $app = Mojolicious::Command::Author::generate::leds_app->new;

ok $app->description, 'has a description';
like $app->usage, qr/app/, 'has usage information';

my $cwd = path;
my $dir = tempdir;
chdir $dir;
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $app->run;
}

like $buffer, qr/my_app/, 'right output';

chdir "$dir/my_app";

ok -e $app->rel_file('script/my_app'),                     'script exists';
ok -e $app->rel_file('lib/MyApp.pm'),                      'application class exists';
ok -e $app->rel_file('cfg/app.cfg'),                        'config file exists';
ok -e $app->rel_file('www/public/index.html'),                 'static file exists';
ok -e $app->rel_file('www/layouts/default.html.ep'), 'layout exists';
ok -e $app->rel_file('www/welcome/index.pm'),   'controller exists';
ok -e $app->rel_file('www/welcome/index.html.ep'), 'template exists';
ok -e $app->rel_file('www/welcome/index.css'), 'css page exists';

chdir $cwd;

done_testing();
