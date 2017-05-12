use 5.010001;
use ExtUtils::MakeMaker "6.46";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojo::IRC::Server::Chinese',
    VERSION_FROM      => 'lib/Mojo/IRC/Server/Chinese.pm', # finds $VERSION
    DISTNAME            => 'Mojo-IRC-Server-Chinese',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "Mojolicious"           => '6.11',
        "Parse::IRC"            => '1.20',
        "Encode::Locale"        => '1.05',
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojo-IRC-Server-Chinese-* MANIFEST' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/Mojo-IRC-Server-Chinese.git',
                web     =>  'https://github.com/sjdy521/Mojo-IRC-Server-Chinese',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       ABSTRACT       => 'A Chinese IRC server base on Mojolicious',
       AUTHOR         => 'sjdy521 <sjdy521@163.com>') : ()),
);
