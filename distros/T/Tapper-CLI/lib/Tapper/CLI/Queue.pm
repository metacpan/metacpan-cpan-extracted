package Tapper::CLI::Queue;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Queue::VERSION = '5.0.7';

use 5.010;
use warnings;
use strict;
use feature qw/ say /;
use English qw/ -no_match_vars /;

# list limit default value
my $i_limit_default = 50;


sub b_print_single_queue {

    my ( $or_queue ) = @_;

    print  "\n";
    printf "%22s: %s\n", 'Id'       , $or_queue->id;
    printf "%22s: %s\n", 'Name'     , $or_queue->name;
    printf "%22s: %s\n", 'Priority' , $or_queue->priority;
    printf "%22s: %s\n", 'Runcount' , $or_queue->runcount;
    printf "%22s: %s\n", 'Active'   , $or_queue->active;

    if ( $or_queue->queuehosts->count ) {
        printf "%22s: %s\n",
            'Bound hosts',
            join ', ', map { $_->host->name } $or_queue->queuehosts->all;
    }
    if ( $or_queue->deniedhosts->count ) {
        printf "%22s: %s\n",
            'Denied hosts',
            join ', ', map { $_->host->name } $or_queue->deniedhosts->all;
    }
    if ( my @a_testrun_ids = $or_queue->queued_testruns->get_column('testrun_id')->all ) {

        my $i_counter           = 0;
        my $i_max_elements      = 15;
        my $i_testrun_id_length = length $a_testrun_ids[-1];

        while ( scalar( @a_testrun_ids ) > 0 ) {
            printf "%22s: %s\n",
                $i_counter++ ? q## : 'Queued testruns (ids)',
                join ', ', map { sprintf '%' . $i_testrun_id_length . 's', $_ } splice @a_testrun_ids, 0, $i_max_elements
            ;
        }
    }

    return 1;

}


sub b_print_queues {

    my ( $or_queues ) = @_;

    if ( $or_queues->isa('DBIx::Class::ResultSet') ) {
        for my $or_queue ( $or_queues->all ) {
            b_print_single_queue( $or_queue );
        }
    }
    else {
        b_print_single_queue( $or_queues );
    }
    print "\n";

    return 1;

}


sub ar_get_delete_queues_parameters {
    return [
        [ 'id|i=i@'   , 'delete particular queues', 'Can be given multiple times.', ],
        [ 'name|n=s@' , 'delete by queue name', 'Can be given multiple times.',     ],
        [ 'force|f'   , 'really execute the command',                               ],
        [ 'verbose|v' , 'print all output, without only print ids',                 ],
        [ 'help|?'    , 'Print this help message and exit.',                        ],
    ];
}


sub b_delete_queues {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_delete_queues_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME queue-delete [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( !$hr_options->{id} && !$hr_options->{name} ) {
        die "error: missing paramet 'id' or 'name'\n";
    }

    require Tapper::Model;

    my %h_queue_ids = map { $_ => q## } @{$hr_options->{id}};
    foreach my $s_name ( @{$hr_options->{name}} ) {
        if (
            my $or_host =
                Tapper::Model::model('TestrunDB')
                    ->resultset('Queue')
                    ->find({
                        name        => $s_name,
                        is_deleted  => 0,
                    })
        ) {
            $h_queue_ids{$or_host->id} = $or_host;
        }
        else {
            die "error: Can't find host by name '$s_name'\n";
        }
    }

    if (! $hr_options->{force} ) {
        say {*STDERR} "info: Skip deleting queues unless --force is used.";
        return;
    }

    require Tapper::Cmd::Queue;
    my $or_cmd = Tapper::Cmd::Queue->new();
    foreach my $i_queue_id ( sort { $h_queue_ids{$a} cmp $h_queue_ids{$b} } keys %h_queue_ids ){

        my $or_queue = $h_queue_ids{$i_queue_id};

        # host object isn't set by loop above. look for object by id.
        if (! $or_queue ) {
            if (!
                (
                    $or_queue =
                        Tapper::Model::model('TestrunDB')
                            ->resultset('Queue')
                            ->find( $i_queue_id )
                )
            ) {
                die "error: Can't find host by id '$i_queue_id'\n";
            }
        }

        $or_cmd->del( $or_queue );

        if ( $hr_options->{verbose} ) {
            say 'info: Deleted queue ' . $or_queue->name . ": $i_queue_id";
        }

    }

    return;

}


sub ar_get_list_queues_parameters {
    return [
        [ 'id|i=i@'     , 'list particular preconditions', 'Can be given multiple times.',                                              ],
        [ 'name|n=s@'   , 'list preconditions by name', 'Can be given multiple times.',                                                 ],
        [ 'minprio=i'   , 'list queues with at least this priority level',                                                              ],
        [ 'maxprio=i'   , 'list queues with at most this priority level',                                                               ],
        [ 'all'         , 'list all queues, even deleted ones',                                                                         ],
        [ 'active'      , 'list active queues',                                                                                         ],
        [ 'limit|l=i'   , "limit the number of testruns (default = $i_limit_default). A value smaller than 1 deactivates the limit.",   ],
        [ 'verbose|v'   , 'print all output, without only print ids',                                                                   ],
        [ 'help|?'      , 'Print this help message and exit.',                                                                          ],
    ];
}


sub b_list_queues {

    my ( $or_app_rad ) = @_;

    my $or_querylog;

    require Tapper::Model;
    my $or_schema = Tapper::Model::model('TestrunDB');

    if ( $ENV{TAPPER_TRACE} ) {
        require DBIx::Class::QueryLog;
        $or_querylog = DBIx::Class::QueryLog->new();
        $or_schema->storage->debugobj( $or_querylog );
        $or_schema->storage->debug( 1 );
    }

    my $ar_parameters = ar_get_list_queues_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME queue-list [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    my $hr_search = {};
    if ( my $ar_queue_ids = $hr_options->{id} ) {
        if ( my $ar_queue_names = $hr_options->{name} ) {
            $hr_search->{-or} = [
                { 'me.id'   => { -in => $ar_queue_ids } },
                { 'me.name' => { -in => $ar_queue_names } },
            ];
        }
        else {
            $hr_search->{'me.id'} = { -in => $ar_queue_ids };
        }
    }
    elsif ( my $ar_queue_names = $hr_options->{name} ) {
        $hr_search->{'me.name'} = { -in => $ar_queue_names };
    }

    if ( $hr_options->{minprio} ) {
        ($hr_search->{'me.priority'} ||= {})->{'>='} = $hr_options->{minprio};
    }
    if ( $hr_options->{maxprio} ) {
        ($hr_search->{'me.priority'} ||= {})->{'<='} = $hr_options->{maxprio};
    }

    if ( $hr_options->{active} ) {
        $hr_search->{'me.active'} = 1;
    }
    if ( !$hr_options->{all} && !$hr_options->{id} && !$hr_options->{name} ) {
        $hr_search->{'me.is_deleted'} = 0;
    }

    my $hr_search_options = {
        order_by => { -desc => 'me.id' },
    };
    if ( exists $hr_options->{limit} ) {
        if ( $hr_options->{limit} > 0 ) {
            $hr_search_options->{rows} = $hr_options->{limit};
        }
    }
    else {
        $hr_search_options->{rows} = $i_limit_default;
    }
    if ( $hr_options->{verbose} ) {
        $hr_search_options->{'prefetch'} = [
            { 'queuehosts'  => 'host', },
            { 'deniedhosts' => 'host', },
        ];
    }
    else {
        $hr_search_options->{'select'} = ['id','name'];
    }

    my $or_queue_rs =
        $or_schema
            ->resultset('Queue')
            ->search( $hr_search, $hr_search_options )
    ;

    if ( $hr_options->{verbose} ) {
        b_print_queues( $or_queue_rs );
    }
    else {
        say "id     name";
        foreach my $or_queue ( $or_queue_rs->all ) {
            printf "%06d %s\n", $or_queue->id, $or_queue->name;
        }
    }

    if ( $ENV{TAPPER_TRACE} ) {

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


sub ar_get_new_queue_parameters {
    return [
        [ 'name|n=s'      , 'name',                                                    ],
        [ 'priority|p=i'  , 'priority',                                                ],
        [ 'active|a'      , 'set active flag to this value, prepend with no to unset', ],
        [ 'verbose|v'     , 'some more informational output',                          ],
        [ 'help|?'        , 'Print this help message and exit.',                       ],
    ];
}


sub b_new_queue {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_new_queue_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME queue-new [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    my $hr_queue = {
         name       => $hr_options->{name},
         priority   => $hr_options->{priority},
         active     => $hr_options->{active} // 0,
    };

    require Tapper::Model;
    require Tapper::Cmd::Queue;
    my $or_cmd = Tapper::Cmd::Queue->new();
    if ( my $i_queue_id = $or_cmd->add( $hr_queue ) ) {
        if ( $hr_options->{verbose} ) {
            b_print_single_queue(
                Tapper::Model::model('TestrunDB')
                    ->resultset('Queue')
                    ->search({ id => $i_queue_id }, { rows => 1 })
                    ->first
            );
        }
        else {
            say $i_queue_id;
        }
    }
    else {
        die "error: Can't create new queue because of an unknown error\n";
    }

    return;

}


sub ar_get_rename_queue_parameters {
    return [
        [ 'oldname|o=s', 'name of the queue to be changed',     ],
        [ 'newname|n=s', 'new name of the queue',               ],
        [ 'help|?'     , 'Print this help message and exit.',   ],
    ];
}


sub b_rename_queue {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_rename_queue_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME queue-rename [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    for my $s_parameter (qw/ oldname newname /) {
        if (! $hr_options->{$s_parameter} ) {
            die "error: missing argument '$s_parameter'\n";
        }
    }

    require Tapper::Model;

    if (
        my $or_queue =
            Tapper::Model::model('TestrunDB')
                ->resultset('Queue')
                ->search({ name => $hr_options->{oldname} }, { rows => 1 })
                ->first
    ) {
        require DateTime;
        $or_queue->name( $hr_options->{newname} );
        $or_queue->updated_at( DateTime->now->strftime('%F %T') );
        $or_queue->update;

        say "info: $hr_options->{oldname} is now known as $hr_options->{newname}";
    }
    else {
        die "error: No such queue: " . $hr_options->{oldname} . "\n";
    }

    return;

}


sub ar_get_update_queue_parameters {
    return [
        [ 'id|i=i'      , 'id of the queue to be changed',                          ],
        [ 'name|n=s'    , 'name of the queue to be changed',                        ],
        [ 'priority|p=i', 'priority',                                               ],
        [ 'active|a=i'  , 'set active flag to this value, prepend with no to unset',],
        [ 'verbose|v'   , 'some more informational output',                         ],
        [ 'help|?'      , 'Print this help message and exit.',                      ],
    ];
}


sub b_update_queue {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_update_queue_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME queue-update [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( !$hr_options->{id} && !$hr_options->{name} ) {
        die "error: parameter 'id' or 'name' is required\n";
    }
    if ( defined $hr_options->{active} && !grep { $hr_options->{active} == $_ } 0,1 ) {
        die "error: invalid value for 'active'. 0 or 1 are allowed\n";
    }

    require Tapper::Model;

    if (
        my $or_queue =
            Tapper::Model::model('TestrunDB')
                ->resultset('Queue')
                ->find(
                    $hr_options->{id}
                        ? { id   => $hr_options->{id} }
                        : { name => $hr_options->{name} }
                )
    ) {

        require Tapper::Cmd::Queue;
        my $or_cmd = Tapper::Cmd::Queue->new();

        my $b_update    = 0;
        my $hr_new_opts = {};
        if ( defined $hr_options->{priority} && $hr_options->{priority} ne $or_queue->priority ) {
            $b_update                = 1;
            $hr_new_opts->{priority} = $hr_options->{priority};
        }
        if ( defined $hr_options->{active} && $hr_options->{active} ne $or_queue->active ) {
            $b_update                = 1;
            $hr_new_opts->{active}   = $hr_options->{active};
        }

        if ( $b_update ) {
            if (! $or_cmd->update( $or_queue, $hr_new_opts) ) {
                die 'error: cannot update queue: ' . $or_queue->id . "\n";
            }
        }
        else {
            say {*STDERR} 'info: queue is already up to date';
        }

        if ( $hr_options->{verbose} ) {
            b_print_single_queue( $or_queue );
        }
        else {
            say 'info: successfully updated queue ' . $or_queue->id;
        }

    }
    else {
        die 'error: cannot find queue ' . ( $hr_options->{id} ? "by id '$hr_options->{id}'" : "by name '$hr_options->{name}'" ) . "\n";
    }

    return;

}


sub setup {

    my ( $or_apprad ) = @_;

    $or_apprad->register( 'queue-list'  , \&b_list_queues  , 'Show all queues matching a given condition', );
    $or_apprad->register( 'queue-new'   , \&b_new_queue    , 'Create a queue', );
    $or_apprad->register( 'queue-update', \&b_update_queue , 'Update a existing queue', );
    $or_apprad->register( 'queue-rename', \&b_rename_queue , 'Rename a queue', );
    $or_apprad->register( 'queue-delete', \&b_delete_queues, 'Delete an existing queue', );

    if ( $or_apprad->can('group_commands') ) {
        $or_apprad->group_commands(
            'Testrun commands',
                'queue-list',
                'queue-new',
                'queue-rename',
                'queue-delete',
        );
    }

    return;

}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Queue

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg} unless otherwise stated.

    use App::Rad;
    use Tapper::CLI::Test;
    Tapper::CLI::Test::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Queue - Tapper - queue related commands for the Tapper CLI

=head1 FUNCTIONS

=head2 b_print_single_queue

print column data for a single queue row to STDOUT

=head2 b_print_queues

print column data for queues to STDOUT

=head2 b_get_delete_queue_parameters

return delete queue parameters and descriptions

=head2 b_delete_queues

delete queues

=head2 b_get_list_queue_parameters

return list queue parameters and descriptions

=head2 b_list_queues

list existing queues

=head2 ar_get_new_queue_parameters

return new queue parameters and descriptions

=head2 b_new_queue

add a new queue

=head2 ar_get_rename_queue_parameters

return rename queue parameters and descriptions

=head2 b_rename_queue

rename a queue

=head2 ar_get_update_queue_parameters

return update queue parameters and descriptions

=head2 b_update_queue

update a existing queue

=head2 setup

Initialize the queue functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
