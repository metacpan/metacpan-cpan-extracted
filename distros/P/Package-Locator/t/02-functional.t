#!perl

use strict;
use warnings;

use FindBin qw($Bin);
use Path::Class;
use Test::More (tests => 10);

use Package::Locator;

#------------------------------------------------------------------------------

my $found;
my $repos_dir = dir($Bin)->as_foreign('Unix')->stringify() . '/repos';
my @repos_urls = map { URI->new("file://$repos_dir/$_") } qw(a b);

my $locator = Package::Locator->new( repository_urls => \@repos_urls );

#------------------------------------------------------------------------------
# Locate first...


$found = $locator->locate(package => 'Foo');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz",
   'Locate by package name');

$found = $locator->locate(package => 'Bar');
is($found, undef, 'Locate non-existant package name');

$found = $locator->locate(distribution => 'A/AU/AUTHOR/Foo-1.0.tar.gz');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz",
    'Locate by dist path');

$found = $locator->locate(distribution => 'A/AU/AUTHOR/Bar-1.0.tar.gz');
is($found, undef, 'Locate non-existant dist path');

$found = $locator->locate(package => 'Foo', version => 2.0);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
    'Locate by package name and decimal version');

$found = $locator->locate(package => 'Foo', version => 'v1.2.0');
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
    'Locate by package name and vstring');

$found = $locator->locate(package => 'Foo', version => 3.0);
is($found, undef, 'Locate non-existant version');

#------------------------------------------------------------------------------
# Locate latest...

$found = $locator->locate(package => 'Foo', latest => 1);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
   'Locate latest by package name');

$found = $locator->locate(package => 'Foo', version => 1.0, latest => 1);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
   'Locate latest by package name and decimal version');

$found = $locator->locate(package => 'Foo', version => 'v1.0.5', latest => 1);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
   'Locate latest by package name and vstring');





