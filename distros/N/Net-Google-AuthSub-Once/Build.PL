use Module::Build;
Module::Build->new(
    module_name => 'Net::Google::AuthSub::Once',
    license     => 'perl',
    requires => {
        'URI' => 0,
        'URI::QueryParam' => 0,
        'Crypt::Random' => 0,
        'Crypt::OpenSSL::RSA' => 0,
        'File::Slurp' => 0,
        'MIME::Base64' => 0,

    },
)->create_build_script;

