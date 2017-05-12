use Module::Build;
my $build = Module::Build->new
(
    module_name => 'Net::PostcodeNL::WebshopAPI',
    license  => 'perl',
    requires => {
        'perl'          => '5.6.1',
        'JSON::XS'      => '2.33',
        'URI::Template' => '0.16',
        'LWP::UserAgent' => '6.04',
    },
);
$build->create_build_script;
