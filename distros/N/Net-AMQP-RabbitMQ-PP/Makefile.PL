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
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 6.52,
        'File::ShareDir::Install' => 0.13,
    },
    PREREQ_PM => {
		'Net::AMQP'       => 0.06,
		'List::MoreUtils' => 0.25,
		'File::ShareDir'  => 1.116,
		'Try::Tiny'       => 0.12,
		'Socket::Linux'   => 0.01,
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
            bugtracker => 'https://github.com/PayProp/net-amqp-rabbitmq/issues',
            repository => 'https://github.com/PayProp/net-amqp-rabbitmq'
        },
        repository => {
            type => 'git',
            url  => 'https://github.com/PayProp/net-amqp-rabbitmq.git',
            web  => 'https://github.com/PayProp/net-amqp-rabbitmq',
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
