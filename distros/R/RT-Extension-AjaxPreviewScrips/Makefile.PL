use inc::Module::Install;

RTx 'RT-Extension-AjaxPreviewScrips';

repository 'https://github.com/bestpractical/rt-extension-ajaxpreviewscrips';

requires_rt '4.2.0';
rt_too_new '4.4.0';

no_index( package => qw/HTML::Mason::Commands RT::Record RT::Ticket RT::Transaction/ );

sign;
WriteAll;
