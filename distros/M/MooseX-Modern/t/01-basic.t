use Test::Modern;
use MooseX::Modern;
use Module::Loaded;

for (qw/
    Moose
    Moose::Util::TypeConstraints
    MooseX::AttributeShortcuts
    MooseX::HasDefaults::RO
    namespace::autoclean
/) {
    ok is_loaded($_), "Module $_ was loaded successfully";
}

done_testing;
