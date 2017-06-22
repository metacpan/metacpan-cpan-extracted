requires 'perl', '5.008005';

requires 'Carp';
requires 'Plack';
requires 'Plack::Session::Store', '0.30';
requires 'Time::Seconds';
requires 'lib::abs';
requires 'parent';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Fatal';
    requires 'Redis::Fast', '0.20';
    requires 'JSON', '2.0';
};

on development => sub {
    requires 'Redis';
    requires 'JSON::XS', '3.03';
    requires 'Mojo::JSON';
};
