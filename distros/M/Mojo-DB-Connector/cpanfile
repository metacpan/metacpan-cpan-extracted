requires 'perl', '5.010001';

requires 'Mojolicious';
requires 'Class::Method::Modifiers';
requires 'List::Util';
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
