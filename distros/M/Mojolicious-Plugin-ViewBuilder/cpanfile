requires 'Mojolicious';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Mojolicious' => '5.0';
    requires 'Test::Mojo';
    requires 'Test::More', '0.98';
};
