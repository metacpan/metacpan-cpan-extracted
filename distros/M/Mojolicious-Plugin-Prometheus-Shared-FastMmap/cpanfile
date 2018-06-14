requires 'Mojolicious::Plugin::Prometheus', '1.1.0';
requires 'Mojolicious::Plugin::CHI';
requires 'CHI::Driver::FastMmap';
requires 'Cache::FastMmap';
requires 'Role::Tiny';
requires 'Class::Method::Modifiers';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Software::License::Artistic_2_0';
};
