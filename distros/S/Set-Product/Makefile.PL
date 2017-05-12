use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'Set::Product',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Set/Product.pm',
    ABSTRACT_FROM => 'lib/Set/Product.pm',
    PREREQ_PM     => {
        Exporter       => '5.57',
        'Scalar::Util' => 0,
    },
    BUILD_REQUIRES => { 'Test::More' => 0.98, },
    META_MERGE     => {
        recommends => { 'Set::Product::XS' => 0, },
        resources => {
            repository => 'https://github.com/gray/set-product',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Set-Product-*' },
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
