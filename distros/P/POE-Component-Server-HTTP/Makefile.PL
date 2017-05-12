use ExtUtils::MakeMaker;

eval {
    require POE::Component::Server::HTTP;
    if ($POE::Component::Server::HTTP::VERSION <= 0.05) {
        warn <<WARN;
---------------------------------------------------------------
Please read Changes as this new version has a changed interface
---------------------------------------------------------------
WARN
    }
};

WriteMakefile(
    NAME           => 'POE::Component::Server::HTTP',
    AUTHOR         => 'Arthur Bergman',
    VERSION_FROM   => 'lib/POE/Component/Server/HTTP.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/POE/Component/Server/HTTP.pm',
    PREREQ_PM      => {
        POE => '0.3007',    # KR_RUN is certainly newer than 0.27, and
                            # 0.3005 has a broken POE::Filter::HTTPD
        POE::API::Peek => 0,
        File::Spec   => 0,
        HTTP::Date   => 0,
        HTTP::Status => 0,
        YAML         => 0,
    },
   );
