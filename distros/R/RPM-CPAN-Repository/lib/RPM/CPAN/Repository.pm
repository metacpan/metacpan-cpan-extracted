package RPM::CPAN::Repository;

use strict;
use warnings;
use Config::Tiny;
use File::Basename qw(dirname);
use POSIX qw(uname);

our $VERSION = '0.0.1';

our $REPO_FILE   = '/etc/yum.repos.d/mediaalpha-public.repo';
my $REPO_CONTENT = <<'END';
[mediaalpha-public-perl]
name     = mediaalpha-public-perl-5.42.2
baseurl  = https://mediaalpha-public-rpm-repo.s3.amazonaws.com/perl/5.42.2/$basearch
gpgcheck = 1
gpgkey   = https://mediaalpha-public-rpm-repo.s3.amazonaws.com/RPM-GPG-KEY-mediaalpha
END

# we only support AL2023
sub detect_al2023 {
    my $os_release = '/etc/os-release';

    my $config = Config::Tiny->read($os_release)
        or die "Can't read $os_release: " . Config::Tiny->errstr . "\n";

    my $name    = $config->{_}{NAME}    // '';
    my $version = $config->{_}{VERSION} // '';

    # Strip surrounding quotes if present
    $name    =~ s/^"(.*)"$/$1/;
    $version =~ s/^"(.*)"$/$1/;

    unless ($name =~ /amazon linux/i) {
        die "Error: This script requires Amazon Linux (found: $name)\n";
    }

    if ($version ne '2023') {
        die "Error: This script requires Amazon Linux 2023 (found: Amazon Linux $version)\n";
    }

    print "OK: Amazon Linux 2023 detected\n";
}

# supports x86_64 and aarch64 (Graviton)
sub detect_architecture {
    my (undef, undef, undef, undef, $arch) = uname();

    unless ($arch eq 'x86_64' || $arch eq 'aarch64') {
        die "Error: Unsupported architecture (found: $arch, supported: x86_64, aarch64)\n";
    }

    print "OK: $arch architecture detected\n";
    return $arch;
}

sub check_if_repo_dir_exists {
    my $dir = dirname($REPO_FILE);
    unless (-d $dir) {
        die "Error: $dir directory does not exist\n";
    }
}

sub add_the_public_ma_repo {
    open(my $fh, '>', $REPO_FILE) or die "Can't write $REPO_FILE: $!\n";
    print $fh $REPO_CONTENT;
    close($fh);
    print "OK: Wrote $REPO_FILE\n";
}

sub check_the_public_ma_repo {
    open(my $fh, '<', $REPO_FILE) or die "Error: $REPO_FILE does not exist or can't be read: $!\n";
    my $existing = do { local $/; <$fh> };
    close($fh);

    if ($existing eq $REPO_CONTENT) {
        print "OK: $REPO_FILE exists and is correct\n";
    } else {
        die "Error: $REPO_FILE exists but content differs from expected\n";
    }
}

sub remove_the_public_ma_repo {
    unless (-f $REPO_FILE) {
        print "OK: $REPO_FILE does not exist (nothing to remove)\n";
        return;
    }

    unlink($REPO_FILE) or die "Error: Failed to remove $REPO_FILE: $!\n";
    print "OK: Successfully removed $REPO_FILE\n";
}

1; # Must return true
__END__

=head1 NAME

RPM::CPAN::Repository - Manage the MediaAlpha public RPM repository

=head1 VERSION

0.0.1

=head1 SYNOPSIS

    use RPM::CPAN::Repository;

    RPM::CPAN::Repository::detect_al2023();
    RPM::CPAN::Repository::detect_architecture();
    RPM::CPAN::Repository::check_if_repo_dir_exists();
    RPM::CPAN::Repository::add_the_public_ma_repo();

=head1 DESCRIPTION

C<RPM::CPAN::Repository> provides functions to install, verify, and remove the
MediaAlpha public RPM repository configuration on Amazon Linux 2023 hosts
(x86_64 and aarch64/Graviton).

=head1 FUNCTIONS

=head2 detect_al2023

Reads C</etc/os-release> and dies unless the host is Amazon Linux 2023.

=head2 detect_architecture

Calls C<uname(2)> and dies unless the architecture is C<x86_64> or C<aarch64>.
Returns the detected architecture string.

=head2 check_if_repo_dir_exists

Dies unless the C</etc/yum.repos.d> directory exists.

=head2 add_the_public_ma_repo

Writes the MediaAlpha public RPM repository configuration to
C</etc/yum.repos.d/mediaalpha-public.repo>.

=head2 check_the_public_ma_repo

Reads the repo file and dies if its content differs from the expected template.

=head2 remove_the_public_ma_repo

Removes the repo file if it exists; silently succeeds if the file is absent.

=head1 AUTHOR

Labros Chaidas <labros@mediaalpha.com>

=head1 LICENSE

This software is licensed under the GNU General Public License, version 3.
See the F<LICENSE> file distributed with this software for full details.

=cut
