use 5.006;
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
    NAME               => 'Net::LDAP::SID',
    AUTHOR             => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM       => 'lib/Net/LDAP/SID.pm',
    ABSTRACT_FROM      => 'lib/Net/LDAP/SID.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {

        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Net-LDAP-SID-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/net-ldap-sid',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-SID',
                    repository => 'https://github.com/karpet/net-ldap-sid'
                },
            }
            )
    ),
);
