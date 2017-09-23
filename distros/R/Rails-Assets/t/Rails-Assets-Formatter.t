#!perl -T

use strict;
use warnings;
use Test::More tests => 7;
use Test::Deep;

BEGIN {
  use_ok( 'Rails::Assets::Formatter' ) || BAIL_OUT();
}
diag( "Testing Rails::Assets::Formatter $Rails::Assets::Formatter::VERSION, Perl $], $^X" );

# they have to be defined in Rails::Assets::Formatter.pm
ok( defined &format_asset_elem, 'format_asset_elem() is defined' );
ok( defined &format_referral_elem, 'format_referral_elem() is defined' );
ok( defined &format_template_elem, 'format_template_elem() is defined' );

{
  my ($asset_file, $ext, $assets_paths) = (
    'app/assets/stylesheets/application.css',
    '.css', [qw(app/assets/stylesheets/)]
  );
  my $expected_elem = {
    name => 'application.css',
    full_path => $asset_file,
    ext => $ext,
  };
  is_deeply(
    format_asset_elem($asset_file, $ext, $assets_paths),
    $expected_elem, 'format_asset_elem() works as expected'
  );
}

{
  my ($asset_name, $ext, $referral) = qw(
    application.css .css app/views/layouts/application.html.haml
  );
  my $expected_elem = {
    name => $asset_name,
    referral => $referral,
    ext => $ext,
  };
  is_deeply(
    format_referral_elem($asset_name, $ext, $referral),
    $expected_elem, 'format_referral_elem() works as expected'
  );
}

{
  my ($template_file, $asset_name) = qw(
    app/views/layouts/application.html.haml application.css
  );
  my $expected_elem = {
    name => $asset_name,
    full_path => $template_file,
  };
  is_deeply(
    format_template_elem($template_file, $asset_name),
    $expected_elem, 'format_template_elem() works as expected'
  );
}
