use inc::Module::Install;
RTx('RT-Extension-AttachmentWarning');
all_from('lib/RT/Extension/AttachmentWarning.pm');
readme_from('lib/RT/Extension/AttachmentWarning.pm');
sign;
&WriteAll;
