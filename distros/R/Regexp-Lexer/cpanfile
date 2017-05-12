requires 'perl', '5.010001';
requires 'parent';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on develop => sub {
    requires 'YAML::Tiny';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Deep';
};

