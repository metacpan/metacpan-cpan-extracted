requires 'perl', '5.010001';
requires 'Sub::Identify', '0.14';
requires 'Sub::Util', '1.50';
requires 'Carp';
requires 'Scalar::Util';
requires 'Type::Tiny', '1.012000';
requires 'Class::Load';

feature 'finder_function_parameters' => sub {
    requires 'Function::Parameters', '2.000003';
};

feature 'finder_sub_wrap_in_type' => sub {
    requires 'Sub::WrapInType', '0.04';
};

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on 'test' => sub {
    requires 'Test2::V0', '0.000135';
    requires 'Test::LeakTrace';
    requires 'Devel::Refcount';
};
