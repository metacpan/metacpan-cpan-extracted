## no critic
use Test::More;
use Test::Moose::More;

my %classes = (
    'Podman::System'     => [ 'DiskUsage', 'Version', 'Client' ],
    'Podman::Images'     => [ 'List',      'Client' ],
    'Podman::Containers' => [ 'List',      'Client' ],
    'Podman::Image'      =>
      [ 'Build', 'Inspect', 'Pull', 'Remove', 'Client', 'Name' ],
    'Podman::Container' => [
        'Create', 'Delete', 'Inspect', 'Kill',
        'Start',  'Stop',   'Client',  'Name',
    ],
);

for my $class ( sort keys %classes ) {
    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    for my $method ( @{ $classes{$class} } ) {
        has_method_ok( $class, $method );
    }
}

done_testing();
