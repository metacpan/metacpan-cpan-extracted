use strict;
use warnings;

use Test::More tests => 34;
#use Test::More qw(no_plan);

use File::Temp ();
use Fatal qw(open close);
use Module::Starter::App;

# Change to a new temporary directory which will be cleaned up automatically
my $test_dir     = File::Temp::tempdir( CLEANUP => 1 );
my $dist_dirname = 'The-Test-Module';
my $dist_dir     = "${test_dir}/${dist_dirname}";
my $deb_name     = 'libthe-test-module-perl';

# Set up a configuration file to avoid being affected by local user
# config files
open my $config_fh, '>', "${test_dir}/config";
print $config_fh <<END_CONFIG;
author: Ethel the Aardvark
email: quantity-surveyor\@example.org
verbose: 1
dir: ${dist_dir}
plugins: Module::Starter::Plugin::DebPackage
END_CONFIG
close $config_fh;

$ENV{MODULE_STARTER_DIR} = $test_dir;

# Make sure helper function is working
my @config_lines = _read_file("${test_dir}/config");
my $config_content = _read_file("${test_dir}/config");

cmp_ok( $#config_lines, '==', 4
      , 'helper _read_file returns an array of lines in array context' );
like( $config_content, qr/^author.*DebPackage$/s
    , 'helper _read_file returns a string in scalar context' );

# Build a test instance
# This requires faking @ARGV as at least one argument is required
@ARGV = qw( --module The::Test::Module );
Module::Starter::App->run;

# Test the output files
ok( -d $dist_dir, "Distribution dir exists" );
ok( -d "${dist_dir}/debian", "debian dir exists" );

ok( -f "${dist_dir}/debian/compat", "compat file exists" );
my @compat_lines = _read_file("${dist_dir}/debian/compat");
is( $#compat_lines, 0, ' .. One line in compat file' );
like( $compat_lines[0], qr/^\d+$/, ' .. Single integer in compat file' );

ok( -f "${dist_dir}/debian/control", "control file exists" );
my @control_lines = _read_file("${dist_dir}/debian/control");
for my $header ( qw( Source
                     Section
                     Priority
                     Build-Depends
                     Build-Depends-Indep
                     Maintainer
                     Standards-Version
                     Homepage
                     Package
                     Architecture
                     Depends
                     Description ) ) {
  my @matches = grep { /^${header}:/ } @control_lines;
  is( @matches, 1, " .. control file has one ${header} line" );

  # Per-header tests
  if ( $header eq 'Source' ) {
    is( $matches[0], "Source: ${deb_name}\n"
      , " .. Source line has the correct deb name" );
  }
  elsif ( $header eq 'Maintainer' ) {
    is( $matches[0], "Maintainer: Ethel the Aardvark <quantity-surveyor\@example.org>\n"
      , " .. Maintainer line has the correct author details" );
  }
  elsif ( $header eq 'Homepage' ) {
    is( $matches[0], "Homepage: http://search.cpan.org/dist/${dist_dirname}\n"
      , " .. Homepage line has the correct address" );
  }
  elsif ( $header eq 'Package' ) {
    is( $matches[0], "Package: ${deb_name}\n"
      , " .. Package line has the correct deb name" );
  }
}

ok( -f "${dist_dir}/debian/changelog", "changelog file exists" );
my @changelog_lines = _read_file("${dist_dir}/debian/changelog");
like( $changelog_lines[0], qr/^${deb_name} /
    , " .. First line of changelog includes deb name" );
like( $changelog_lines[-1], qr/Ethel the Aardvark <quantity-surveyor\@example.org>/
    , " .. Last line of changelog includes author details" );

ok( -f "${dist_dir}/debian/copyright", "copyright file exists" );
my $copyright_content = _read_file("${dist_dir}/debian/copyright");
like( $copyright_content, qr/This is the debian package for the The::Test::Module module/
    , " .. copyright file introduces module by perl name" );
like( $copyright_content, qr/Ethel the Aardvark <quantity-surveyor\@example.org>/
    , " .. copyright file includes author details" );

ok( -f "${dist_dir}/debian/conffiles", "conffiles file exists" );
ok( -z "${dist_dir}/debian/conffiles", " .. conffiles is empty" );

ok( -f "${dist_dir}/debian/rules", "rules file exists" );
my $rules_content = _read_file("${dist_dir}/debian/rules");
like( $rules_content, qr{This debian/rules file is provided as a template for normal perl}
    , " .. rules file starts with expected intro" );

# Helper functions
sub _read_file {
  my ($filepath) = @_;

  open my $fh, '<', $filepath;

  if ( wantarray() ) {
    my @lines = <$fh>;
    return @lines;
  }
  else {
    my $content = do { local $/; <$fh>; };
    return $content;
  }
}
