#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Test::Deep;
use Test::Output;
use Rails::Assets;

BEGIN {
  use_ok( 'Rails::Assets::Output' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets::Output $Rails::Assets::Output::VERSION, Perl $], $^X" );

my $mocked_assets_hash = {
  fonts => [()],
  images => [(
   {
      name => 'image.png',
      full_path => 'public/image.png',
      ext => '.png',
    }
   )],
  javascripts => [(
    {
      name => 'application.js',
      full_path => 'app/assets/javascripts/application.js',
      ext => '.js',
    },
    {
      name => 'unused.js',
      full_path => 'app/assets/javascripts/unused.js',
      ext => '.js',
    }
  )],
  stylesheets => [(
    {
      name => 'application.css',
      full_path => 'app/assets/stylesheets/application.css.scss',
      ext => '.scss',
    }
  )],
};
my $mocked_template_hash = {
  fonts => [()],
  images => [()],
  javascripts => [(
    {
      name => 'application.js',
      full_path => 'app/views/layouts/application.html.haml',
    }
  )],
  stylesheets => [(
    {
      name => 'application.css',
      full_path => 'app/views/layouts/application.html.haml',
    },
    {
      name => 'broken_ref.css',
      full_path => 'app/views/layouts/application.html.haml',
    }
  )],
};
my $mocked_scss_hash = {
  fonts => [()],
  images => [(
    {
      name => 'image.png',
      referral => 'app/assets/stylesheets/application.css.scss',
      ext => '.png',
    },
    {
      name => 'not_found.png',
      referral => 'app/assets/stylesheets/application.css.scss',
      ext => '.png',
    }
  )],
  javascripts => [()],
  stylesheets => [()],
};
my $mocked_map_hash = {
  fonts => [()],
  images => [()],
  javascripts => [(
    {
      name => 'application.js.map',
      referral => 'app/assets/javascripts/application.js',
      ext => '.map',
    },
    {
      name => 'unused.js.map',
      referral => 'app/assets/javascripts/unused.js',
      ext => '.map',
    }
  )],
  stylesheets => [()],
};
{
  *Rails::Assets::assets_hash = sub { return $mocked_assets_hash };
  *Rails::Assets::template_hash = sub { return $mocked_template_hash };
  *Rails::Assets::scss_hash = sub { return $mocked_scss_hash };
  *Rails::Assets::map_hash = sub { return $mocked_map_hash };

  my $fake_asset = Rails::Assets->new();
  is_deeply($fake_asset->map_hash(), $mocked_map_hash, 'I can mock an instance method correctly');
  stdout_is(
    sub { tell_output($fake_asset) },
      "My fonts files are:0\n" .
      "My fonts references are:0\n" .
      "My fonts .scss references are:0\n" .
      "My fonts .js references are:0\n" .
      "My images files are:1\n" .
      "- image.png (public/image.png)\n" .
      "My images references are:0\n" .
      "My images .scss references are:2\n" .
      "- image.png (app/assets/stylesheets/application.css.scss)\n" .
      "- not_found.png (app/assets/stylesheets/application.css.scss)\n" .
      "My images .js references are:0\n" .
      "My javascripts files are:2\n" .
      "- application.js (app/assets/javascripts/application.js)\n" .
      "- unused.js (app/assets/javascripts/unused.js)\n" .
      "My javascripts references are:1\n" .
      "- application.js (app/views/layouts/application.html.haml)\n" .
      "My javascripts .scss references are:0\n" .
      "My javascripts .js references are:2\n" .
      "- application.js.map (app/assets/javascripts/application.js)\n" .
      "- unused.js.map (app/assets/javascripts/unused.js)\n" .
      "My stylesheets files are:1\n" .
      "- application.css (app/assets/stylesheets/application.css.scss)\n" .
      "My stylesheets references are:2\n" .
      "- application.css (app/views/layouts/application.html.haml)\n" .
      "- broken_ref.css (app/views/layouts/application.html.haml)\n" .
      "My stylesheets .scss references are:0\n" .
      "My stylesheets .js references are:0\n"
      , 'tell_output() works as expected'
  );

}
