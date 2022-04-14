#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use OPM::Installer::Utils::Config;

{
    package
        MyHomeDir;

    use File::Basename;
    use File::Spec;

    sub my_home { File::Spec->rel2abs( dirname __FILE__ ); };
}

$File::HomeDir::IMPLEMENTED_BY = 'MyHomeDir';

if ( open my $fh, '>', File::Spec->catfile( dirname( __FILE__ ), '.opminstaller.rc' ) ) {
    print {$fh} "repository=file://hallo/test
repository=http://opar.perl-services.de/1234
path=/local/app
";
    close $fh;
}

my $obj = OPM::Installer::Utils::Config->new;

isa_ok $obj, 'OPM::Installer::Utils::Config';

my $config       = $obj->rc_config;
my $config_check = {
    path  => '/local/app',
    repository => [
        'file://hallo/test',
        'http://opar.perl-services.de/1234',
    ],
};

is_deeply $config, $config_check;

done_testing();
