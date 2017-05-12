use strict;
use warnings;

use Shipwright;
use Shipwright::Test;
use File::Spec::Functions qw/catfile/;
use File::Temp qw/tempdir/;

use Test::More tests => 28;

Shipwright::Test->init;

{

    # fs backend test
    my $repo       = 'fs:' . create_fs_repo();
    my $shipwright = Shipwright->new(
        log_level  => 'fatal',
        repository => $repo,
    );
    $shipwright->backend->initialize;

    my %map = (
        create => {
            $repo => 1,

          # yeah, fs can create anywhere, but this may fail if permission denied
            'fs:/noexists/bla' => 1,
        },
        list => {
            'fs:/noexists/bla' => undef,
            $repo              => 1,
        },
    );
    test_repo( 'FS', %map );
}

SKIP: {
    skip "svk: no svk found or env SHIPWRIGHT_TEST_SVK not set", 10 
      if skip_svk();

    create_svk_repo();

    my $shipwright =
      Shipwright->new( log_level => 'fatal', repository => '//bar' );
    $shipwright->backend->initialize;

    my %map = (
        create => {
            '//__shipwright/foo' => 1,
            'svk:/noexists/'     => undef,
        },
        list => {
            '//__shipwright/foo' => undef,
            'svk:/noexists/'     => undef,
            '//bar'              => 1,
        },
    );

    test_repo( 'SVK', %map );
}

SKIP: {
    skip "svn: no svn found or env SHIPWRIGHT_TEST_SVN not set", 10 
      if skip_svn();

    my $valid   = create_svn_repo();
    my $invalid = 'svn:file:///aa/bb/cc';

    my $shipwright = Shipwright->new(
        log_level  => 'fatal',
        repository => "svn:$valid/bar"
    );
    $shipwright->backend->initialize;

    my %map = (
        create => {
            "svn:$valid" => 1,
            $invalid     => undef,
        },
        list => {
            "svn:$valid"     => undef,
            $invalid         => undef,
            "svn:$valid/bar" => 1,
        },
    );

    test_repo( 'SVN', %map );
}

sub test_repo {
    my $bk_class = shift;
    my %map      = @_;
    for my $action ( keys %map ) {
        for my $repo ( keys %{ $map{$action} } ) {
            my $backend = Shipwright::Backend->new( repository => $repo );
            isa_ok( $backend, 'Shipwright::Backend::' . $bk_class );
            is(
                $backend->check_repository( action => $action, force => 1 ),
                $map{$action}{$repo},
                "$repo for action $action",
            );
        }
    }
}
