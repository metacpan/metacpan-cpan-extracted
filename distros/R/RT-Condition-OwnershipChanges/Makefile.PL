use inc::Module::Install;


RTx 'RT-Condition-OwnershipChanges';
all_from 'lib/RT/Condition/OwnershipChanges.pm';
readme_from 'lib/RT/Condition/OwnershipChanges.pm';
license  'gplv2';

sign;
manifest_skip;
auto_manifest;
WriteAll;
