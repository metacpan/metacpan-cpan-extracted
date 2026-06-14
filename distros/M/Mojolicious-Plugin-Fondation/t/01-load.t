#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp 'tempdir';
use File::Spec;
use FindBin;

# Add lib directories to @INC so plugins can be found
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

# Use test helper for creating apps with temporary home
use Mojolicious::Plugin::Fondation::TestHelper qw(create_test_app);

# Load the Fondation plugin
use_ok 'Mojolicious::Plugin::Fondation';

# Create a temporary directory for config file
my $tempdir = tempdir(CLEANUP => 1);
my $conf_file = File::Spec->catfile($tempdir, 'test.conf');

# Write test configuration with dependencies
write_config($conf_file);

# Create a test Mojolicious app with temporary home directory
my $app = create_test_app($tempdir);
my $t = Test::Mojo->new($app);

# Load Config plugin with our config file
$t->app->plugin('Config' => {file => $conf_file});

# Load Fondation plugin (should use config from file)
$t->app->plugin('Fondation');

# # Get Fondation instance via helper
my $fondation = $t->app->manager;
ok($fondation, 'Fondation plugin loaded and accessible via helper');
isa_ok($fondation, 'Mojolicious::Plugin::Fondation::Manager', 'Fondation is the manager');


# Check Fondation dependencies

done_testing();

sub write_config {
    my ($file) = @_;
    open my $fh, '>', $file or die "Cannot write $file: $!";
    print $fh <<'CONFIG';
{
 'Fondation' => {
     dependencies => [
         'Fondation::User',
         'Fondation::Authorization',
    ]
  },
 'Fondation::Authorization' => {
     dependencies => [
         'Fondation::Role',
         'Fondation::Permission',
    ]
  },
}
CONFIG
    close $fh;
}
