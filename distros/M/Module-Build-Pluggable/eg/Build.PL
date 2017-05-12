use strict;
use lib '../lib/';
use Module::Build;
use Module::Build::Pluggable (
    'PPPort', # => 'lib/ppport.h'
    'ReadmeMarkdownFromPod',
    'Repository',
);

my $mbp = Module::Build::Pluggable->new(
    dist_name => 'Eg',
    dist_version => 0.01,
    dist_abstract => 'test',
    dynamic_config => 0,
    module_name => 'Eg',
    requires => {},
);
$mbp->create_build_script()

