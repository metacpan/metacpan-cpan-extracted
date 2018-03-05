BEGIN { push @INC, '.' }
use inc::Module::Install;

name	        'Module-Install-RTx';
author          'Best Practical Solutions';
all_from        'lib/Module/Install/RTx.pm';
requires        'Module::Install::Admin' => 0.40;
requires        'Module::Install::ReadmeFromPod';
readme_from     'lib/Module/Install/RTx.pm';

auto_provides;
&WriteAll( check_nmake => 0, sign => 1 );
