use 5.008001;
use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::ReadmeMarkdownFromPod;
use Module::Install::GithubMeta;
use Module::Install::Repository;

name 'String-Diff';
all_from 'lib/String/Diff.pm';
readme_from 'lib/String/Diff.pm';
readme_markdown_from 'lib/String/Diff.pm';
githubmeta;

requires 'Algorithm::Diff';

build_requires 'Test::Base';
build_requires 'Test::More';
build_requires 'YAML';

auto_set_repository;
WriteAll;
