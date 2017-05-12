requires 'perl', '5.008_001';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More';
    requires 'Tie::IxHash';
};

on develop => sub {
    requires 'Test::Requires';
};
