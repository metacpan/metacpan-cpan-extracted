use strict;
use warnings;
use Module::Build;

# Check whether we're on one of the more popular
# non-POSIX systems before building

if ($^O =~ m/^(?:mswin32|dos|macos|os2|cygwin|v[mo]s|riscos|amigaos|beos|mpeix)$/) {
    die "NA: requires POSIX 1b platform";
}

my $builder = Module::Build->new(
                                 module_name         => 'POSIX::SchedYield',
                                 license             => 'gpl',
                                 dist_author         => 'Marc Beyer <japh@tirwhan.org>',
                                 dist_version_from   => 'lib/POSIX/SchedYield.pm',
                                 xs_files            => { 'SchedYield.xs' => 'lib/POSIX/SchedYield.xs' },
                                 include_dirs        => ['.'],
                                 requires => {
                                              'Test::More' => 0,
                                              'version'    => 0,
                                          },
                                 add_to_cleanup      => [ 'POSIX-SchedYield-*' ],
                             );

$builder->create_build_script();
