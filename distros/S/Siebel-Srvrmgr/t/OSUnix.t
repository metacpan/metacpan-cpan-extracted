use warnings;
use strict;
use Test::More;
use Test::Moose qw(has_attribute_ok);
use Test::TempDir::Tiny 0.016;
use File::Spec;
use Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias;
use lib 't';
use Test::Siebel::Srvrmgr::Fixtures qw(create_ent_log);

eval "use Siebel::Srvrmgr::OS::Unix";
plan skip_all =>
  "Siebel::Srvrmgr::OS::Unix is required for running these tests: $@"
  if $@;

use constant TMP_DIR => tempdir();
use constant ENTERPRISE_LOG =>
  File::Spec->catfile( TMP_DIR, 'foobar.foobar666.log' );

# :WORKAROUND:22-03-2015 19:58:18:: setting to this hardcode because the hack to define $0 for a running process
# set both fname and cmndline attributes of Proc::ProcessTable::Process
use constant PROC_NAME   => 'siebmtshmw';
use constant TOTAL_TESTS => 16;
plan tests               => TOTAL_TESTS;

if ( $] >= 5.012_005 ) {

  SKIP: {

        eval
q{use Proc::Daemon;  die "This test is not supported at this version of perl ($])" unless $] > 5.012_005};

        skip "Cannot run this test because of \"$@\"", TOTAL_TESTS, if $@;

        my $daemon = Proc::Daemon->new();

        my $kid = $daemon->init();

        unless ($kid) {

            local $0 = PROC_NAME;

            #let's put child to do something
            while (1) {

                my $a = 0;
                my $b = 1;
                my $n = 2000;

                for ( 0 .. ( $n - 1 ) ) {
                    my $sum = $a + $b;
                    $a = $b;
                    $b = $sum;
                }

                sleep 1;

            }

        }
        else {

            my $procs = fixtures($kid);
            test_attributes($procs);
            test_methods($procs);
            test_operations($procs);
            $daemon->Kill_Daemon($kid);

        }

    }

}
else {

  SKIP: {

# :REMARK:23-03-2015 02:23:56:: perl 5.8.9 does not allow the change of fname in /proc by changing $0
        eval q{use Proc::Background};

        skip "Cannot run this test because of \"$@\"", TOTAL_TESTS, if $@;

        my $proc_path = File::Spec->catfile( TMP_DIR, PROC_NAME );

        open( my $script, '>', $proc_path )
          or die "Cannot create $$proc_path: $!";

        my $code = q(#!/usr/bin/perl
#let's put child to do something
while (1) {

    my $a = 0;
    my $b = 1;
    my $n = 2000;

    for ( 0 .. ( $n - 1 ) ) {
        my $sum = $a + $b;
        $a = $b;
        $b = $sum;
    }

    sleep 1;

});

        print $script $code;
        close($script);
        chmod 0700, $proc_path;
        my $siebel_proc = Proc::Background->new($proc_path);
        my $procs       = fixtures( $siebel_proc->pid );
        test_attributes($procs);
        test_methods($procs);
        test_operations($procs);
        $siebel_proc->die;

    }

}

###################################################
# SUBS
#

sub fixtures {

    my $pid = shift;

    note("Running tests against perl $], child PID is $pid");

    # giving some time to get data into /proc
    sleep 3;

    create_ent_log( $pid, ENTERPRISE_LOG );
    return Siebel::Srvrmgr::OS::Unix->new(
        {
            cmd_regex => ( PROC_NAME . '$' ),
            comps_source =>
              Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias->new(
                {
#ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9644	) for SRProc
                    process_regex =>
                      'Created(\smultithreaded)?\sserver\sprocess',
                    log_path => ENTERPRISE_LOG,
                }
              )
        }
    );

}

END {

    unlink ENTERPRISE_LOG
      or note( 'Failed to remove ' . ENTERPRISE_LOG . ": $!" );
    rmdir TMP_DIR or note( 'Failed to remove ' . TMP_DIR . ": $!" );

}

sub test_operations {

    my $procs     = shift;
    my $procs_ref = $procs->get_procs();

    is( ref($procs_ref), 'HASH', 'get_procs returns a hash reference' );

# :WORKAROUND:21-06-2015 12:53:45:: avoid getting other undesired process beside the one we are forcing as "Siebel process"
# :WORKAROUND:03-12-2015 13:31:44:: avoid problems with concurrent tests on the same OS
    foreach my $pid ( keys( %{$procs_ref} ) ) {

        if (   ( $procs_ref->{$pid}->{comp_alias} eq 'N/A' )
            or ( $procs_ref->{$pid}->{comp_alias} eq 'unknown' ) )
        {

            delete $procs_ref->{$pid};

        }

    }

    is( scalar( keys( %{$procs_ref} ) ),
        1, 'get_procs returns a single process' )
      or diag( explain($procs_ref) );
    my $pid = ( keys( %{$procs_ref} ) )[0];
    isa_ok(
        $procs_ref->{$pid},
        'Siebel::Srvrmgr::OS::Process',
        "reference of $pid key"
    );
    is( $procs_ref->{$pid}->get_comp_alias,
        'EAIObjMgr_enu', 'process has the correct component alias associated' );
    is( $procs_ref->{$pid}->get_fname,
        'siebmtshmw', 'process has the correct process name' );
    ok( $procs_ref->{$pid}->is_comp, 'is_comp returns true' );

    my $float   = qr/\d+(\.\d+)?/;
    my $integer = qr/\d+/;

    like( $procs_ref->{$pid}->get_pctcpu, $float, 'process %CPU is a float' );
    like( $procs_ref->{$pid}->get_pctmem, $float,
        'process %memory is a float' );
    like( $procs_ref->{$pid}->get_rss, $integer, 'process RSS is a integer' );
    like( $procs_ref->{$pid}->get_vsz, $integer, 'process VSZ is a integer' );

}

sub test_methods {

    my $procs   = shift;
    my @methods = (
        'get_cmd',       'set_cmd',
        'get_mem_limit', 'set_mem_limit',
        'find_comps',    'get_procs',
        'get_cpu_limit', 'set_cpu_limit',
        'get_comps_source'
    );
    can_ok( $procs, @methods );

}

sub test_attributes {

    my $procs = shift;
    my @attribs =
      (qw(comps_source cmd_regex mem_limit cpu_limit limits_callback));

    foreach my $attrib (@attribs) {

        has_attribute_ok( $procs, $attrib );

    }

}

