use inc::Module::Install;

name 'Parallel-Scoreboard';
all_from 'lib/Parallel/Scoreboard.pm';

license 'perl';
readme_from 'lib/Parallel/Scoreboard.pm';

requires 'Class::Accessor::Lite' => 0.05;
requires 'HTML::Entities';
requires 'JSON';

test_requires 'File::Temp';
test_requires 'Test::More';
test_requires 'Test::Warn';
auto_include;

repository 'https://github.com/kazuho/p5-Parallel-Scoreboard';

WriteAll;
