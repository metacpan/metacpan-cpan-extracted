requires 'perl', '5.008005';

requires 'Module::Runtime';
requires 'Net::Amazon::DynamoDB::Marshaler', '0.05';
requires 'Paws';
requires 'PerlX::Maybe';
requires 'Scalar::Util';

on test => sub {
    requires 'Test::Deep';
    requires 'Test::DescribeMe';
    requires 'Test::Fatal';
    requires 'Test::More', '0.96';
};

on develop => sub {
    requires 'Dist::Milla';
    requires 'UUID::Tiny';
};
