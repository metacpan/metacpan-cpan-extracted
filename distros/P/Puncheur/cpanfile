requires 'Clone';
requires 'Config::PL';
requires 'Data::Section::Simple';
requires 'Hash::MultiValue';
requires 'JSON';
requires 'Plack';
requires 'Plack::Middleware::Session';
requires 'Plack::Request::WithEncoding';
requires 'Router::Boom', '1.00';
requires 'Text::Xslate';
requires 'Tiffany';
requires 'URI::QueryParam';
requires 'URL::Encode';
requires 'perl', '5.010';

recommends 'URL::Encode::XS';

# Plugin::ShareDir
recommends 'File::ShareDir';

# Plugin::HandleStatic
recommends 'MIME::Base64';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
};
