use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Net::LDAP::Server::Test',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/Net/LDAP/Server/Test.pm',
    ABSTRACT_FROM => 'lib/Net/LDAP/Server/Test.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'        => 0,
        'IO::Socket'        => 0,
        'IO::Select'        => 0,
        'Net::LDAP::Server' => '0.3',
        'Net::LDAP'         => 0,
        'Net::LDAP::SID'    => 0,
        'Data::Dump'        => 0,

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-LDAP-Server-Test-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/net-ldap-server-test',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Server-Test',
                    repository =>
                        'https://github.com/karpet/net-ldap-server-test',
                },
            }
            )
    ),
);
