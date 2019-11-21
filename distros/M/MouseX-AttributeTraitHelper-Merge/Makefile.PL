use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.010001;
 
use ExtUtils::MakeMaker;
 
my %WriteMakefileArgs = (
    "ABSTRACT" => "Extend your attribute traits interface for Mouse",
    "AUTHOR" => "Nikolay Shulyakovskiy <n.shulyakovskiy\@corp.mail.ru>",
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => 0
    },
    "DISTNAME" => "MouseX-AttributeTraitHelper-Merge",
    "LICENSE" => "perl",
    "MIN_PERL_VERSION" => "5.010001",
    "NAME" => "MouseX::AttributeTraitHelper::Merge",
    "TEST_REQUIRES" => {
        "Test::More" => "0.88",
        "Mouse" => "2.5.9",
    },
    "VERSION" => "0.99",
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:my-mail-ru/MouseX-AttributeTraitHelper-Merge.git',
                web => 'https://github.com/my-mail-ru/MouseX-AttributeTraitHelper-Merge',
            }
        },
    },
    "test" => {
        "TESTS" => "t/*.t",
    }
);
 
$WriteMakefileArgs{PREREQ_PM} = delete $WriteMakefileArgs{TEST_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.63_03) };
delete $WriteMakefileArgs{CONFIGURE_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
$WriteMakefileArgs{INSTALLDIRS} = 'perl' if "$]" >= 5.006002 && "$]" <= 5.011000;
 
WriteMakefile(%WriteMakefileArgs);

