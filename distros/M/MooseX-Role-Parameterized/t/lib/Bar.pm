package Bar;

use MooseX::Role::Parameterized;

parameter include_is_bar => (
    isa     => 'Bool',
    default => 1,
);

role {
    my $p = shift;
    if ($p->include_is_bar) {
        method is_bar => sub { 1 };
    }
};

1;
