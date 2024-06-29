requires 'perl', '5.008001';
#requires 'Moose';
requires 'JSON::XS';
requires 'Mojolicious';
requires 'Data::Format::Pretty::JSON';
requires 'Net::SSLeay';
requires 'IO::Socket::SSL';
#requires 'Hash::AsObject';
#requires 'EV';
requires 'Moo';
requires 'Type::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Pod::Coverage';
};

recommends 'Type::Tiny::XS'; # improve performance Type::Tiny even more
recommends 'Class::XSAccessor'; # improve performance Moo accessors
