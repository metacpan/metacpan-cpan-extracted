use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use FindBin;
use File::Spec;

my $config = plugin 'Config' 
          => { default => {
                watch_dirs => {
                  downloads => app->home->rel_dir('downloads')
                } },
                file => app->home->rel_dir('myapp.conf')
                };


# Mojolicious::Lite
#   my $config = plugin ConfigHashMerge => default =>
#     { watch_dirs => { downloads => app->home->rel_dir('downloads') } };
#       say $_ for ($config->{watch_dirs}{qw(downloads music ebooks)});
#
get '/' => sub {
  my $self = shift;
  my $dirs = $self->config('watch_dirs');
  $self->render(json  => $dirs);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)
  ->json_is( '/downloads', undef, 'Config overwrites defaults' )
  ->json_is( '/music', app->home->rel_dir('music') )
  ->json_is( '/ebooks', app->home->rel_dir('ebooks') );

done_testing();
