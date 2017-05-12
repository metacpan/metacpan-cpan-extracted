use v5.10;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'Object-Signature-Portable';
all_from 'lib/Object/Signature/Portable.pm';
author q{Robert Rothenberg <rrwo@cpan.org>};
license 'artistic_2';

perl_version 5.010;

tests_recursive('t');

#tests_recursive('xt');

resources(
    #homepage   => 'http://yourwebsitehere.com',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'git://github.com/robrwo/Object-Signature-Portable.git',

#   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Signature-Portable',
);

configure_requires();

build_requires();

requires(
    'Crypt::Digest'  => 0,
    'Exporter::Lite' => 0,
    'JSON::MaybeXS'  => 0,
    'version'        => 0.77,
);

test_requires(
    'Test::Differences' => 0,    # seems to be required for some cpantesters
    'Test::Most'        => 0,
    'Test::Warnings'    => 0,
    'if'                => 0,
);

install_as_cpan;
auto_install;
WriteAll;
