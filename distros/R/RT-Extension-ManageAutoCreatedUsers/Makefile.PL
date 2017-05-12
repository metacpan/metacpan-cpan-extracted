use inc::Module::Install;

RTx 'RT-Extension-ManageAutoCreatedUsers';
license  'gplv2';

githubmeta('github');

requires_rt '4.2.0';
requires_rt_plugin 'RT::Extension::MergeUsers';
requires 'Module::Runtime';
requires 'Class::Method::Modifiers';

test_requires 'Test::More';

no_index 'package' => 'RT::User';

sign;
auto_install;
WriteAll;
