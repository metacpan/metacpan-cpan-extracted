use Module::Build;

Module::Build->new(
    module_name => 'SQL::Interpolate',
    license => 'perl',
    recommends => {
        Text::Balanced => '>= 1.87',
        Filter::Simple => 0
    },
    dist_author => 'David Manura (http://math2.org/david/contact)'
)->create_build_script();
