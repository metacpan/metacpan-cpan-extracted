use inc::Module::Install;


RTx 'RTx-Search-FullTextByDefault';
all_from 'lib/RTx/Search/FullTextByDefault.pm';
readme_from 'lib/RTx/Search/FullTextByDefault.pm';
license  'gplv2';

requires_rt('4.2.0');

no_index package => 'RT::Search::Simple';

sign;
WriteAll;
