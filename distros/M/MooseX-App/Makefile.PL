# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;

my $from = 'lib/MooseX/App.pm';

# Define metadata
name            'MooseX-App';
all_from        $from;
readme_from     $from;

perl_version    '5.010';

# Specific dependencies
requires        'Moose'                         => '2.00';
requires        'namespace::autoclean'          => 0;
requires        'Module::Pluggable'             => 0;
requires        'Path::Class'                   => 0;
requires        'MooseX::Types::Path::Class'    => 0;
requires        'Config::Any'                   => 0;
requires        'List::Util'                    => '1.44';
requires        'Pod::Elemental'                => 0;

recommends      'IO::Interactive'               => 0;
recommends      'Term::ReadKey'                 => 0;
recommends      'Term::ANSIColor'               => 0;
recommends      'File::HomeDir'                 => 0;
recommends      'Text::WagnerFischer'           => 0;

if ($^O eq 'MSWin32') {
    recommends 'Win32::Console::ANSI';
}

build_requires  'Test::Most'                    => 0;
build_requires  'Test::NoWarnings'              => 0;

author_requires 'Test::Pod'                     => '1.14';
author_requires 'Test::Pod::Coverage'           => '1.04';
author_requires 'Test::Perl::Critic'            => 0;
author_requires 'Module::Install::ReadmeFromPod'=> 0;

repository 'git://github.com/maros/MooseX-App.git';
bugtracker 'https://github.com/maros/MooseX-App/issues';

WriteAll;