use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Templated';
all_from 'lib/MooseX/Templated.pm';
license 'perl';

requires 'Moose'                        => '1.0';
requires 'MooseX::Types::Path::Class';
requires 'Path::Class'                  => '0.16';
requires 'MooseX::Role::Parameterized';
requires 'MooseX::Types::Path::Class';
requires 'namespace::autoclean';
requires 'Template'                     => '2.20';

test_requires 'Test::More';
test_requires 'Test::Warn';

tests_recursive();

WriteAll();

if ($Module::Install::AUTHOR) {
	system( 'pod2text lib/MooseX/Templated.pm > README' );
}
