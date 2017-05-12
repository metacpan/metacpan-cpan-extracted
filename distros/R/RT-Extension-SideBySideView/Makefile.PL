use inc::Module::Install;

RTx 'RT-Extension-SideBySideView';
repository 'https://github.com/tbrumm/RT-Extension-SideBySideView';

# this is only because M::I author_from doesn't support multiple authors
author 'Christian Loos <cloos@netsandbox.de>';

requires_rt '4.0.0';
rt_too_new '4.6.0';

sign;
WriteAll;
