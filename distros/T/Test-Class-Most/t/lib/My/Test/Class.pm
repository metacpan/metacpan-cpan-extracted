package My::Test::Class;

use Test::Class::Most is_abstract => 1;

INIT { Test::Class->runtests }

sub parent { ['Test::Class'] }

sub startup  : Tests(startup)  {}
sub setup    : Tests(setup)    {}
sub teardown : Tests(teardown) {}
sub shutdown : Tests(shutdown) {}

sub sanity : Tests(2) {
    my $test = shift;

    {
        no strict 'refs';
        my $class = ref $test;
        eq_or_diff \@{"${class}::ISA"}, $test->parent,
          'Inheritance should be handled correctly';
    }
    eval '$foo = 1';
    my $error = $@;
    like $error, qr/^Global symbol "\$foo" requires explicit package name/,
      '... and we should automatically have strict turned on';
}

sub is_abstract {
    my $test = shift;
    return Test::Class::Most->is_abstract($test);
}

sub verify_abstract_behavior : Tests(1) {
    my $test        = shift;
    my $test_class  = ref $test;
    my $is_abstract = Test::Class::Most->is_abstract($test_class);
    my $maybe = $is_abstract ? "" : "not";
    is $test->is_abstract, $is_abstract, "$test_class should $maybe be abstract";
}

1;
