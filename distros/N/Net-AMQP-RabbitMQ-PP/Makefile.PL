#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
 
install_share 'share';

WriteMakefile(
    NAME             => 'Net::AMQP::RabbitMQ::PP',
    VERSION_FROM     => 'lib/Net/AMQP/RabbitMQ/PP.pm',
    AUTHOR           => [
        'Eugene Marcotte <emarcotte@athenahealth.com>',
        'Lee Johnson <leejo@cpan.org>',
    ],
    LICENSE          => 'gpl_2',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
		'Net::AMQP'       => 0.06,
		'List::MoreUtils' => 0.25,
		'File::ShareDir'  => 1.00,
        'File::ShareDir::Install' => 0.11,
		'Try::Tiny'       => 0.12,
		'Socket::Linux'   => 0.01,
		'File::ShareDir::Install' => 0.10,
    },
    TEST_REQUIRES => {
        'Test::File::ShareDir' => 1.001001,
        'Test::Most'           => 0.31,
        'Test::Exception'      => 0.43,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Net::AMQP::RabbitMQ::PP',
            bugtracker => 'https://github.com/Humanstate/net-amqp-rabbitmq/issues',
            repository => 'https://github.com/Humanstate/net-amqp-rabbitmq'
        },
        repository => {
            type => 'git',
            url  => 'https://github.com/Humanstate/net-amqp-rabbitmq.git',
            web  => 'https://github.com/Humanstate/net-amqp-rabbitmq',
        },
    },
    test => {
        TESTS                => 't/*.t t/*/*.t t/*/*/*.t',
        RECURSIVE_TEST_FILES => 1,
    },
);

package MY;
use File::ShareDir::Install qw/ postamble /;

# vim: ts=4:sw=4:et
