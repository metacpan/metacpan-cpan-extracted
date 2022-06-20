use 5.008_007;
use ExtUtils::MakeMaker;

use strict;
use warnings;

use SPVM::Builder::Util::API;

WriteMakefile(
    NAME              => 'SPVM::Resource::Zlib',
    VERSION_FROM      => 'lib/SPVM/Resource/Zlib.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl_5',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SPVM/Resource/Zlib.pm', # retrieve abstract from module
       AUTHOR         => 'Yuki Kimoto<kimoto.yuki@gmail.com>') : ()),
    test => {TESTS => 't/*.t'},
    clean => {FILES => ".spvm_build"},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yuki-kimoto/Perl-SPVM-Resource-Zlib.git',
                web  => 'https://github.com/yuki-kimoto/Perl-SPVM-Resource-Zlib',
            },
        },
    },
    PREREQ_PM => {
        'SPVM'              => '0.9500',
    },
);

1;
