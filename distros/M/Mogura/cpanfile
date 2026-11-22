requires 'perl', '5.034000';

# Runtime dependencies are locked, including transitive modules, by Carton.
requires 'Mojolicious', '9.42';
requires 'IO::Socket::SSL', '2.009';
requires 'YAML::PP', '0.039';
requires 'DBI', '1.647';
requires 'DBD::SQLite', '1.78';

# Native JSON decoding for metadata; streaming validation for tool artifacts.
requires 'Cpanel::JSON::XS', '4.20';
requires 'JSON::SL', '1.0.7';

on 'test' => sub {
    requires 'Test::More', '1.302183';

    # Test::Mojo ships with Mojolicious and has no independent version.
    requires 'Test::Mojo';
};

on 'develop' => sub {
    requires 'Perl::Tidy', '20260826';
};
