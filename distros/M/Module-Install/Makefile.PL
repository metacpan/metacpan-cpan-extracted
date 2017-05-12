use strict;
use warnings;

# NOTE: Module::Install's Makefile.PL needs this "use lib 'lib'" to
# bootstrap itself. Other module distributions using Module::Install
# do not need it. It causes inc::Module::Install to load from the
# (unique to this distribution) file ./lib/inc/Module/Install.pm instead
# of the system inc::Module::Install or the bundled ./inc/Module/Install.pm
use lib 'lib';
use inc::Module::Install;

name          'Module-Install';
author        'Adam Kennedy <adamk@cpan.org>';
perl_version  '5.006';
all_from      'lib/Module/Install.pm';

requires      'Devel::PPPort'       => '3.16';
requires      'ExtUtils::Install'   => '1.52';
requires      'ExtUtils::MakeMaker' => '6.59';
requires      'ExtUtils::ParseXS'   => '2.19';
requires      'File::Path'          => 0; #needs version
requires      'File::Remove'        => '1.42';
requires      'File::Spec'          => '3.28';
requires      'Module::Build'       => '0.29';
requires      'Module::CoreList'    => '2.17';
requires      'Module::ScanDeps'    => '1.09'; #detects prereqs better
requires      'Parse::CPAN::Meta'   => '1.4413';
requires      'Win32::UTCFileTime'  => '1.56' if win32;
requires      'YAML::Tiny'          => '1.38';

test_requires 'Test::Harness'       => '3.13';
test_requires 'Test::More'          => '0.86';
test_requires 'autodie'             => '0';

recommends    'Archive::Zip'        => '1.37';
recommends    'File::HomeDir'       => '1';
recommends    'JSON'                => '2.9';
recommends    'LWP::Simple'         => '6.00';
recommends    'LWP::UserAgent'      => '6.05';
recommends    'PAR::Dist'           => '0.29';
 
# Remove some extra test files
clean_files( qw{ t/Foo } );

# Test configure_requires support (also needed by WriteMyMeta)
configure_requires 'YAML::Tiny' => '1.33';

# Makes the recursive test script run
# (to test recursive test support)
tests_recursive;

# This is a normal CPAN module
install_as_cpan;

# Normally this shouldn't be done in here, it should be done
# by release automation. This is mostly for testing reasons.
repository 'https://github.com/Perl-Toolchain-Gang/Module-Install.git';

# All of our dependencies are the same on all platforms
dynamic_config 0;

add_metadata x_contributors => [ # manually added, from git shortlog -e -s -n
    'Adam Kennedy <adam@ali.as>',
    'Kenichi Ishigaki <ishigaki@cpan.org>',
    'Alexandr Ciornii <alexchorny@gmail.com>',
    'Chris \'BinGOs\' Williams <chris@bingosnet.co.uk>',
    'Karen Etheridge <ether@cpan.org>',
    'Paul Fenwick <pjf@perltraining.com.au>',
    'bowtie <bowtie@cpan.org>',
    'Matt S Trout <dbix-class@trout.me.uk>',
    'Dan Book <grinnz@grinnz.com>',
    'Alberto Simoes <ambs@cpan.org>',
    'Christian Walde <walde.christian@googlemail.com>',
    'Ricardo Signes <rjbs@cpan.org>',
    'Ingy <ingy@ingy.net>', # 'Ingy döt Net <ingy@ingy.net>',
    'Hans Dieter Pearcey <hdp@cpan.org>',
    'Avar Arnfjord Bjarmason <avarab@gmail.com>', # 'Ævar Arnfjörð Bjarmason <avarab@gmail.com>',
    'Curtis Jewell <csjewell@cpan.org>',
    'Graham Knop <haarg@haarg.org>',
    'Olivier Mengue <dolmen@cpan.org>', # 'Olivier Mengué <dolmen@cpan.org>',
    'Rafael Kitover <rkitover@gmail.com>',
    'gregor herrmann <gregoa@debian.org>',
    'Alex Vandiver <github@chmrr.net>',
    'Ash Berlin <ash_github@firemirror.com>',
    'Craig A. Berry <craigberry@mac.com>',
    'Dan Brook <dbrook@venda.com>',
    'David Golden <dagolden@cpan.org>',
    'Gabor Szabo <szabgab@gmail.com>',
    'Graham Ollis <plicease@cpan.org>',
    'Joshua ben Jore <twists@gmail.com>',
    'Kang-min Liu <gugod@gugod.org>',
    'Kent Fredric <kentfredric@gmail.com>',
    'Leo Lapworth <leo@cuckoo.org>',
    'Marcel Grunauer <hanekomu@gmail.com>', # 'Marcel Grünauer <hanekomu@gmail.com>',
    'Peter Rabbitson <ribasushi@cpan.org>',
    'Thomas Sibley <tsibley@cpan.org>',
    'Tokuhiro Matsuno <tokuhirom@cpan.org>',
    'Tom Wyant <wyant@cpan.org>',
];

WriteAll;

my $readme_from = 'lib/Module/Install.pod';
# pod2text is in https://metacpan.org/release/podlators
system("pod2text $readme_from > README")
  if -f '.gitignore' and (not -e 'README' or (stat('README'))[9] < (stat($readme_from))[9]);
