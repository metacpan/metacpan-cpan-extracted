requires 'Class::Accessor::Lite';
requires 'Module::Load';
requires 'parent';
requires 'perl', '5.010001';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::mysqld';
};
