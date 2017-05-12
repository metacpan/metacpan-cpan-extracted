requires "perl" => "5.10.0";
requires "Module::Starter::Simple";
requires "Carp";
requires "File::Spec";
requires "ExtUtils::Command";
requires "Test::Pod" => "1.22";
requires "Test::CheckManifest" => "0.9";

on 'test' => sub {
    requires 'Test::More' => "0";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
