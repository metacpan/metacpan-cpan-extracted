use inc::Module::Install;

name           'Pod-Minicpandoc';
all_from       'lib/Pod/Minicpandoc.pm';
readme_from    'lib/Pod/Minicpandoc.pm';
githubmeta;

requires       'HTTP::Tiny';
requires       'Archive::Tar';
requires       'Archive::Zip';
requires       'File::Spec';
requires       'IO::Uncompress::Gunzip';
requires       'JSON::PP';

install_script 'bin/mcpandoc';

manifest_skip;
auto_manifest;
WriteAll;

