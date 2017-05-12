use inc::Module::Install;
name 'RTx-Timeline';
license 'perl';
author 'Todd Chapman <todd@chaka.net>';
requires 'JSON::Syck' => 0;
RTx('RT-Extension-Timeline');
&WriteAll;
