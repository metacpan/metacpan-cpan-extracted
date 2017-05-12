use inc::Module::Install;

name           'Pod-Cpandoc';
all_from       'lib/Pod/Cpandoc.pm';
readme_from    'lib/Pod/Cpandoc.pm';
githubmeta;

requires       'HTTP::Tiny';
requires       'IO::Socket::SSL', '1.56';
requires       'Net::SSLeay',     '1.49';
requires       'JSON::PP';

install_script 'bin/cpandoc';

manifest_skip;
auto_manifest;
WriteAll;

