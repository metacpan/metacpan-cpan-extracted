use Module::Build 0.2607;

my $build = Module::Build->new(
        module_name => 'Net::SMTP::Retryable',
        license => 'perl',
        create_makefile_pl => 'traditional',
        requires => {
            'Net::SMTP' => 0,
            'Time::HiRes' => 0,
            'Class::Delegation' => 0,
        });

$build->config_data('smtp-server' => $build->prompt("Enter a valid SMTP server for testing", ""));
$build->config_data('to-address' => $build->prompt("Enter a valid email address for testing", ""));
$build->create_build_script();
