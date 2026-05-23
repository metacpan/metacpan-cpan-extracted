use strict;
use warnings;
use Test::More;
use Devel::CheckOS qw(os_is);

unless ( os_is('Linux') ) {
    plan skip_all => 'Detection tests only run on Linux';
}

use RPM::CPAN::Repository;

# detect_al2023: passes on AL2023, dies with a meaningful message elsewhere
eval { RPM::CPAN::Repository::detect_al2023() };
if ($@) {
    like( $@, qr/Amazon Linux/i, 'detect_al2023 identifies the OS in its error' );
} else {
    pass('detect_al2023 succeeded - running on Amazon Linux 2023');
}

# detect_architecture: passes on x86_64 or aarch64, dies with a meaningful message elsewhere
my $arch;
eval { $arch = RPM::CPAN::Repository::detect_architecture() };
if ($@) {
    like( $@, qr/x86_64.*aarch64|aarch64.*x86_64/, 'detect_architecture lists supported arches in its error' );
} else {
    like( $arch, qr/^(x86_64|aarch64)$/, "detect_architecture returned supported arch ($arch)" );
}

# check_if_repo_dir_exists: passes when /etc/yum.repos.d/ is present
eval { RPM::CPAN::Repository::check_if_repo_dir_exists() };
if ($@) {
    like( $@, qr|/etc/yum\.repos\.d|, 'check_if_repo_dir_exists reports path in its error' );
} else {
    pass('check_if_repo_dir_exists succeeded - /etc/yum.repos.d/ exists');
}

done_testing();
