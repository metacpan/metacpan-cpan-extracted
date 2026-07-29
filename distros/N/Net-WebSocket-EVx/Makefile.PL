use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker 'ev_args';
use Alien::Base::Wrapper ();

my %args = (
    NAME             => 'Net::WebSocket::EVx',
    VERSION_FROM     => 'lib/Net/WebSocket/EVx.pm',
    ABSTRACT_FROM    => 'lib/Net/WebSocket/EVx.pod',
    AUTHOR           => 'Yegor Korablev <egor@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'  => '6.64', # TEST_REQUIRES
        'Alien::Base::Wrapper' => '0',
        'Alien::Wslay'         => '0.3',  # bundles wslay 1.1.1; we use 1.1.0+ API
        'EV::MakeMaker'        => '0',
        'EV'                   => '4.0',
    },
    PREREQ_PM => {
        'EV'       => '4.0',  # EVAPI is used at runtime too, and needs ev_cleanup
        'Carp'     => '0',
        'Exporter' => '0',
        'XSLoader' => '0',
        'constant' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'       => '0.94', # subtest (done_testing needs only 0.88)
        'Devel::Peek'      => '0',
        'Fcntl'            => '0',
        'IO::Socket::INET' => '0',
        'Net::EmptyPort'   => '0',
        'POSIX'            => '0',
        'Socket'           => '0',
        'utf8'             => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/Net-WebSocket-EVx.git',
                web  => 'https://github.com/vividsnow/Net-WebSocket-EVx',
            },
            bugtracker => { web => 'https://github.com/vividsnow/Net-WebSocket-EVx/issues' },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
    clean => { FILES => 'Net-WebSocket-EVx-*' },
);

# core since 5.13.9; without it we just ship no provides
if (eval { require Module::Metadata; 1 }) {
    $args{META_MERGE}{provides} = Module::Metadata->provides(version => 2, dir => 'lib');
}

# TEST_REQUIRES needs ExtUtils::MakeMaker 6.64
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    $args{PREREQ_PM} = { %{ $args{PREREQ_PM} }, %{ delete $args{TEST_REQUIRES} } };
}

# Alien::Base::Wrapper rewrites CONFIGURE_REQUIRES in place and lowers ours
# (Alien::Wslay back to 0), so keep a copy and restore the higher minimums after
my %wanted = %{ $args{CONFIGURE_REQUIRES} };

my %mm = Alien::Base::Wrapper->new('Alien::Wslay')->mm_args2(ev_args(%args));

for my $module (keys %wanted) {
    my ($mine, $theirs) = ($wanted{$module}, $mm{CONFIGURE_REQUIRES}{$module});
    my $comparable = defined($theirs)
        && $theirs =~ /^[0-9]+(?:\.[0-9]+)?$/ && $mine =~ /^[0-9]+(?:\.[0-9]+)?$/;
    $mm{CONFIGURE_REQUIRES}{$module} = ($comparable && $theirs > $mine) ? $theirs : $mine;
}

WriteMakefile(%mm);
