#!perl -T

use strict;
use warnings;
use Test::More tests => 39;
use Test::Deep;
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

BEGIN {
  use_ok( 'Rails::Assets' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets $Rails::Assets::VERSION, Perl $], $^X" );

# Test some class constants in Rails::Assets.pm
is( ref($Rails::Assets::TEMPLATE_DIR), 'ARRAY', 'class constant TEMPLATE_DIR is an ARRAY');
is( ref($Rails::Assets::TEMPLATE_EXT), 'ARRAY', 'class constant TEMPLATE_EXT is an ARRAY');
is( ref($Rails::Assets::ASSETS_DIR), 'ARRAY', 'class constant ASSETS_DIR is an ARRAY');
is( ref($Rails::Assets::ASSETS_EXT), 'HASH', 'class constant ASSETS_EXT is an HASH');

# Test methods defined in Rails::Assets.pm
ok( defined &Rails::Assets::new, 'new() is defined');
ok( defined &Rails::Assets::template_dir, 'template_dir() is defined');
ok( defined &Rails::Assets::template_ext, 'template_ext() is defined');
ok( defined &Rails::Assets::assets_dir, 'assets_dir() is defined');
ok( defined &Rails::Assets::assets_ext, 'assets_ext() is defined');
ok( defined &Rails::Assets::assets_hash, 'assets_hash() is defined');
ok( defined &Rails::Assets::template_hash, 'template_hash() is defined');
ok( defined &Rails::Assets::scss_hash, 'scss_hash() is defined');
ok( defined &Rails::Assets::map_hash, 'map_hash() is defined');
ok( defined &Rails::Assets::assets_paths, 'assets_paths() is defined');
ok( defined &Rails::Assets::reversed_ext, 'reversed_ext() is defined');
ok( defined &Rails::Assets::analyse, 'analyse() is defined');

# Test default for class constants and initializer
my $template_directories = [qw( app/views/)];
my $template_extensions = [qw(.haml .erb)];
my $assets_directories = [qw( app/assets/ public/ vendor/assets/ )];
my $assets_extensions = {
  fonts => [qw(.woff2 .woff .ttf .eot .otf)],
  images => [qw(.png .jpg .gif .svg .ico)],
  javascripts => [qw(.js .map)],
  stylesheets => [qw(.css .scss)],
};

is_deeply( $Rails::Assets::TEMPLATE_DIR, $template_directories, 'TEMPLATE_DIR has the expected default');
is_deeply( $Rails::Assets::TEMPLATE_EXT, $template_extensions, 'TEMPLATE_EXT has the expected default');
is_deeply( $Rails::Assets::ASSETS_DIR, $assets_directories, 'ASSETS_DIR has the expected default');
is_deeply( $Rails::Assets::ASSETS_EXT, $assets_extensions, 'ASSETS_EXT has the expected default');

my $assets = Rails::Assets->new();
is_deeply( $assets->template_dir(), $template_directories, 'template_dir() has the expected default');
is_deeply( $assets->template_ext(), $template_extensions, 'template_ext() has the expected default');
is_deeply( $assets->assets_dir(), $assets_directories, 'assets_dir() has the expected default');
is_deeply( $assets->assets_ext(), $assets_extensions, 'assets_ext() has the expected default');

{
  push @{$assets->template_dir}, 'app/';
  is_deeply($assets->template_dir, [qw(app/views/ app/)], 'Can push elements into template_dir reference');
  is_deeply($Rails::Assets::TEMPLATE_DIR, $template_directories, 'Pushing elements into instance reference does not affect constants');
}

{
  local %ENV = ();
  my $test_dir = dirname(__FILE__) or die "Cannot get __FILE__ path: $!";
  my $fixtures_path = catdir($test_dir, 'fixtures');
  chdir $fixtures_path or die "Cannot chdir to $fixtures_path : $!";

  is($assets->assets_hash(), undef, 'assets_hash() is undef by default');
  is($assets->template_hash(), undef, 'template_hash() is undef by default');
  is($assets->scss_hash(), undef, 'scss_hash() is undef by default');
  is($assets->map_hash(), undef, 'map_hash() is undef by default');
  is($assets->assets_paths(), undef, 'assets_paths() is undef by default');
  is($assets->reversed_ext(), undef, 'reversed_ext() is undef by default');

  $assets->analyse();

  is_deeply(
    [sort keys %{$assets->assets_hash()}], [qw(fonts images javascripts stylesheets)],
    'assets_hash() has proper keys');
  is_deeply(
    [sort keys %{$assets->template_hash()}], [qw(fonts images javascripts stylesheets)],
    'template_hash() has proper keys');
  is_deeply(
    [sort keys %{$assets->scss_hash()}], [qw(fonts images javascripts stylesheets)],
    'scss_hash() has proper keys');
  is_deeply(
    [sort keys %{$assets->map_hash()}], [qw(fonts images javascripts stylesheets)],
    'map_hash() has proper keys');

  my $expected_paths = [qw(
    app/assets/fonts/ app/assets/javascripts/ app/assets/stylesheets/ app/assets/ public/
    vendor/assets/fonts/ vendor/assets/javascripts/ vendor/assets/stylesheets/ vendor/assets/
  )];
  is_deeply($assets->assets_paths(), $expected_paths, 'assets_paths() contains expected paths');

  is_deeply(
    [sort keys %{$assets->reversed_ext()}], [sort map {@$_} values %{$assets->assets_ext()}],
    'reversed_ext() has all values from assets_ext() as keys');
}
