use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Net::Server::Framework',
    AUTHOR        => 'Lenz Gschwendtner <lenz@springtimesoft.com>',
    VERSION_FROM  => 'lib/Net/Server/Framework.pm',
    ABSTRACT_FROM => 'lib/Net/Server/Framework.pm',
    PL_FILES      => {},
    PM            => {
        'lib/Net/Server/Framework.pm' => '$(INST_LIBDIR)/Net/Server/Framework.pm',
        'lib/Net/Server/Framework/Auth.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Auth.pm',
        'lib/Net/Server/Framework/Client.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Client.pm',
        'lib/Net/Server/Framework/Config.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Config.pm',
        'lib/Net/Server/Framework/Crypt.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Crypt.pm',
        'lib/Net/Server/Framework/DB.pm' => '$(INST_LIBDIR)/Net/Server/Framework/DB.pm',
        'lib/Net/Server/Framework/Errorcodes.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Errorcodes.pm',
        'lib/Net/Server/Framework/Format.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Format.pm',
        'lib/Net/Server/Framework/Spooler.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Spooler.pm',
        'lib/Net/Server/Framework/Validate.pm' => '$(INST_LIBDIR)/Net/Server/Framework/Validate.pm',
        },
    PREREQ_PM     => {
        'Test::More'          => 0,
        'Net::Server'         => 0,
        'Crypt::CBC'          => 0,
        'MIME::Base64'        => 0,
        'Digest::MD5'         => 0,
        'DBI'                 => 0,
        'Data::FormValidator' => 0,
        'Data::Serializer'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-Server-Framework-*' },
);
