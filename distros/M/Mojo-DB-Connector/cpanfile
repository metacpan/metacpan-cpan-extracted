requires 'perl', '5.010001';

requires 'Mojolicious', '7.55';
requires 'Class::Method::Modifiers';
requires 'List::Util', '1.42';
requires 'Role::Tiny', '2.000001';

recommends 'Mojo::DB::Role::ResultsRoles';
recommends 'Mojo::mysql';
recommends 'Mojo::Pg';

on develop => sub {
    requires 'Test::Pod';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
};
