use inc::Module::Install;
RTx('RT-Extension-Log-MemoryUsage');
all_from 'lib/RT/Extension/Log/MemoryUsage.pm';
readme_from 'lib/RT/Extension/Log/MemoryUsage.pm';

WriteAll();
