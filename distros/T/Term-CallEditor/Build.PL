#!perl
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

# there is also Devel::CheckOS but the use-devel-assertos script seems a
# bit too complicated every time I look at it. so...
if ($^O =~ /MSWin32/) {
    print
      "Sorry, no automated install on Windows due to lack of POSIX::tcgetpgrp.\n";
    exit 0;
}

my $builder = Module::Build->new(
    module_name        => 'Term::CallEditor',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Term/CallEditor.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Cwd' => '0', 'Test::Most' => '0', },
    requires           => {
        'perl'       => 5.008,
        'File::Temp' => 0.18,
        'IO::Handle' => 0,
    },
    test_requires  => { 'Test::More' => 0.72, },
    sign           => 1,
    add_to_cleanup => ['Term-CallEditor-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://github.com/thrig/Term-CallEditor' } },
);

$builder->create_build_script();
