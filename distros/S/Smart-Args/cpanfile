requires 'perl', '5.008001';

requires 'Exporter', '5.63';
requires 'Mouse', '0.92';
requires 'PadWalker', '1.92';
requires 'Scalar::Util', '1.21';
requires 'Mouse::Util::TypeConstraints';

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Requires';
    requires 'Test::Builder::Module';

    requires 'Moose::Util::TypeConstraints';
    requires 'MooseX::Types::Moose';
    requires 'MouseX::Types';
    requires 'MouseX::Types::Mouse';
};

on develop => sub {
    requires 'Params::Validate';
    requires 'Test::Perl::Critic';
};
