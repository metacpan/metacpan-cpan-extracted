package Tapper::CLI::Testrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Testrun::VERSION = '5.0.8';

use 5.010;
use warnings;
use strict;
use feature qw/ say /;
use English qw/ -no_match_vars /;

# list limit default value
my $i_limit_default = 50;


sub b_print_single_testrun {

    my ( $or_testrun ) = @_;

    print  "\n";
    printf "%17s: %s\n", 'Id'   , $or_testrun->id;
    printf "%17s: %s\n", 'Topic', $or_testrun->topic_name;

    if ( $or_testrun->shortname ) {
        printf "%17s: %s\n", 'Shortname', $or_testrun->shortname;
    }
    if ( $or_testrun->testrun_scheduling ) {

        require Tapper::Cmd::Testrun;
        my $or_cmd = Tapper::Cmd::Testrun->new();
        my $hr_testrun_details = $or_cmd->status($or_testrun->id);
        printf "%17s: %s\n", 'State', $hr_testrun_details->{status};
        printf "%17s: %s\n", 'Queue', $or_testrun->testrun_scheduling->queue->name;

        if ( $or_testrun->testrun_scheduling->status eq 'schedule' ) {
            if ( $or_testrun->testrun_scheduling->requested_hosts->count ) {
                printf "%17s: %s\n", q#Requested Host's#, join ",", $or_testrun->testrun_scheduling->requested_hosts->related_resultset('host')->get_column('name')->all;
            }
        }
        else {
            if (
                $or_testrun->testrun_scheduling->host &&
                $or_testrun->testrun_scheduling->host->name
            ) {
                printf "%17s: %s\n", 'Used Host', $or_testrun->testrun_scheduling->host->name;
            }
        }

        printf "%17s: %s\n", 'Auto rerun', $or_testrun->testrun_scheduling->auto_rerun ? 'yes' : 'no';

    }
    else {
        printf "%17s: %s\n", q##, 'Old testrun without scheduling information';
    }

    if ( $or_testrun->notes ) {
        printf "%17s: %s\n", 'Notes', $or_testrun->notes;
    }

    printf "%17s: ",  q#Precondition Id's#;
    if ( my @a_preconditions = $or_testrun->ordered_preconditions ) {
        say join ", ", map {$_->id} @a_preconditions;
    }
    else {
        say 'None';
    }

    return 1;

}


sub b_print_testruns {

    my ( $or_testruns ) = @_;

    if ( $or_testruns->isa('DBIx::Class::ResultSet') ) {
        for my $or_testrun ( $or_testruns->all ) {
            b_print_single_testrun( $or_testrun );
        }
    }
    else {
        b_print_single_testrun( $or_testruns );
    }
    print  "\n";

    return 1;

}


sub ar_get_list_testrun_parameters {
    return [
        [ 'id|i=i@'   , 'list particular testruns', 'Can be given multiple times.',                                                     ],
        [ 'finished|f', 'list finished testruns, OR combined with other state filters',                                                 ],
        [ 'running|r' , 'list running testruns, OR combined with other state filters',                                                  ],
        [ 'schedule|s', 'list scheduled testruns, OR combined with other state filters',                                                ],
        [ 'prepare|p' , 'list testruns not yet in any scheduling queue, OR combined with other state filters',                          ],
        [ 'queue|q=s@', 'list testruns assigned to this queue, OR combined with other queues, AND combined with other filters',         ],
        [ 'host|h=s@' , 'list testruns assigned to this queue, OR combined with other hosts, AND combined with other filters',          ],
        [ 'limit|l=i'   , "limit the number of testruns (default = $i_limit_default). A value smaller than 1 deactivates the limit.",   ],
        [ 'verbose|v' , 'print all output, without only print ids',                                                                     ],
        [ 'help|?'    , 'Print this help message and exit.',                                                                            ],
    ];
}


sub ar_get_rerun_testrun_parameters {
    return [
        [ 'id|i=i@'   , 'rerun particular testruns', 'Can be given multiple times.', ],
        [ 'notes|n=s' , 'add a description for new testruns',                        ],
        [ 'verbose|v' , 'print all output, without only print ids',                  ],
        [ 'help|?'    , 'Print this help message and exit.',                         ],
    ];
}


sub ar_get_delete_testrun_parameters {
    return [
        [ 'id|i=i@'  , 'delete particular testruns', 'Can be given multiple times.', ],
        [ 'force|f'  , 'really execute the command',                                 ],
        [ 'verbose|v', 'print all output, without only print ids',                   ],
        [ 'help|?'   , 'Print this help message and exit.',                          ],
    ];
}


sub ar_get_create_testrun_parameters {
    return [
        [
            'macroprecond|m=s',
            'use this macro precondition file',
        ],[
            'precondition|p=i@',
            'assigned precondition ids',
        ],[
            'owner|o=s',
            'default=$USER; user login name',
        ],[
            'topic|t=s',
            'default=Misc; one of: Kernel, Xen, KVM, Hardware, Distribution, Benchmark, Software, Misc',
        ],[
            'queue|q=s',
            'default=AdHoc',
        ],[
            'notes|n=s',
            'notes',
        ],[
            'rerun_on_error=i',
            'retry this testrun this many times if an error occurs',
        ],[
            'shortname|s=s',
            'shortname',
        ],[
            'earliest|e=s',
            q#default=now; don't start testrun before this time (format: YYYY-MM-DD hh:mm:ss or now)#,
        ],[
            'requested_host|rh=s@',
            'String; name one possible host for this testrequest;',
            'multiple requested hosts are OR evaluated, i.e. each is appropriate',
        ],[
            'requested_feature|rf=s@',
            'description of one requested feature of a matching host for this testrequest;',
            'multiple requested features are AND evaluated, i.e. each must fit;',
            'not evaluated if a matching requested host is found already',
        ],[
            'notify:s',
            q#create a notification for when the testrun is finished, possibly with filter for 'fail' or 'success'#,
        ],[
            'wait_after_tests',
            'default=0; wait after testrun for human investigation',
        ],[
            'verbose|v',
            'some more informational output',
        ],[
            'dryrun',
            'default=0; only print the preconditions to stdout and then exit',
        ],[
            'auto_rerun',
            'default=0; put this testrun into db again when it is chosen by scheduler',
        ],[
            'priority',
            'This is a very important testrun that should bypass scheduling and not wait for others',
        ],[
            'D=s%',
            'Define a key=value pair used in macro preconditions',
        ],[
            'help|?',
            'Print this help message and exit',
        ],
    ];
}


sub create_macro_preconditions {

    my ( $hr_options ) = @_;

    my $hr_d = $hr_options->{D}; # options are auto-down-cased
    my $b_dryrun = $hr_options->{dryrun};
    my $s_ttapplied = $hr_options->{macroprecond_evaluated};

    if ($b_dryrun) {
        print $s_ttapplied;
        exit 0;
    }

    require Tapper::Cmd::Precondition;
    return Tapper::Cmd::Precondition->new->add( $s_ttapplied );

}


sub s_create_testrun_parameter_check {

    my ( $hr_options ) = @_;

    if ( !$hr_options->{precondition} && !$hr_options->{macroprecond} ) {
        return q#At least one of "precondition" or "macroprecond" is required#;
    }
    if ( exists $hr_options->{rerun_on_error} && $hr_options->{rerun_on_error} !~ /^\d+$/ ) {
        return "value for rerun_on_error ($hr_options->{rerun_on_error}) is not an integer value";
    }
    if ( $hr_options->{earliest} ) {
        require DateTime::Format::Natural;
        my $or_parser           = DateTime::Format::Natural->new;
        $hr_options->{earliest} = $or_parser->parse_datetime( $hr_options->{earliest} );
        if ( $or_parser->success ) {
            if ( $hr_options->{verbose} ) {
                say $hr_options->{earliest}->strftime('%d.%m.%Y %T');
            }
        }
        else {
            return $or_parser->error;
        }
    }

    require Tapper::Model;
    if ( $hr_options->{requested_host} ) {
        for my $i_counter ( 0..$#{$hr_options->{requested_host}} ) {
            if (
                my $or_host =
                    Tapper::Model::model('TestrunDB')
                        ->resultset('Host')
                        ->search(
                            { name => $hr_options->{requested_host}[$i_counter] },
                            { rows => 1 },
                        )
                        ->first
            ) {
                $hr_options->{requested_host}[$i_counter] = $or_host->id;
            }
            else {
                die "Host '$hr_options->{requested_host}[$i_counter]' does not exist\n";
            }
        }
    }
    if ( $hr_options->{notify} ) {
        $hr_options->{notify} = lc $hr_options->{notify};
        if (! grep { $hr_options->{notify} eq $_ } qw/ pass fail / ) {
            die "invalid value for 'notify': valid values 'pass', 'fail'\n";
        }
    }

    require File::Slurp;
    if ( $hr_options->{macroprecond} ) {
        if ( -e $hr_options->{macroprecond} ) {

            require Tapper::Cmd;
            my $or_cmd = Tapper::Cmd->new;
            my $s_mpc_file = $hr_options->{macroprecond};
            my $hr_d = $hr_options->{D};

            $hr_options->{macroprecond_evaluated} = $or_cmd->apply_macro($s_mpc_file, $hr_d);
            if ( (my $s_required) = $hr_options->{macroprecond_evaluated} =~/^# (?:tapper[_-])?mandatory[_-]fields:\s*(.+)/m ) {
                my $re_delim = qr/,+\s*/;
                foreach my $s_field ( split $re_delim, $s_required ) {
                    $s_field =~ s/\s+//g;
                    my ( $s_name, undef ) = split /\./, $s_field;
                    if (! $hr_options->{D}{$s_name} ) {
                        die "Expected macro field '$s_name' missing.\n";
                    }
                }
            }

        }

    }

    return;

}


sub b_create_testrun {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_create_testrun_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME testrun-new [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( my $s_error = s_create_testrun_parameter_check( $hr_options ) ) {
        die 'error: ' . $s_error . "\n";
    }

    my @a_ids;
    if ( $hr_options->{macroprecond} ) {
        @a_ids = create_macro_preconditions( $hr_options );
    }
    if ( $hr_options->{precondition} ) {
        push @a_ids, @{$hr_options->{precondition}};
    }

    if (! @a_ids ) {
        die "error: No valid preconditions given\n";
    }

    require DateTime;
    my $hr_testrun = {
        wait_after_tests    => $hr_options->{wait_after_tests},
        priority            => $hr_options->{priority}            || 0,
        auto_rerun          => $hr_options->{auto_rerun}          || 0,
        earliest            => $hr_options->{earliest}            || DateTime->now,
        notes               => $hr_options->{notes}               || q##,
        owner               => $hr_options->{owner}               || $ENV{USER},
        queue               => $hr_options->{queue}               || 'AdHoc',
        rerun_on_error      => $hr_options->{rerun_on_error} ? int( $hr_options->{rerun_on_error} ) || 0 : 0,
        shortname           => $hr_options->{shortname}           || q##,
        topic               => $hr_options->{topic}               || 'Misc',
    };

    if ( exists $hr_options->{notify} ) {
        $hr_testrun->{notify} = $hr_options->{notify};
    }

    require Tapper::Cmd::Testrun;
    my $or_cmd = Tapper::Cmd::Testrun->new();
    my ( $i_testrun_id, $s_error ) = $or_cmd->add( $hr_testrun );

    if ( $i_testrun_id ) {
        if ( $s_error ) {
            say {*STDERR} "warning: $s_error";
        }
    }
    else {
        if ( $s_error ) {
            die "error: Can't create new testrun\n$s_error\n";
        }
        else {
            die "error: Can't create new testrun because of an unknown error\n";
        }
    }

    require Tapper::Model;
    my $or_testrun_search =
        Tapper::Model::model('TestrunDB')
            ->resultset('Testrun')
            ->find( $i_testrun_id )
    ;

    if ( my $retval = $or_cmd->assign_preconditions( $i_testrun_id, @a_ids ) ) {
        $or_testrun_search->delete();
        die $retval . "\n";
    }

    require Tapper::Cmd::Requested;

    my $or_cmd_req;
    if ( $hr_options->{requested_host} ) {
        $or_cmd_req = Tapper::Cmd::Requested->new;
        foreach my $s_host ( @{$hr_options->{requested_host}} ) {
            if (! $or_cmd_req->add_host( $i_testrun_id, $s_host, ) ) {
                die "error: adding host failed\n";
            }
        }
    }

    if ( $hr_options->{requested_feature} ) {
        $or_cmd_req ||= Tapper::Cmd::Requested->new;
        foreach my $s_feature ( @{$hr_options->{requested_feature}} ) {
            if (! $or_cmd_req->add_feature( $i_testrun_id, $s_feature ) ) {
                die "error: adding feature failed\n";
            }
        }
    }

    require DateTime;
    $or_testrun_search->testrun_scheduling->updated_at( DateTime->now->strftime('%F %T') );
    $or_testrun_search->testrun_scheduling->status('schedule');
    $or_testrun_search->testrun_scheduling->update;

    if ( $hr_options->{verbose} ) {
        say $or_testrun_search->to_string;
    }
    else {
        if ( $ENV{TAPPER_WITH_WEB} ) {
            my $s_webserver = Tapper::Config->subconfig->{webserver};
            say "http://$s_webserver/tapper/testrun/id/$i_testrun_id";
        }
        else {
            say $i_testrun_id;
        }
    }

    return;

}


sub b_delete {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_delete_testrun_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME testrun-delete [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if (! $hr_options->{force} ) {
        say {*STDERR} "info: Skip all testruns. Use --force.";
        return;
    }

    require Tapper::Cmd::Testrun;
    my $or_cmd = Tapper::Cmd::Testrun->new();
    for my $i_testrun_id ( @{$hr_options->{id}} ){
        if ( my $s_error = $or_cmd->del( $i_testrun_id ) ) {
            die "error: Can not delete testrun $i_testrun_id: $s_error\n";
        }
        if ( $hr_options->{verbose} ) {
            say "info: deleted testrun $i_testrun_id\n";
        }
    }

    return;

}


sub b_rerun {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_rerun_testrun_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME testrun-rerun [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    require Tapper::Cmd::Testrun;
    my $or_testrun = Tapper::Cmd::Testrun->new();

    if ( my $ar_testrun_ids = $hr_options->{id} ) {
        for my $i_testrun_id ( @{$ar_testrun_ids} ) {
            if ( my $i_new_testrun_id = $or_testrun->rerun( $i_testrun_id, $hr_options ) ) {
                if ( $hr_options->{verbose} ) {
                    my $or_new_testrun = Tapper::Model::model->resultset('TestRun')->find($i_new_testrun_id);
                    b_print_testruns( $or_new_testrun );
                    say 'info: original id: ', $i_testrun_id;
                }
                else {
                        say $i_new_testrun_id;
                }
            }
            else {
                die "error: Can't restart testrun $i_testrun_id\n";
            }
        }
        return;
    }
    else {
        die "error: missing required parameter id\n";
    }

}


sub ar_get_queue_ids {

    my ( $or_schema, $ar_queue_names ) = @_;

    my @a_check_queues;
    foreach my $s_queue ( @{$ar_queue_names} ) {
        if (
            my $or_queue_rs =
                $or_schema
                    ->resultset('Queue')
                    ->search({
                        name => $s_queue,
                    },{
                        'select'   => [ 'id' ],
                    })
        ) {
            push @a_check_queues, $or_queue_rs->get_column('id')->all
        }
        else {
            die "error: No such queue: $s_queue\n";
        }
    }

    if ( @a_check_queues ) {
        return @a_check_queues;
    }
    return;

}


sub ar_get_host_ids {

    my ( $or_schema, $ar_host_names ) = @_;

    my @a_check_hosts = ();
    foreach my $s_host ( @{$ar_host_names} ) {
        if (
            my $or_host_rs =
                $or_schema
                    ->resultset('Host')
                    ->search({
                        name => $s_host
                    },{
                        'select'  => [ 'id' ],
                    })
        ) {
            push @a_check_hosts, $or_host_rs->get_column('id')->all;
        }
        else {
            die "error: No such host: $s_host\n";
        }
    }

    if ( @a_check_hosts ) {
        return @a_check_hosts;
    }
    return;

}


sub b_list_testrun {

    my ( $or_app_rad ) = @_;

    my $or_querylog;

    require Tapper::Model;
    my $or_schema = Tapper::Model::model('TestrunDB');

    if ( $ENV{DEBUG} ) {
        require DBIx::Class::QueryLog;
        $or_querylog = DBIx::Class::QueryLog->new();
        $or_schema->storage->debugobj( $or_querylog );
        $or_schema->storage->debug( 1 );
    }

    my $ar_parameters = ar_get_list_testrun_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my %h_options = %{$or_app_rad->options};

    if ( $h_options{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME testrun-rerun [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    my @a_given_options = grep {
        $h_options{$_}
    } qw/ finished running schedule prepare queue host /;

    my $hr_search      = {};
    my @a_check_queues = ();

    if ( my $i_testrun_id = $h_options{id} ) {

        if ( @a_given_options ) {
            print {*STDERR} "error: other filters doesn't make sense with filter 'id'\n";
        }

        # filter 'id' doesn't make sense without verbose
        $h_options{verbose} = 1;

        $hr_search = { 'me.id' => $i_testrun_id }

    }
    elsif ( @a_given_options ) {

        if ( my @a_state_selection = grep { $h_options{$_} } qw/ finished running schedule prepare / ) {
            $hr_search->{'testrun_scheduling.status'} ||= \@a_state_selection;
        }

        if ( my $ar_queue_ids = ar_get_queue_ids( $or_schema, $h_options{queue} ) ) {
            $hr_search->{'testrun_scheduling.queue_id'} = { -in => $ar_queue_ids };
        }

        if ( my $ar_host_ids = ar_get_queue_ids( $or_schema, $h_options{host} ) ) {
            $hr_search->{-or} = [
                -and => [
                    -not                         => { 'testrun_scheduling.status' => 'schedule',       },
                    'testrun_scheduling.host_id' => { -in                         => $ar_host_ids,  },
                ],
                -and => [
                    'testrun_scheduling.status'  => 'schedule',
                    'requested_hosts.host_id'    => { -in  => $ar_host_ids, },
                ],
            ];
        }

    }

    my $hr_search_options = {
        order_by => { -desc => 'me.id' }
    };

    if ( exists $h_options{limit} ) {
        if ( $h_options{limit} > 0 ) {
            $hr_search_options->{rows} = $h_options{limit};
        }
    }
    else {
        $hr_search_options->{rows} = $i_limit_default;
    }
    if ( $h_options{verbose} ) {
        $hr_search_options->{'prefetch'} = [
            {
                'testrun_scheduling' => [
                    'queue',
                    {
                        'requested_hosts' => 'host',
                    },
                ],
            },
            {
                'testrun_scheduling' => 'host',
            },
        ];
    }
    else {
        $hr_search_options->{'join'}   = 'testrun_scheduling';
        $hr_search_options->{'select'} = ['id'];
    }

    my $or_testrun_rs =
        $or_schema
            ->resultset('Testrun')
            ->search( $hr_search, $hr_search_options )
    ;

    if ( $h_options{verbose} ) {
        Tapper::CLI::Testrun::b_print_testruns( $or_testrun_rs );
    }
    else {
        foreach my $i_testrun_id ( $or_testrun_rs->get_column('id')->all ) {
            say $i_testrun_id;
        }
    }

    if ( $ENV{DEBUG} ) {

        require DBIx::Class::QueryLog::Analyzer;
        my $or_analyzer = DBIx::Class::QueryLog::Analyzer->new({
            querylog => $or_querylog,
        });

        require Data::Dumper;
        say {*STDERR} "Query count: " . scalar( @{$or_analyzer->get_sorted_queries} );
        say {*STDERR} Data::Dumper::Dumper([
            $or_analyzer->get_sorted_queries
        ]);

    }

    return;

}


sub testrun_update
{
        my ($c) = @_;
        $c->getopt( 'id=i@','status=s', 'topic=s', 'auto-rerun!','help|?', 'verbose|v' );
        if ( $c->options->{help} or not $c->options->{id}) {
                say STDERR "Please set at least one testrun id with --id!" unless @{$c->options->{id} || []};
                say STDERR "Please set an update action" unless ($c->options->{state} or defined $c->options->{"auto-rerun"});
                say STDERR "$PROGRAM_NAME testrun-update --id=s@ --status=s --auto_rerun --no-auto-rerun --verbose|v [--help|?]";
                say STDERR "    --id            Id of the testrun to update, can be given multiple times";
                say STDERR "    --topic         one of: Kernel, Xen, KVM, Hardware, Distribution, Benchmark, Software, Misc";
                say STDERR "    --status        Set testrun to given status, can be one of 'prepare', 'schedule', 'finished'.";
                say STDERR "    --auto-rerun    Activate auto-rerun on testrun. ";
                say STDERR "    --no-auto-rerun Activate auto-rerun on testrun";
                say STDERR "    --verbose|v     Print new state of testrun (will only print id of updated testruns without)";
                say STDERR "    --help|?        Print this help message and exit";
                return;
        }

        require Tapper::Model;
 ID:
        foreach my $testrun_id (@{$c->options->{id}}) {
                my $testrun = Tapper::Model::model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                if (not $testrun) {
                        say STDERR "Testrun with id $testrun_id not found. Skipping!";
                        next ID;
                }

                if ( $c->options->{topic} ) {
                    $testrun->update_content({
                        topic => $c->options->{topic},
                    });
                }

                if (not ($testrun->testrun_scheduling->status eq 'prepare' or
                         $testrun->testrun_scheduling->status eq 'schedule')
                   )
                {
                        say STDERR "Can only update testruns in state 'schedule' and 'finished'. Updating testruns in other states will break something. Please consider tapper testrun-rerun";
                        next ID;
                }

                if ($c->options->{status}) {
                        $testrun->testrun_scheduling->status($c->options->{status});
                        $testrun->testrun_scheduling->update;
                }
                if (defined($c->options->{"auto-rerun"})) {
                        $testrun->testrun_scheduling->auto_rerun($c->options->{"auto-rerun"});
                        $testrun->testrun_scheduling->update;
                }
                if ($c->options->{verbose}) {
                        b_print_testruns($testrun);
                } else {
                        say $testrun_id;
                }
        }

}


sub b_cancel
{

        my ($c) = @_;
        $c->getopt( 'id=i@','comment=s','help|?', 'verbose|v' );
        if ( $c->options->{help} or not $c->options->{id}) {
                say STDERR "Please set at least one testrun id with --id!" unless @{$c->options->{id} || []};
                say STDERR "$PROGRAM_NAME testrun-cancel --id=i@ [--comment=s]  [--verbose|v] [--help|?]";
                say STDERR "    --id            Id of the testrun to cancel, can be given multiple times";
                say STDERR "    --comment       A comment why the testrun(s) were cancelled";
                say STDERR "    --verbose|v     Tell user what we just did (without -v only the testrun id will be printed in the success case)";
                say STDERR "    --help|?        Print this help message and exit";
                return;
        }

        require Tapper::Cmd::Testrun;
        my $cmd = Tapper::Cmd::Testrun->new();
        foreach my $id (@{$c->options->{id}}) {
                my $retval = $cmd->cancel($id, $c->options->{comment});
                warn $retval if $retval;
        }
        return;
}



sub b_pause
{

        my ($c) = @_;
        $c->getopt( 'id=i@','help|?', 'verbose|v' );
        if ( $c->options->{help} or not $c->options->{id}) {
                say STDERR "Please set at least one testrun id with --id!" unless @{$c->options->{id} || []};
                say STDERR "$PROGRAM_NAME testrun-pause --id=i@ [--verbose|v] [--help|?]";
                say STDERR "    --id            Id of the testrun to pause, can be given multiple times";
                say STDERR "    --help|?        Print this help message and exit";
                return;
        }

        require Tapper::Cmd::Testrun;
        my $cmd = Tapper::Cmd::Testrun->new();
        foreach my $id (@{$c->options->{id}}) {
                my $retval = $cmd->pause($id);
                say $id if $retval;
        }
        return;
}



sub b_continue
{

        my ($c) = @_;
        $c->getopt( 'id=i@','help|?', 'verbose|v' );
        if ( $c->options->{help} or not $c->options->{id}) {
                say STDERR "Please set at least one testrun id with --id!" unless @{$c->options->{id} || []};
                say STDERR "$PROGRAM_NAME testrun-continue --id=i@ [--verbose|v] [--help|?]";
                say STDERR "    --id            Id of the testrun to continue, can be given multiple times";
                say STDERR "    --help|?        Print this help message and exit";
                return;
        }

        require Tapper::Cmd::Testrun;
        my $cmd = Tapper::Cmd::Testrun->new();
        foreach my $id (@{$c->options->{id}}) {
                my $retval = $cmd->continue($id);
                say $id if $retval;
        }
        return;
}



sub setup {

    my ( $or_apprad ) = @_;

    $or_apprad->register( 'testrun-list'   , \&b_list_testrun   , 'Show all testruns matching a given condition', );
    $or_apprad->register( 'testrun-update' , \&testrun_update   , 'Update an existing testrun', );
    $or_apprad->register( 'testrun-rerun'  , \&b_rerun          , 'Rerun an existing testrun with the same preconditions', );
    $or_apprad->register( 'testrun-delete' , \&b_delete         , 'Delete a testrun', );
    $or_apprad->register( 'testrun-pause'  , \&b_pause          , 'Pause a not-yet-running testrun', );
    $or_apprad->register( 'testrun-continue',\&b_continue       , 'Continue a paused testrun', );
    $or_apprad->register( 'testrun-cancel' , \&b_cancel         , 'Cancel a running testrun', );
    $or_apprad->register( 'testrun-new'    , \&b_create_testrun , 'Create a testrun', );

    if ( $or_apprad->can('group_commands') ) {
        $or_apprad->group_commands(
            'Testrun commands',
                'testrun-list',
                'testrun-new',
                'testrun-update',
                'testrun-rerun',
                'testrun-delete',
                'testrun-pause',
                'testrun-continue',
                'testrun-cancel',
        );
    }

    return;

}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Testrun

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg} unless otherwise stated.

    use App::Rad;
    use Tapper::CLI::Testrun;
    Tapper::CLI::Testrun::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Testrun - Tapper - testrun related commands for the tapper CLI

=head1 FUNCTIONS

=head2 b_print_single_testrun

print column data for a single testrun row to STDOUT

=head2 b_print_testruns

print column data for resultset to STDOUT

=head2 ar_get_list_testrun_parameters

return list testrun parameters and descriptions

=head2 ar_get_rerun_testrun_parameters

return rerun testrun parameters and descriptions

=head2 ar_get_delete_testrun_parameters

return delete testrun parameters and descriptions

=head2 ar_get_create_testrun_parameters

return create testrun parameters and descriptions

=head2 create_macro_preconditions

Process a macroprecondition. This includes substitions using
Template::Toolkit, separating the individual preconditions that are part of
the macroprecondition and putting them into the database. Parameters fit the
App::Cmd::Command API.

@param hashref - hash containing options
@param hashref - hash containing arguments

@returnlist array containing precondition ids

=head2 s_create_testrun_parameter_check

check command line parameters for create testrun and return error if exists

=head2 b_create_testrun

create a testrun

=head2 b_delete

delete a testrun

=head2 b_rerun

rerun an existing testrun

=head2 ar_get_queue_ids

return an array reference of queue_ids for a an array reference of queue_names

=head2 ar_get_host_ids

return an array reference of host_ids for a an array reference of host_names

=head2 b_list_testrun

list existing restuns

=head2 testrun_update

Update values of an existing testrun.

=head2 b_cancel

Cancel a running testrun. If the given testrun is currently not running,
the function does the obvious right thing and also warns the user.

=head2 b_pause

Pause a not-yet-running testrun.

=head2 b_continue

Continue a paused testrun.

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
