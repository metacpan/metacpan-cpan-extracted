use inc::Module::Install;

RTx('RT-Extension-JSGantt');

repository 'https://github.com/bestpractical/rt-extension-jsgantt';

requires( 'JSON' );
requires( 'List::MoreUtils' );

sign;
WriteAll;
