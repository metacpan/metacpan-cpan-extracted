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
    NAME          => 'Net::LDAP::Class',
    AUTHOR        => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM  => 'lib/Net/LDAP/Class.pm',
    ABSTRACT_FROM => 'lib/Net/LDAP/Class.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'              => 0,
        'Data::Dump'              => 0,
        'Digest::SHA1'            => 0,
        'MIME::Base64'            => 0,
        'Rose::Object'            => 0,
        'Net::LDAP'               => 0,
        'Net::LDAP::SID'          => 0,
        'Net::LDAP::Server::Test' => 0.20,  # SID pack/unpack fixes in 0.20
        'Net::LDAP::Batch'        => 0,
        'Clone'                   => 0,

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-LDAP-Class-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/net-ldap-class',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Class',
                    repository =>
                        'https://github.com/karpet/net-ldap-class'
                },
            }
            )
    ),

);
