use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::NATS2::Client',
    VERSION_FROM => 'lib/Net/NATS2/Client.pm',
    ABSTRACT     => 'A Perl client for the NATS messaging system',
    AUTHOR       => 'Kostiantyn Cherednichenko <dshadowukraine@gmail.com>',
    LICENSE      => 'mit',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version   => 2},
        no_index       => {directory => [qw(examples t)], package => [qw(Net::NATS2::URI)],},
        prereqs        => {runtime   => {requires => {perl => '5.010'}}},
        resources      => {
            bugtracker => {web => 'https://github.com/dshadow/perl-nats2/issues'},
            homepage   => 'https://github.com/dshadow/perl-nats2',
            license    => ['https://opensource.org/license/mit'],
            repository => {
                type => 'git',
                url  => 'git@github.com:dshadow/perl-nats2.git',
                web  => 'https://github.com/dshadow/perl-nats2',
            }
        }
    },
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM        => {'IO::Socket::INET' => 0, 'JSON' => 0, 'URI' => 0,},
);
