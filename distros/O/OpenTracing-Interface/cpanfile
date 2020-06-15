requires        'Carp';
requires        'Package::Constants';
requires        'Role::Inspector', '>= 0.006';
requires        'Role::Declare', '>= 0.04';
requires        'Type::Tiny', '>= 1.006';
requires        'Type::Library';
requires        'Type::Utils';
requires        'Types::Common::Numeric';
requires        'Types::Standard';
requires        'namespace::clean';


on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};


on 'test' => sub {
    requires    "Test::Most";
    requires    "Test::OpenTracing::Interface", '>= v0.21';
};
