use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME           => 'MojoX::Renderer::Xslate',
    AUTHOR         => [ 'gray <gray@cpan.org>', 'hjansen <hjansen@cpan.org>' ],
    LICENSE        => 'perl',
    VERSION_FROM   => 'lib/MojoX/Renderer/Xslate.pm',
    ABSTRACT_FROM  => 'lib/MojoX/Renderer/Xslate.pm',
    PREREQ_PM      => {
        parent         => 0,
        Mojolicious    => 5.81,
        'Text::Xslate' => 0.2013,
        'Try::Tiny'    => 0,
    },
    BUILD_REQUIRES => {
        'Test::Mojo' => 0,
        'Test::More' => 0.82,
    },
    META_MERGE     => {
        resources  => {
            repository => 'http://github.com/gray/mojox-renderer-xslate',
        },
    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean          => { FILES => 'MojoX-Renderer-Xslate-*' },
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
