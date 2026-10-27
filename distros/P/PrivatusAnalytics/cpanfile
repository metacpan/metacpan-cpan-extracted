# Used by run-docker.sh and CI to install everything the tests need.
requires 'perl', '5.020';
requires 'JSON::PP', '2.27';
requires 'Scalar::Util';

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Mojolicious', '9.0';
    requires 'Dancer2', '0.400000';
    requires 'Plack', '1.0047';
    requires 'HTTP::Request::Common';
};

on develop => sub {
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
};
