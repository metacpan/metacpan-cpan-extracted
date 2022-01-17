requires 'perl', '>= 5.020';
requires 'parent', 0;
requires 'Exporter', 0;
requires 'Bytes::Random::Secure';
requires 'Log::Any';
requires 'Role::Tiny';
requires 'JSON::MaybeXS';
requires 'JSON::MaybeUTF8', '>= 2.000';
requires 'Module::Pluggable';
requires 'Module::Load';
requires 'Net::Address::IP::Local';
requires 'indirect';
requires 'Syntax::Keyword::Try';
requires 'Class::Method::Modifiers';

recommends 'Math::Random::ISAAC::XS';

on 'test' => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::Deep', '>= 1.124';
    requires 'Test::Fatal', '>= 0.010';
    requires 'Test::Refcount', '>= 0.07';
    requires 'Test::Warnings', '>= 0.024';
    requires 'Test::Files', '>= 0.14';

    recommends 'Log::Any::Adapter::TAP', '>= 0.003002';
};
