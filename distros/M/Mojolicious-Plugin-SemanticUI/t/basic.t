use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
plugin 'SemanticUI';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');

# Testing if assets are found and served
our $base         = '';
our $served_files = {};
subtest themes => sub {
  $base = '/vendor/SemanticUI/themes/';
  my $path = $base . 'basic/assets/fonts/';
  for my $ext (qw(eot svg ttf woff)) {
    $t->get_ok($path . 'icons.' . $ext)->status_is(200);

    # Let default/assets/fonts/ have the keys.
    #$served_files->{'icons.' . $ext} = 1;
  }

  $path = $base . 'default/assets/fonts/';
  for my $ext (qw(eot otf svg ttf woff woff2)) {
    $t->get_ok($path . 'icons.' . $ext)->status_is(200);
    $served_files->{'icons.' . $ext} = 1;
  }

  $path = $base . 'default/assets/images/';
  $t->get_ok($path . 'flags.png')->status_is(200);
  $served_files->{'flags.png'} = 1;
};
$base = '/vendor/SemanticUI/';
subtest packaged => sub {

  my $path = $base;
  for my $f (qw(semantic.min.css semantic.min.js)) {
    $t->get_ok($path . $f)->status_is(200);
  }
  $served_files->{'semantic.min.css'} = $served_files->{'semantic.min.js'} = 1;
};

subtest components => sub {
  my $path = $base . 'components/';
  File::Find::find(
    sub {
      return if -d;
      $t->get_ok($path . $_)->status_is(200);
      $served_files->{$_} = 1;
    },
    $INC[0] . '/Mojolicious/public/vendor/SemanticUI/components'
  );
};

# To not miss newly added files with next upgrade.
require File::Find;
my $found_files = {};
subtest 'all served files exist' => sub {
  File::Find::find(
    sub {
      return if -d;

      # do not count not minified temporarily used files
      return if $_ =~ m"
        semantic.js | semantic.css
        "x;
      ok(-f $_ && $served_files->{$_}, $_ . ' is served.');

      # do not count basic theme fonts
      return if $File::Find::dir =~ m"basic/assets/fonts";
      $found_files->{$_} = 1;
    },
    $INC[0] . '/Mojolicious/public/vendor/SemanticUI'
  );
};

is_deeply($found_files, $served_files, 'all found files are served');

done_testing();
