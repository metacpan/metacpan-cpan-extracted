use inc::Module::Install;
requires( perl => '5.8.1');
name('Module-Refresh');
author('Jesse Vincent <jesse@bestpractical.com>');
license('perl');
version_from('lib/Module/Refresh.pm');
abstract_from('lib/Module/Refresh.pm');
build_requires ('Test::More' => 0,
                'Path::Class' => 0,
                'File::Temp' => "0.19",
                );
sign;
&WriteAll;
