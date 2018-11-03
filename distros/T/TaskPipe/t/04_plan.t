#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Test::More;
use Cwd 'abs_path';
use File::Basename;
use TaskPipe::TaskUtils;
use Data::Dumper;
use lib 't/lib';
use TaskPipe::TestUtils::Basic;

my $root_dir = File::Spec->catdir(
    dirname(abs_path(__FILE__)),'..','t','non_threaded'
);
my $basic = TaskPipe::TestUtils::Basic->new(
    root_dir => $root_dir
);

$basic->clear_tables;
my $sm = $basic->cmdh->handler->schema_manager;
my $gm = $basic->cmdh->handler->job_manager->gm;
my $utils = TaskPipe::TaskUtils->new(
    sm => $sm,
    gm => $gm
);



my $all_expected = {
    'branch.yml' => {
        plan_mode => 'branch',
        ops => 14,
        results => {
            city => { 
                labels => [ 'A', 'B' ],
                company => {
                    labels => [ 'A', 'B' ],
                    employee => {
                        labels => [ 'A', 'B' ]
                    }
                }
            }
        }
    },


    'tree.yml' => {
        plan_mode => 'tree',
        ops => 14,
        results => {
            city => { 
                labels => [ 'A', 'B' ],
                company => {
                    labels => [ 'A', 'B' ],
                    employee => {
                        labels => [ 'A', 'B' ]
                    }
                }
            }
        }
    },


    'tree_branched.yml' => {
        plan_mode => 'tree',
        ops => 42,
        results => {
            city => {
                labels => [ 'A', 'B' ],
                company => {
                    labels => [ 'A', 'B', 'Y', 'Z' ],
                    employee => {
                        labels => [ 'A', 'B', 'Y', 'Z' ]
                    }
                }
            }
        }
    }
};



plan tests => 3 + 2 * ( 2 + 4 + 8 ) + ( 2 + 8 + 32 );

warn "Running plan tests. Please be patient - this will take some time\n";

foreach my $plan_fn ( sort (keys %$all_expected) ){

    my $expected = $all_expected->{$plan_fn};

    $basic->run_plan({ plan => $plan_fn, plan_opts => [ '--plan_mode', $expected->{plan_mode} ] });

    my $ops = $sm->table('operations', 'plan')->search({})->count;
    is( $ops, $expected->{ops}, "$plan_fn no. of operations" );

    my $xresults = $expected->{results};

    #print "xresults: ".Dumper( $xresults );
    foreach my $table (keys %$xresults){
        test_table_rows( $plan_fn, $table, $xresults->{$table} );
    }
    $basic->clear_tables;
}


done_testing();



sub test_table_rows{
    my ($plan_fn, $table, $xresults, $last_table,$id) = @_;

    #print "executing test_table_rows with table $table xresults ".Dumper( $xresults )."\n";

    my $labels = $xresults->{labels};

    foreach my $label ( @$labels ){
        my $search = { label => $label };
        if ( $last_table ){
            $search->{ $last_table.'_id' } = $id;
        }

        my $rs = $sm->table($table,'plan')->search( $search );

        is( $rs->count, 1, "$plan_fn: record [".$utils->serialize($search)."] exists on $table table");
        foreach my $kid_table ( keys %$xresults ){
            next if $kid_table eq 'labels';
            test_table_rows( $plan_fn, $kid_table, $xresults->{$kid_table}, $table, $rs->next->id );
        }
    }
}




 


                



