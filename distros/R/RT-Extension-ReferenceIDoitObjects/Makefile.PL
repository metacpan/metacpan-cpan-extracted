use inc::Module::Install;

RTx 'RT-Extension-ReferenceIDoitObjects';

all_from 'lib/RT/Extension/ReferenceIDoitObjects.pm';
license 'perl';
readme_from;
repository 'https://github.com/bheisig/rt-extension-referenceidoitobjects';

requires_rt('4.4.0');
auto_install();

sign;
&WriteAll;
