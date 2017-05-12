use inc::Module::Install;

RTx('RT-Extension-PreviewInSearch');

requires_rt '4.0.0';

repository('https://github.com/bestpractical/rt-extension-previewinsearch.git');

sign;
WriteAll();
