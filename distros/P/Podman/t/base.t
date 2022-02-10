## no critic
use Test::More;

my %classes = (
    'Podman::System' => [ 'disk_usage', 'info', 'prune', 'version', ],
    'Podman::Images'     => [ 'list', 'prune', ],
    'Podman::Containers' => [ 'list', 'prune', ],
    'Podman::Image'      =>
      [ 'build', 'inspect', 'pull', 'remove', 'name', ],
    'Podman::Container' => [
        'create', 'delete', 'inspect', 'kill',   'pause', 'restart',
        'start',  'stop',   'unpause', 'name',
    ],
);

for my $module ( sort keys %classes ) {
    require_ok($module);
    can_ok( $module, $_ ) for ( @{ $classes{$module} } );
}

done_testing();
