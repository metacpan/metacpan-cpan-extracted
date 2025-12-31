use inc::Module::Install;

RTx('RT-Extension-PreviewInSearch', { remove_files => 1 });

requires_rt '6.0.0';

repository('https://github.com/bestpractical/rt-extension-previewinsearch.git');

sign;
WriteAll();
