use 5.010001;

use strict;
use warnings;
use version 0.77;

use ExtUtils::MakeMaker;

my $eumm_version = version->parse($ExtUtils::MakeMaker::VERSION);
my $prereq = {
    'Mojolicious' => '5.80',
};

if ($^O eq 'solaris') {
    # $prereq->{'Solaris::Procfs'} = 0.27;   # broken and unmaintained
}
elsif ($^O eq 'linux') {
    $prereq->{'Linux::Smaps'} = 0 if -e '/proc/self/smaps';
}
elsif ($^O eq 'netbsd') {
    die 'OS unsupported';
}
elsif ($^O =~ /(bsd|aix|darwin)/i) {
    $prereq->{'BSD::Resource'} = 0;
}
else {
    die 'OS unsupported';
}

my @args = (
    NAME           => 'Mojolicious::Plugin::SizeLimit',
    VERSION_FROM   => 'lib/Mojolicious/Plugin/SizeLimit.pm',
    ABSTRACT       => 'Terminate workers that grow too large',
    AUTHOR         => 'Bernhard Graf <graf@cpan.org>',
    LICENSE        => 'artistic_2',
    test           => {TESTS => 't/*.t'}
);

if ($eumm_version >= 6.46) {
    push @args,
        META_MERGE     => {
            requires   => {perl => '5.010001'},
            resources  => {
                license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
                bugtracker => 'https://github.com/augensalat/mojolicious-plugin-sizelimit/issues',
                repository => 'https://github.com/augensalat/mojolicious-plugin-sizelimit.git',
            },
        };
}

my %eumm_req = (
    'Config' => 0,
    'File::Spec::Functions' => 0,
    'File::Temp' => 0,
    'FindBin' => 0,
    'IO::Socket::INET' => 0,
    %$prereq,
);

if ($eumm_version >= 6.64) {
    push @args,
        PREREQ_PM => $prereq,
        TEST_REQUIRES => \%eumm_req;
}
elsif ($eumm_version >= 6.5503) {
    push @args,
        PREREQ_PM => $prereq,
        BUILD_REQUIRES => \%eumm_req;
}
else {
    push @args, PREREQ_PM => \%eumm_req;
}

WriteMakefile(@args);
