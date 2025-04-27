use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %WriteMakefileArgs = (
    'NAME'         => 'Net::Patricia',
    'VERSION_FROM' => 'Patricia.pm',     # finds $VERSION
    'ABSTRACT'     => 'Patricia Trie for fast IP address lookups',
    'AUTHOR'       => 'Dave Plonka <plonka@doit.wisc.edu>',
    'LICENSE'      => 'gpl_2',           # and BSD two-clause (see below)
    'MYEXTLIB'     => 'libpatricia/libpatricia$(LIB_EXT)',
    'PREREQ_PM'    => {
        'Carp'            => 0,
        'Exporter'        => 0,
        'Net::CIDR::Lite' => '0.20',
        'Socket'          => 0,
        'Socket6'         => 0,
        'version'         => 0,
    },
    'TEST_REQUIRES' => {
        'Storable'   => 0,
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        license     => ['freebsd'],
        resources   => {
            bugtracker => {
                web =>
                    'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Patricia',
            },
            repository => {
                type => 'git',
                web  => 'https://github.com/tobez/Net-Patricia',
                url  => 'git://github.com/tobez/Net-Patricia.git',
            },
        },
    },
);

my %FallbackPrereqs = (
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{$WriteMakefileArgs{TEST_REQUIRES}},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $WriteMakefileArgs{META_MERGE};
}

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
'
$(MYEXTLIB): libpatricia/Makefile
	cd libpatricia && $(MAKE) $(PASTHRU)
';
}
