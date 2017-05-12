requires 'Exporter::Lite';
requires 'Module::Build::Tiny', '0.039';
requires 'Path::Class', '0.29';
requires 'Scalar::Util';
requires 'Test::More';
requires 'Test::Base';
requires 'URI';

on build => sub {
    requires 'Module::Build::Tiny';
};
on test => sub {
    requires 'Test::Base';
    requires 'Test::More';
};
