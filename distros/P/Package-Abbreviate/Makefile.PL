use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME          => 'Package::Abbreviate',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Package/Abbreviate.pm',
    ABSTRACT_FROM => 'lib/Package/Abbreviate.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
    },
    BUILD_REQUIRES => {
        'Test::More'          => '0.88',
        'Test::UseAllModules' => '0.10',
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Package-Abbreviate',
        },
    },
);

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}          if $eumm < 6.31;
delete $params{META_ADD}         if $eumm < 6.46;

if ($eumm < 6.52 && $params{CONFIGURE_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}          || {} },
        %{ $params{CONFIGURE_REQUIRES} },
    };
    delete $params{CONFIGURE_REQUIRES};
}
if ($eumm < 6.5503 && $params{BUILD_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}      || {} },
        %{ $params{BUILD_REQUIRES} },
    };
    delete $params{BUILD_REQUIRES};
}

WriteMakefile(%params);
