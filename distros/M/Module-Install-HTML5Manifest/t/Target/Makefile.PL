use inc::Module::Install;
name 'Example';
all_from 'lib/Example.pm';
use File::Spec;

html5_manifest
    make_target   => 'html5manifest_target1',
    htdocs_from   => 'htdocs',
    manifest_skip => 'html5manifest1.skip',
    generate_to   => 'example1.manifest',
    ;

html5_manifest
    make_target   => 'html5manifest_target2',
    htdocs_from   => File::Spec->catfile('htdocs', 'tmp'),
    generate_to   => 'example2.manifest',
    ;

WriteAll;
