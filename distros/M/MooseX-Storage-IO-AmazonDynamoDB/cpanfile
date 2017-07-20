requires 'perl', '5.014';

requires 'Data::Dumper';
requires 'JSON::MaybeXS';
requires 'Moose';
requires 'MooseX::Role::Parameterized';
requires 'MooseX::Storage';
requires 'Paws';
requires 'PawsX::DynamoDB::DocumentClient';
requires 'Type::Tiny';
requires 'namespace::autoclean';

on test => sub {
    requires 'Test::DescribeMe';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Milla';
    requires 'Test::Deep';
    requires 'UUID::Tiny';
    requires 'Test::Warnings';
};
