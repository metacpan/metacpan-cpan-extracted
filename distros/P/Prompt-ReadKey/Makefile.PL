use inc::Module::Install;
use Module::Install::GithubMeta;
use Module::Install::ManifestSkip;
use Module::Install::AutoManifest;

name     'Prompt-ReadKey';
all_from 'lib/Prompt/ReadKey.pm';
githubmeta;

requires 'Moose' => '0.33';
requires 'Text::Table';
requires 'Term::ReadKey';
requires 'Scalar::Util';
requires 'List::Util';
requires 'Text::Sprintf::Named';
requires 'Set::Object';

test_requires 'Test::use::ok';
test_requires 'Test::Fatal';

manifest_skip;
auto_manifest;
WriteAll;
