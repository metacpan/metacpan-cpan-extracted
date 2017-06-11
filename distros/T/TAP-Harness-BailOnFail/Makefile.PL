use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'TAP::Harness::BailOnFail',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/TAP/Harness/BailOnFail.pm',
    ABSTRACT_FROM => 'lib/TAP/Harness/BailOnFail.pm',
    PREREQ_PM     => {
        'TAP::Harness::Restricted' => 0,
    },
    BUILD_REQUIRES => { 'Test::More' => 0.98, },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/gray/tap-harness-bailonfail',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'TAP-Harness-BailOnFail-*' },
);

my $eumm_version =  do {
    no warnings 'numeric';
    eval $ExtUtils::MakeMaker::VERSION;
};
delete $conf{META_MERGE} if $eumm_version < 6.46;
$conf{PREREQ_PM} = {
    %{ $conf{PREREQ_PM} || {} }, %{ delete $conf{BUILD_REQUIRES} },
} if ($conf{BUILD_REQUIRES} and $eumm_version < 6.5503);

WriteMakefile(%conf);


sub MY::postamble {
    return <<"    MAKE_FRAG";
authortest:
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"
    MAKE_FRAG
}

sub MY::dist_test {
    my $self = shift;
    return $self->MM::dist_test . <<"    MAKE_FRAG";
\tcd \$(DISTVNAME) && \$(MAKE) authortest \$(PASTHRU)
    MAKE_FRAG
}
