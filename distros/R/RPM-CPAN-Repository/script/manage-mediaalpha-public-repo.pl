#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use RPM::CPAN::Repository;

my $action;
my $help;

GetOptions(
    'add'      => sub { $action = 'add' },
    'remove'   => sub { $action = 'remove' },
    'check'    => sub { $action = 'check' },
    'help|h'   => \$help,
) or die "Usage: $0 [--add|--remove|--check] [--help]\n";

if ($help || !$action) {
    print <<END;
Usage: $0 [--add|--remove|--check] [--help]

Options:
  --add      Install the MediaAlpha public RPM repository (default)
  --remove   Remove the MediaAlpha public RPM repository
  --check    Verify the repository is correctly configured
  --help     Show this help message

Must be run as root.
END
    exit 0;
}

die "Error: Must run as root\n" if $< != 0;

if ($action eq 'add') {
    RPM::CPAN::Repository::detect_al2023();
    RPM::CPAN::Repository::detect_architecture();
    RPM::CPAN::Repository::check_if_repo_dir_exists();
    RPM::CPAN::Repository::add_the_public_ma_repo();
}
elsif ($action eq 'remove') {
    RPM::CPAN::Repository::remove_the_public_ma_repo();
}
elsif ($action eq 'check') {
    RPM::CPAN::Repository::check_the_public_ma_repo();
}
