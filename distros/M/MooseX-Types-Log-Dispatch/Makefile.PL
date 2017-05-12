
use strict;
use warnings;
use inc::Module::Install;

# Define metadata
name 'MooseX-Types-Log-Dispatch';
abstract 'Moose type-constraints and coercions for Log::Dispatch.';
all_from 'lib/MooseX/Types/Log/Dispatch.pm';

# Specific dependencies
requires 'Moose';
requires 'Log::Dispatch';
requires 'MooseX::Types';

test_requires 'Test::More';
test_requires 'Test::Exception';

resources 'IRC' => 'irc://irc.perl.org/#moose';
resources 'license' => 'http://dev.perl.org/licenses/';
resources 'repository' => 'git://git.moose.perl.org/MooseX-Types-Log-Dispatch.git';

WriteAll;
