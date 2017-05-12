use inc::Module::Install;

RTx 'RT-Extension-QuoteSelection';

repository 'https://github.com/bestpractical/rt-extension-quoteselection';

requires_rt '4.0.0';
rt_too_new '4.6.0';

sign;
WriteAll;
