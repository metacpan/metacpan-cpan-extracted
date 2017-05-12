use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'Task::Digest',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Task/Digest.pm',
    ABSTRACT_FROM => 'lib/Task/Digest.pm',
    PREREQ_PM => {
        'Crypt::RIPEMD160'          => 0,
        'Digest::BLAKE'             => 0,
        'Digest::BMW'               => 0,
        'Digest::CubeHash::XS'      => 0,
        'Digest::ECHO'              => 0,
        'Digest::EdonR'             => 0,
        'Digest::Fugue'             => 0,
        'Digest::GOST'              => 0,
        'Digest::Groestl'           => 0,
        'Digest::Hamsi'             => 0,
        'Digest::JH'                => 0,
        'Digest::Keccak'            => 0,
        'Digest::Luffa'             => 0,
        'Digest::MD2'               => 0,
        'Digest::MD4'               => 0,
        'Digest::MD5'               => 0,
        'Digest::MD6'               => 0,
        'Digest::Perl::MD4'         => 0,
        'Digest::Perl::MD5'         => 0,
        'Digest::SHA'               => 0,
        'Digest::SHA1'              => 0,
        'Digest::SHA::PurePerl'     => 0,
        'Digest::SHAvite3'          => 0,
        'Digest::SIMD'              => 0,
        'Digest::Shabal'            => 0,
        'Digest::Skein'             => 0,
        'Digest::Whirlpool'         => 0,
    },
    BUILD_REQUIRES => { 'Test::More' => 0.82, },
    META_MERGE     => {
        resources => {
            repository => 'http://github.com/gray/task-digest',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Task-Digest-*' },
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
