requires 'Class::Method::Modifiers';
requires 'Guard';
requires 'JSON';
requires 'MojoX::JSON::RPC';
requires 'Mojolicious';
requires 'Time::Out';
requires 'perl', '5.014';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'Test::Mojo';
    requires 'Test::Simple', '0.44';
    requires 'Test::MockModule';
    requires 'Test::MockObject';
    requires 'Test::More';
};
