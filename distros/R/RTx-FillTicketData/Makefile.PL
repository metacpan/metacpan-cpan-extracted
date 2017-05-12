use inc::Module::Install;
RTx 'RTx-FillTicketData', { no_readme_generation => 1 };
requires_rt('4.0.0');
all_from('lib/RTx/FillTicketData.pm');
repository 'git://github.com/ichesnokov/RTx-FillTicketData';
no_index 'etc';
WriteAll();
