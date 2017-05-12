#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::Topsy',
    license             => 'perl',
    dist_author         => 'Jonathan Leto <jonathan@leto.net>',
    dist_abstract       => 'Perl Interface to the Otter API to Topsy',
    dist_version        => '0.03',
    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0.21,
    },
    requires => {
        'Moose'          => 0.78,
        'MooseX::Declare' => 0.30,
        'MooseX::Iterator'=> 0.11,
        'JSON::Any'      => 1.19,
        'URI::Escape'    => 0,
        'LWP::UserAgent' => 2.032,
    },
    add_to_cleanup      => [ 'Net::Topsy-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/leto/net-topsy/tree/master'
        },
    },
);

$builder->create_build_script();
print "Have a great day!\n";
