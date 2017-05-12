requires 'perl', '5.008001';
requires 'LWP::UserAgent', '6.13';
requires 'JSON::XS', '3.01';
requires 'AnyEvent', '7.11',
requires 'IO::All', '0.86',

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::CheckManifest';
};

on 'develop' => sub {
    requires 'Module::Build::Tiny';
    requires 'Minilla';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod';
    requires 'Test::Spellunker';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
