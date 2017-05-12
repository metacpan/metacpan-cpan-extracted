use inc::Module::Install;
name 'Example';
all_from 'lib/Example.pm';

html5_manifest
    htdocs_from   => 'htdocs',
    manifest_skip => 'html5manifest.skip',
    generate_to   => 'example.manifest',
    network_list  => [qw( /api /foo/bar.cgi )],
    use_digest    => 1,
    ;

WriteAll;
