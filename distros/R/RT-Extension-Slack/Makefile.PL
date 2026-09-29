use lib '.';
use inc::Module::Install;

RTx ('RT-Extension-Slack');
license 'gpl2';

requires_rt ('6.0.0');

author 'Josh Tackitt <tackittj@reed.edu>';
abstract 'Send and sync RT ticket notifications to Slack';

WriteAll();
