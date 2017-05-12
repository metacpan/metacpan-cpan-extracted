use inc::Module::Install;

RTx 'RT-Extension-AdminConditionsAndActions';

repository('https://github.com/bestpractical/rt-extension-adminconditionsandactions');

no_index( package => 'RT::ScripCondition', 'RT::ScripAction' );

sign;
WriteAll;
