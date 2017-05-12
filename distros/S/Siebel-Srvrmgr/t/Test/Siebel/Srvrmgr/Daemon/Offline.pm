package Test::Siebel::Srvrmgr::Daemon::Offline;

use Test::Most 0.35;
use Test::Moose 2.1806;
use Cwd;
use Test::TempDir::Tiny;
use File::Copy;
use base 'Test::Siebel::Srvrmgr::Daemon';

sub _constructor : Test(2) {
    my $test = shift;
    $test->_set_log();
    my $tmp_dir = tempdir();
    copy(
        File::Spec->catfile(
            getcwd(), 't', 'output', 'delimited', '8.0.0.2_20412.txt'
        ),
        $tmp_dir
    ) or die "cannot copy output file: $!";

    ok(
        $test->{daemon} = $test->class()->new(
            {
                output_file =>
                  File::Spec->catfile( $tmp_dir, '8.0.0.2_20412.txt' ),
                field_delimiter => '|',
                time_zone       => 'America/Sao_Paulo',
                commands        => [
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'load preferences',
                        action  => 'LoadPreferences'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp types',
                        action  => 'Dummy'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list params',
                        action  => 'Dummy'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list params for component SRProc',
                        action  => 'Dummy'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def',
                        action  => 'Dummy'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list comp def SRProc',
                        action  => 'Dummy'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list tasks',
                        action  => 'Dummy'
                    ),
                    Siebel::Srvrmgr::Daemon::Command->new(
                        command => 'list tasks for component SRProc',
                        action  => 'Dummy'
                    ),
                ]
            }
        ),
        'constructor works'
    );
    isa_ok( $test->{daemon}, $test->class() );

}

sub class_methods : Test(+2) {
    my $test = shift;
    $test->SUPER::class_methods();
    can_ok( $test->{daemon}, (qw(get_output_file _set_output_file)) );
    does_ok( $test->{daemon}, 'Siebel::Srvrmgr::Daemon::Cleanup' );
}

sub class_methods2 : Test(+6) {
  SKIP: {
        skip 'This class does not implement such test', 6 if (1);
    }

}

sub runs : Test(+1) {
    my $test = shift;
    ok( $test->{daemon}->run(), 'run method executes successfuly' );
}

sub class_attributes : Test(+2) {
    my $test    = shift;
    my @attribs = (qw(output_file field_delimiter));
    $test->SUPER::class_attributes( \@attribs );
}

sub last_run : Test(+1) {

  SKIP: {
        skip 'This class does not implement such test', 1 if (1);
    }

}

1;
