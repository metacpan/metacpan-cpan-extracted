
requires "JSON" => "0";
requires "Try::Tiny" => "0";
requires "Time::HiRes" => "0";

on 'test' => sub {
    requires 'Test::More' => "0";
    requires 'Test::MockObject' => "0";
    requires 'Test::Identity' => "0";
    requires "Try::Tiny" => "0";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
