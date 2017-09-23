#!perl -T

use strict;
use warnings;
use Test::More tests => 14;
use Test::Deep;
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

BEGIN {
  use_ok( 'Rails::Assets::Base' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets::Base $Rails::Assets::Base::VERSION, Perl $], $^X" );

# they have to be defined in Rails::Assets::Base.pm
ok( defined &Rails::Assets::Base::format_extensions_list, 'format_extensions_list() is defined' );
ok( defined &prepare_extensions_refs, 'prepare_extensions_refs() is defined' );
ok( defined &prepare_assets_refs, 'prepare_assets_refs() is defined' );
ok( defined &find_files, 'find_files() is defined' );

my $assets_extensions = {
  fonts => [qw(.ttf)],
  images => [qw(.png)],
  javascripts => [qw(.js)],
  stylesheets => [qw(.css)],
};
my $assets_directories = [qw(app/assets/ public/ vendor/assets/)];

{
  my $assets_ext = [qw(fonts images javascripts stylesheets)];
  is_deeply(
    Rails::Assets::Base::format_extensions_list($assets_extensions),
    $assets_ext, 'format_extensions_list() works with an HASH reference'
  );
  is_deeply(
    Rails::Assets::Base::format_extensions_list($assets_ext),
    $assets_ext, 'format_extensions_list() works with an ARRAY reference'
  );

  my $invalid_ref = sub { return 1 };
  eval { Rails::Assets::Base::format_extensions_list($invalid_ref) } or my $at = $@;
  like(
    $at, qr/Invalid extension argument provided/,
    'format_extensions_list() dies with a message when invalid reference provided'
  );
}

{
  my $expected_assets = {
    fonts => [()], images => [()],
    javascripts => [()], stylesheets => [()],
  };
  my $expected_paths = [qw(
    app/assets/fonts/ app/assets/javascripts/ app/assets/stylesheets/ app/assets/ public/
    vendor/assets/fonts/ vendor/assets/javascripts/ vendor/assets/stylesheets/ vendor/assets/
  )];

  my $expected_reversed_ext = {
    '.ttf' => 'fonts', '.png' => 'images', '.js' => 'javascripts', '.css' => 'stylesheets'
  };

  is_deeply(
    prepare_extensions_refs($assets_extensions),
    $expected_assets, 'prepare_extensions_refs() subroutine works as expected'
  );

  my ($actual_assets, $actual_paths, $actual_eversed_ext) =
      prepare_assets_refs($assets_directories, $assets_extensions);

  is_deeply($actual_assets, $expected_assets, 'prepare_assets_refs() returns expected assets');
  is_deeply($actual_paths, $expected_paths, 'prepare_assets_refs() returns expected paths');
  is_deeply($actual_eversed_ext, $expected_reversed_ext, 'prepare_assets_refs() returns expected reversed ext');
}

{
  local %ENV = ();
  my $test_dir = dirname(__FILE__) or die "Cannot get __FILE__ path: $!";
  my $fixtures_path = catdir($test_dir, 'fixtures');
  chdir $fixtures_path or die "Cannot chdir to $fixtures_path : $!";

  my $assets_directories = [qw(app/assets/ public/ vendor/assets/)];
  my $expected_files = [qw(
    app/assets/stylesheets/application.css
    public/favicon.ico
    public/images/null.png
    vendor/assets/images/.keep
    vendor/assets/javascripts/bootstrap.min.js
    vendor/assets/javascripts/jquery.js
    vendor/assets/stylesheets/css/bootstrap.css
    vendor/assets/stylesheets/font-awesome/css/font-awesome.css.scss
    vendor/assets/stylesheets/font-awesome/fonts/fontawesome-webfont.eot
    vendor/assets/stylesheets/font-awesome/fonts/fontawesome-webfont.svg
    vendor/assets/stylesheets/font-awesome/fonts/fontawesome-webfont.ttf
    vendor/assets/stylesheets/font-awesome/fonts/fontawesome-webfont.woff
    vendor/assets/stylesheets/font-awesome/fonts/fontawesome-webfont.woff2
    vendor/assets/stylesheets/font-awesome/fonts/FontAwesome.otf
  )];

  my $actual_files = find_files($assets_directories);
  is_deeply($actual_files, $expected_files, 'find_files() returns expected files');

  eval { find_files([()]) } or my $at = $@;
  like(
    $at, qr/Invalid reference provided/,
    'format_extensions_list() dies with a message when invalid reference provided'
  );
}
