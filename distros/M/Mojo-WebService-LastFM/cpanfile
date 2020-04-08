# To use: cpanm --installdeps .
requires 'perl' => '5.010001';
requires 'Mojolicious' => '8.0';
requires 'Mojo::UserAgent';
requires 'Mojo::Promise';
requires 'Moo' => '2.000000';
requires 'Carp';
requires 'strictures' => '2';
requires 'namespace::clean';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Fatal';
    requires 'Test::Memory::Cycle';
    requires 'Data::Dumper';
    requires 'Mojolicious::Lite';
};
