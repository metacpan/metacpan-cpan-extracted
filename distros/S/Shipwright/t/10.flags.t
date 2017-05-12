use strict;
use warnings;

use Shipwright;
use Shipwright::Test;
use File::Spec::Functions qw/catfile catdir/;

use Test::More tests => 3;

Shipwright::Test->init;

{
    my $shipwright = Shipwright->new(
        repository => 'fs:' . create_fs_repo,
        log_level  => 'FATAL',
    );

    test_flags( shipwright => $shipwright, name => 'foo' );

}

sub test_flags {
    my %args       = @_;
    my $shipwright = $args{shipwright};
    my $name       = $args{name};

    # init
    $shipwright->backend->initialize();

    my $flags = $shipwright->backend->flags;
    is_deeply( $flags->{$name}, undef, 'initial flags are undef' );

    $flags->{$name} = [ 'foo', 'bar' ];
    $shipwright->backend->flags($flags);

    $flags = $shipwright->backend->flags;
    is_deeply(
        $flags->{$name},
        [ 'foo', 'bar' ],
        "set flags to ['foo', 'bar']"
    );

    $flags->{$name} = [];
    $shipwright->backend->flags($flags);

    $flags = $shipwright->backend->flags;
    is_deeply( $flags->{$name}, [], "set flags to []" );
}
