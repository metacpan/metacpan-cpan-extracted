#!/usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny 'capture_stdout';
use Cwd 'abs_path';
use File::Basename;
use Test::More tests => 11;

BEGIN {
    eval "use Perl::PrereqInstaller";
}

# FYI: You owe me $3.50 if you put 'A::Non::Existent::Perl::Module' on CPAN.
require A::Non::Existent::Perl::Module if 0;

my $installer = Perl::PrereqInstaller->new;

$installer->scan($0);
$installer->{_not_installed}{'--version'} = 1;

my @not_installed = $installer->not_installed;
my @installed     = $installer->previously_installed;

diag('Ignore the warnings about A::Non::Existent::Perl::Module not being found. This is intentional.');
$installer->cpanm;

my @newly_installed     = $installer->newly_installed;
my @failed_install      = $installer->failed_install;
my @still_not_installed = $installer->not_installed;

isa_ok( $installer, 'Perl::PrereqInstaller' );
is_deeply(
    \@installed,
    [ 'Capture::Tiny', 'Cwd', 'File::Basename', 'Test::More' ],
    'Find modules that are already installed'
);
is_deeply(
    \@not_installed,
    [ '--version', 'A::Non::Existent::Perl::Module' ],
    'Find modules that are not yet installed'
);
is_deeply( \@newly_installed, ['--version'],
    'cpanm is installed and report newly installed modules' );
is_deeply(
    \@failed_install,
    ['A::Non::Existent::Perl::Module'],
    'Report which modules fail to install'
);
is_deeply(
    \@still_not_installed,
    ['A::Non::Existent::Perl::Module'],
    'Report which modules still need to be installed'
);

my $bad_file = 't/bad/scan-error.pl';
my $abs_path = abs_path($bad_file);
$installer->scan($bad_file);
my @scan_errors = $installer->scan_errors;
is_deeply( \@scan_errors, [$abs_path], 'Report files with scan errors' );

my $test_path = ( fileparse( abs_path($0) ) )[1];
my $report_got = capture_stdout { $installer->report; };
my $report_expect = <<EOF;
File parsing errors:
  ${test_path}bad/scan-error.pl

Modules to install:
  A::Non::Existent::Perl::Module

Successfully installed:
  --version

Failed to install:
  A::Non::Existent::Perl::Module

EOF
is( $report_got, $report_expect, 'Summary report' );

my $deep_installer = Perl::PrereqInstaller->new;
$deep_installer->scan("t/deep");
my @not_installed_deep = $deep_installer->not_installed;
my @installed_deep     = $deep_installer->previously_installed;

is_deeply( \@installed_deep, ['CausesWarning'],
    'Find modules that are already installed deep' );
is_deeply(
    \@not_installed_deep,
    ['Another::Non::Existent::Perl::Module'],
    'Find modules that are not yet installed deep'
);

my $deep_report_got = capture_stdout {
    $deep_installer->report(
        {   'not_installed'        => 0,
            'previously_installed' => 0,
            'newly_installed'      => 0,
            'failed_install'       => 0,
            'scan_errors'          => 0,
            'scan_warnings'        => 1,
        }
    );
};
my $deep_report_expect_pt1 = <<EOF;
Warnings during scan:
  ${test_path}deep/deep-script.pl
EOF
my $deep_report_expect_pt2 = <<'EOF';
  | - "my" variable $x masks earlier declaration in same scope at
  |   CausesWarning.pm line 6.

EOF
my $deep_report_expect = $deep_report_expect_pt1 . $deep_report_expect_pt2;
is( $deep_report_got, $deep_report_expect,
    'Summary report for scan warnings' );

