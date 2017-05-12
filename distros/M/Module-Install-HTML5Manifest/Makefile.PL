use inc::Module::Install;
name 'Module-Install-HTML5Manifest';
all_from 'lib/Module/Install/HTML5Manifest.pm';
readme_from 'lib/Module/Install/HTML5Manifest.pm';
readme_markdown_from 'lib/Module/Install/HTML5Manifest.pm';
githubmeta;

requires 'Data::Dumper';
requires 'HTML5::Manifest';
requires 'MIME::Base64';
requires 'Module::Install';

tests 't/*.t';
author_tests 'xt';

build_requires 'Capture::Tiny';
build_requires 'File::Spec';
build_requires 'IO::Compress::Gzip'; # for t/02_gz.t
build_requires 'IO::Uncompress::Gunzip'; # for t/02_gz.t
build_requires 'Digest::MD5';
build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
