#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Protocol::XMLRPC',
    VERSION_FROM => 'lib/Protocol/XMLRPC.pm',
    ABSTRACT =>
      'Asynchronous, web framework agnostic XML-RPC implementation ',
    AUTHOR => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/protocol-xmlrpc'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'MIME::Base64' => 0,
        'Test::More'   => 0,
        'Time::Local'  => 0,
        'XML::LibXML'  => 0,
    },
    clean => {FILES => 'Protocol-XMLRPC-*'},
    test  => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);
