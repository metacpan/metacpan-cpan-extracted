use inc::Module::Install;

RTx 'RT-Extension-AdminConditionsAndActions';

repository('https://github.com/bestpractical/rt-extension-adminconditionsandactions');

requires_rt '4.0.0';
rt_too_new '4.4.2';

no_index( package => 'RT::ScripCondition', 'RT::ScripAction' );

WriteAll;
