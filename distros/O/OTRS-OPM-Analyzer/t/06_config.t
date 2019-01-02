#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Basename;
use OTRS::OPM::Analyzer::Utils::Config;

# write default config file
my $dir = dirname $0;
mkdir File::Spec->catdir( $dir, 'conf' );

my $config_file = File::Spec->catfile( $dir, 'conf', 'base.yml' );

open my $fh, '>', $config_file;
print $fh q~---
path: test
app:
  name: OPAR
enum:
  - 1
  - 2

~;

close $fh;

my $config = OTRS::OPM::Analyzer::Utils::Config->new;
isa_ok $config, 'OTRS::OPM::Analyzer::Utils::Config';

is $config->get('path'), 'test';
is $config->get('app.name'), 'OPAR';
is $config->get('.app.name'), 'OPAR';
is $config->get('app..name'), 'OPAR';
is $config->get('.app..name'), 'OPAR';
is $config->get('test.name'), undef;
is $config->get('date'), undef;
is $config->get('.date'), undef;
is_deeply $config->get('enum'), [1,2];


{
    my $check = { path => 'test', app => { name => 'OPAR' }, enum => [1,2] };
    is_deeply $config->load( $config_file ), $check;
}

{
    $config->{_config} = undef;
    is $config->set('file', basename __FILE__ ), basename __FILE__;
    is $config->get('file'), basename __FILE__;

    is $config->set('test.name', 'anything' ), 'anything';
    is $config->get('test.name'), 'anything';

    is $config->set( undef, 'test' ), undef;

    is_deeply $config->set('test.array', [1,2]), [1,2];
    is_deeply $config->get('test.array'), [1,2];
    is_deeply $config->set('.test.array', [1,2]), [1,2];
    is_deeply $config->set('.test..array', [1,2]), [1,2];
    is_deeply $config->set('test..array', [1,2]), [1,2];
    is $config->set('test.array.name', 'MyArray'), undef;
}

{
    $config->{_config} = undef;
    is $config->get('path'), undef;
}

{
    my $error;
    eval {
        $config->load( undef );
    } or $error = $@;

    like $error, qr/\Ano config file given/;
}


done_testing();
