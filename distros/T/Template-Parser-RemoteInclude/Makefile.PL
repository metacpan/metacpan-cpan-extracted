use strict;
use warnings;

use inc::Module::Install 0.91;

use Module::Install::AuthorRequires;
use Module::Install::CheckConflicts;
use Module::Install::AuthorTests;

perl_version '5.010001';

name 'TemplateParserRemoteInclude';
all_from 'lib/Template/Parser/RemoteInclude.pm';

requires 'namespace::autoclean'   => '0';
requires 'AnyEvent'          => '0';
requires 'AnyEvent::Curl::Multi'   => '1.1';
requires 'Template'     => '0';
requires 'HTTP::Request'   => '0';
requires 'Scalar::Util'   => '0';
requires 'Try::Tiny'   => '0';
requires 'Sub::Install'   => '0';

resources(
    'license'    => 'http://dev.perl.org/licenses/',
    'repository' => 'git@github.com:mrRico/Template-Parser-RemoteInclude.git',
);

auto_install;
WriteAll;
