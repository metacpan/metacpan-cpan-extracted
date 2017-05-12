use inc::Module::Install;
name 'Example';
all_from 'lib/Example.pm';

html5_manifest
    htdocs_from   => 'htdocs',
    manifest_skip => 'html5manifest.skip',
    generate_to   => 'example.manifest',
    with_gzfile   => 1,
    network_list  => [qw( /api /foo/bar.cgi )],
    use_digest    => 1,
    ;

WriteAll;
