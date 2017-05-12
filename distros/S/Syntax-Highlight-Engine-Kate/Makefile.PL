use 5.006;
use inc::Module::Install 0.91;

name           'Syntax-Highlight-Engine-Kate';
license        'perl';
author         'Hans Jeuken';
all_from       'lib/Syntax/Highlight/Engine/Kate.pm';

requires       'perl'                     => '5.006';
requires       'Carp'                     => '0';
requires       'Path::Tiny'               => '0';
requires       'Data::Dumper'             => '0';
requires       'File::Basename'           => '0';

test_requires  'Test::More'               => '1.00';
test_requires  'Test::Warn'               => '0.30';
test_requires  'Test::Differences'        => '0.61';
test_requires  'Term::ANSIColor'          => '0';

no_index       'directory'                => qw{ t xt eg share inc privinc };
homepage       'http://padre.perlide.org/';
#bugtracker     'http://padre.perlide.org/';
repository     'https://github.com/szabgab/Syntax-Highlight-Engine-Kate';

WriteAll;
