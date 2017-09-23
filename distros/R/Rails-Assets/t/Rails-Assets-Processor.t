#!perl -T

use strict;
use warnings;
use Test::More tests => 13;
use Test::Deep;
use Test::Output;

use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);
use Rails::Assets::Base qw(
  find_files
  prepare_assets_refs
  prepare_extensions_refs
);

BEGIN {
  use_ok( 'Rails::Assets::Processor' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets::Processor $Rails::Assets::Processor::VERSION, Perl $], $^X" );

# they have to be defined in Rails::Assets::Processor.pm
ok( defined &process_asset_file, 'process_asset_file() is defined' );
ok( defined &process_template_file, 'process_template_file() is defined' );
ok( defined &process_scss_file, 'process_scss_file() is defined' );
ok( defined &process_map_file, 'process_map_file() is defined' );


{
  local %ENV = ();
  my $test_dir = dirname(__FILE__) or die "Cannot get __FILE__ path: $!";
  my $fixtures_path = catdir($test_dir, 'fixtures');
  chdir $fixtures_path or die "Cannot chdir to $fixtures_path : $!";

  my $template_directories = [qw( app/views/)];
  my $template_extensions = [qw(.haml .erb)];
  my $assets_directories = [qw( app/assets/ public/ vendor/assets/ )];
  my $assets_extensions = {
    fonts => [qw(.woff2 .woff .ttf .eot .otf)],
    images => [qw(.png .jpg .gif .svg .ico)],
    javascripts => [qw(.js .map)],
    stylesheets => [qw(.css .scss)],
  };

  my ($assets_hash, $assets_paths, $reversed_ext) =
   prepare_assets_refs($assets_directories, $assets_extensions);
  my $template_hash = prepare_extensions_refs($assets_extensions);
  my $scss_hash = prepare_extensions_refs($assets_extensions);
  my $map_hash = prepare_extensions_refs($assets_extensions);

  my @asset_files = @{find_files($assets_directories)};
  my @template_files = @{find_files($template_directories)};

  process_asset_file($_, $reversed_ext, $assets_hash, $assets_paths) foreach @asset_files;
  process_template_file($_, $template_hash, $template_extensions) foreach @template_files;

  my @js_files = grep { $_->{ext} eq '.js' } @{$assets_hash->{javascripts}};
  my @scss_files = grep { $_->{ext} eq '.scss' } @{$assets_hash->{stylesheets}};

  process_map_file($_, $reversed_ext, $map_hash) foreach (map {$_->{full_path}} @js_files);

  {
    local $ENV{VERBOSE} = 1;

    stdout_like( sub {
      process_template_file($scss_files[0]->{full_path}, $template_hash, $template_extensions)
    }, qr/Found unknown type/, 'process_template_file() print error message when VERBOSE');
    stdout_like( sub {
      process_asset_file($template_files[0], $template_hash, $template_extensions)
    }, qr/Found unknown type/, 'process_asset_file() print error message when VERBOSE');
    stdout_like( sub {
      process_scss_file($scss_files[0]->{full_path}, $reversed_ext, $scss_hash)
    }, qr/Found unknown type/, 'process_scss_file() print error message when VERBOSE');

    local $reversed_ext->{'.map'} = undef;
    stdout_like( sub {
      process_map_file($_, $reversed_ext, $map_hash) foreach (map {$_->{full_path}} @js_files)
    }, qr/Found unknown type/, 'process_map_file() print error message when VERBOSE');
  }

  {
    local $ENV{VERBOSE} = 0;

    stdout_like( sub {
      process_template_file($scss_files[0]->{full_path}, $template_hash, $template_extensions)
    }, qr//, 'process_template_file() print no error message when VERBOSE disabled');
    stdout_like( sub {
      process_asset_file($template_files[0], $template_hash, $template_extensions)
    }, qr//, 'process_asset_file() print no error message when VERBOSE disabled');
    stdout_like( sub {
      process_scss_file($scss_files[0]->{full_path}, $reversed_ext, $scss_hash)
    }, qr//, 'process_scss_file() print no error message when VERBOSE disabled');
        local $reversed_ext->{'.map'} = undef;
    stdout_like( sub {
      process_map_file($_, $reversed_ext, $map_hash) foreach (map {$_->{full_path}} @js_files)
    }, qr//, 'process_map_file() print no error message when VERBOSE disabled');
  }
}
