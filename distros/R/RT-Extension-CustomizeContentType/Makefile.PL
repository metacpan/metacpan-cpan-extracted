use inc::Module::Install;

RTx('RT-Extension-CustomizeContentType');

repository('https://github.com/bestpractical/rt-extension-customizecontenttype');

no_index package => 'RT::Attachment';

sign();
WriteAll();
