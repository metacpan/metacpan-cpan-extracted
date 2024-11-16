package Tapper::CLI::Host;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::Host::VERSION = '5.0.8';
use 5.010;

use warnings;
use strict;
use English qw/ -no_match_vars /;


sub host_feature_summary
{
        my ($host) = @_;

        return join(",",
                    map { $_->value }
                    sort { $a->entry cmp $b->entry }
                    grep { $_->entry =~ /^(key_word|socket_type|revision)$/ }
                    $host->features->all
                   );
}


sub i_add_queues {

    my ( $or_host, $s_type, $ar_queues ) = @_;

    require Tapper::Model;

    my $i_success_counter = 0;
    foreach my $s_queue ( @{$ar_queues} ) {
        if (
            my $or_queue =
                Tapper::Model::model('TestrunDB')
                    ->resultset('Queue')
                    ->search({
                        name => $s_queue,
                    },{
                        prefetch => [qw/ queuehosts deniedhosts /],
                    })
                    ->first
        ) {
            if ( $s_type eq 'bound' ) {
                if ( grep { $_ == $or_host->id } $or_queue->deniedhosts->get_column('host_id')->all ) {
                    die "error: you cannot add an bound-queue '$s_queue' for a already denied queue for host '" . $or_host->name . "'\n";
                }
                elsif ( grep { $_ == $or_host->id } $or_queue->queuehosts->get_column('host_id')->all ) {
                    die "error: queue '$s_queue' already bound to host '" . $or_host->name . "'\n";
                }
                else {
                    if (
                        Tapper::Model::model('TestrunDB')
                            ->resultset('QueueHost')
                            ->new({
                                host_id  => $or_host->id,
                                queue_id => $or_queue->id,
                            })
                            ->insert()
                    ) {
                        $i_success_counter++;
                    }
                    else {
                        die "error: cannot add queue '$s_queue'\n";
                    }
                }
            }
            elsif ( $s_type eq 'denied' ) {
                if ( $or_queue->queuehosts->count ) {
                    die "error: you cannot add an denied-queue '$s_queue' for a already bind queue for host '" . $or_host->name . "'\n";
                }
                elsif ( $or_queue->deniedhosts->count ) {
                    die "error: queue '$s_queue' already denied for host '" . $or_host->name . "'\n";
                }
                else {
                    if (
                        Tapper::Model::model('TestrunDB')
                            ->resultset('DeniedHost')
                            ->new({
                                host_id  => $or_host->id,
                                queue_id => $or_queue->id,
                            })
                            ->insert()
                    ) {
                        $i_success_counter++;
                    }
                    else {
                        die "error: cannot add queue '$s_queue'\n";
                    }
                }
            }
            else {
                warn "unknown type '$s_type' for sub i_delete_queues";
                die "error: internal processing error\n";
            }
        }
        else {
            die "error: did not find queue '$s_queue'\n";
        }
    }

    return $i_success_counter;

}


sub i_delete_queues {

    my ( $or_host, $s_type, $ar_queues ) = @_;

    my $s_relation_table;
    if ( $s_type eq 'bound' ) {
         $s_relation_table = 'QueueHost';
    }
    elsif ( $s_type eq 'denied' ) {
        $s_relation_table = 'DeniedHost';
    }
    else {
        die "error: unknown type '$s_type' for sub i_delete_queues\n";
    }

    require Tapper::Model;

    my $i_success_counter = 0;
    foreach my $s_queue ( @{$ar_queues} ) {
        if ( $s_queue eq '' ) {
            return
                Tapper::Model::model('TestrunDB')
                    ->resultset( $s_relation_table )
                    ->search({host_id => $or_host->id})
                    ->delete_all
            ;
        }
        else {
            if (
                my $or_queue =
                    Tapper::Model::model('TestrunDB')
                        ->resultset('Queue')
                        ->search({name => $s_queue}, {rows => 1})
                        ->first
            ) {
                my $or_queue_host =
                    Tapper::Model::model('TestrunDB')
                        ->resultset( $s_relation_table )
                        ->search({
                            host_id  => $or_host->id,
                            queue_id => $or_queue->id
                        })
                ;
                if ( $or_queue_host->count ) {
                    $i_success_counter += $or_queue_host->delete_all;
                }
                else {
                    die "error: queue '$s_queue' isn't related with host '" . $or_host->name . "'\n";
                }
            }
            else {
                die "error: no such queue '$s_queue'\n";
            }
        }
    }

    return $i_success_counter;

}


sub b_update_grub {

    my ( $s_hostname ) = @_;

    require Tapper::Model;
    return
        Tapper::Model::model('TestrunDB')
            ->resultset('Message')
            ->new({
                type    => 'action',
                message => {
                    action => 'updategrub',
                    host   => $s_hostname,
                },
            })
            ->insert
    ;

}


sub hr_get_hosts_by_options {

    my ( $hr_options ) = @_;

    require Tapper::Model;

    my %h_host_ids = map { $_ => q## } @{$hr_options->{id}};
    foreach my $s_name ( @{$hr_options->{name}} ) {
        if (
            my $or_host =
                Tapper::Model::model('TestrunDB')
                    ->resultset('Host')
                    ->find({
                        name        => $s_name,
                        is_deleted  => 0,
                    })
        ) {
            $h_host_ids{$or_host->id} = $or_host;
        }
        else {
            die "error: Can't find host by name '$s_name'\n";
        }
    }

    return \%h_host_ids;

}


sub ar_get_free_host_parameters {
    return [
        'id|i=i@'       , 'free particular hosts', 'Can be given multiple times.',
        'name|n=s@'     , 'free by host name', 'Can be given multiple times.',
        'comment|c=s'   , 'describe why the host is freed',
        'verbose|v'     , 'print all output, without only print ids',
        'help|?'        , 'Print this help message and exit.',
    ];
}


sub b_free_host {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_free_host_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME host-free [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( !$hr_options->{id} && !$hr_options->{name} ) {
        die "error: missing parameter 'id' or 'name'\n";
    }

    my $hr_host_ids    = hr_get_hosts_by_options( $hr_options );
    my @a_sorted_hosts = sort { $hr_host_ids->{$a} cmp $hr_host_ids->{$b} } keys %{$hr_host_ids};

    foreach my $i_host_id ( @a_sorted_hosts ){

        my $or_host = $hr_host_ids->{$i_host_id};

        # host object isn't set by loop above. look for object by id.
        if (! $or_host ) {
            if (!
                (
                    $or_host =
                        Tapper::Model::model('TestrunDB')
                            ->resultset('Host')
                            ->find( $i_host_id )
                )
            ) {
                die "Can't find host by id '$i_host_id'\n";
            }
        }

        if (
            my @a_testrun_ids =
                Tapper::Model::model('TestrunDB')
                    ->resultset('TestrunScheduling')
                    ->search({
                        host_id => $i_host_id,
                        status  => 'running',
                    }, {
                        select  => ['testrun_id'],
                    })
                    ->get_column('testrun_id')
                    ->all
        ) {
            my $hr_msg = { 'state' => 'quit', };
            if ( $hr_options->{comment} ) {
               $hr_msg->{error} = $hr_options->{comment};
            }
            for my $i_testrun_id ( @a_testrun_ids ) {
                if (!
                    Tapper::Model::model('TestrunDB')
                        ->resultset('Message')
                        ->new({
                            testrun_id => $i_testrun_id,
                            message    => $i_host_id,
                        })
                        ->insert
                ) {
                    die "freeing host failed: $i_host_id\n";
                }
            }
            if ( $hr_options->{verbose} ) {
                say "info: freeing host successful: $i_host_id";
            }
        }
        else {
            say "info: host is already free: $i_host_id";
        }

    }

    return;

}


sub ar_get_delete_parameters {
    return [
        [ 'id|i=i@'   , 'delete particular hosts', 'Can be given multiple times.',  ],
        [ 'name|n=s@' , 'delete by host name', 'Can be given multiple times.',      ],
        [ 'force|f'   , 'really execute the command',                               ],
        [ 'verbose|v' , 'print all output, without only print ids',                 ],
        [ 'help|?'    , 'Print this help message and exit.',                        ],
    ];
}


sub b_delete {

    my ( $or_app_rad ) = @_;

    require Tapper::Model;

    my $ar_parameters = ar_get_delete_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME host-delete [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( !$hr_options->{id} && !$hr_options->{name} ) {
        die "error: missing parameter 'id' or 'name'\n";
    }

    my $hr_host_ids = hr_get_hosts_by_options( $hr_options );

    if (! $hr_options->{force} ) {
        say {*STDERR} "info: Skip actual host-delete unless --force is used.";
        return;
    }

    foreach my $i_host_id ( sort { $hr_host_ids->{$a} cmp $hr_host_ids->{$b} } keys %{$hr_host_ids} ){

        my $or_host = $hr_host_ids->{$i_host_id};

        # host object isn't set by loop above. look for object by id.
        if (! $or_host ) {
            if (!
                (
                    $or_host =
                        Tapper::Model::model('TestrunDB')
                            ->resultset('Host')
                            ->find( $i_host_id )
                )
            ) {
                die "Can't find host by id '$i_host_id'\n";
            }
        }

        my $s_name = $or_host->name;
        if (! b_update_grub( $s_name ) ) {
            die "error: Can't update grub by id '$i_host_id'\n";
        }

        require DateTime;
        $or_host->active( 0 );
        $or_host->is_deleted( 1 );
        $or_host->updated_at( DateTime->now->strftime('%F %T') );

        if ( $or_host->update() ) {
            if ( $hr_options->{verbose} ) {
                say "info: Deleted host $s_name: $i_host_id";
            }
        }
        else {
            die "error: Can't update host by id '$i_host_id'\n";
        }

    }

    return;

}


sub print_hosts_verbose
{
        my ($hosts, $verbosity_level) = @_;

        $verbosity_level //= 0;

        # calculate width of columns
        my %max = (
                   name      => length('Name'),
                   features  => length ('Features'),
                   comment   => length('Comment'),
                   bindqueue => length('Bound Queues'),
                   denyqueue => length('Denied Queues'),
                   pool      => length('Pool count (used/all)'),
                  );

        my @a_host = $hosts->isa('DBIx::Class::ResultSet') ? $hosts->all : $hosts;

 HOST:
        foreach my $host ( @a_host ) {
                my $features = host_feature_summary($host);
                $max{name}    = length($host->name) if length($host->name) > $max{name};
                $max{features} = length($features) if length($features) > $max{features};
                $max{comment} = length($host->comment) if length($host->comment) > $max{comment};

                my $tmp_length = length(join ", ", map {$_->queue->name} $host->queuehosts->all);
                $max{bindqueue} = $tmp_length if $tmp_length > $max{bindqueue} ;

                $tmp_length = length(join ", ", map {$_->queue->name} $host->denied_from_queue->all);
                $max{denyqueue} = $tmp_length if $tmp_length > $max{bindqueue} ;
        }

        my ($name_length, $feature_length, $comment_length, $bq_length, $dq_length, $pool_length) =
          ($max{name}, $max{features}, $max{comment}, $max{bindqueue}, $max{denyqueue}, $max{pool});

        # use printf to get the wanted field width
        if ($verbosity_level > 1) {
                printf("%5s | %${name_length}s | %-${feature_length}s | %11s | %10s | %${comment_length}s | %-${bq_length}s | %-${dq_length}s | %-${pool_length}s\n",
                        'ID', 'Name', 'Features', 'Active', 'Testrun ID', 'Comment', 'Bound Queues', 'Denied Queues', 'Pool Count (used/all)');
        } else {
                printf("%5s | %${name_length}s | %-${feature_length}s | %11s | %10s | %${bq_length}s | %${dq_length}s | %-${pool_length}s\n",
                        'ID', 'Name', 'Features', 'Active', 'Testrun ID', 'Bound Queues', 'Denied Queues', 'Pool Count (used/all)');
                $comment_length = 0;
        }
        say "="x(5+$name_length+$feature_length+11+length('Testrun ID')+$comment_length+$bq_length+$dq_length+$pool_length+7*length(' | '));

        require Tapper::Model;
        foreach my $host ( @a_host ) {
                my ($name_length, $feature_length, $queue_length) = ($max{name}, $max{features}, $max{queue});
                my $testrun_id = 'unknown id';
                if (not $host->free) {
                        my $job_rs = Tapper::Model::model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $host->id, status => 'running'});
                        $testrun_id = $job_rs->search({}, {rows => 1})->first->testrun_id if $job_rs->count;
                }
                my $features = host_feature_summary($host);
                my $output = sprintf("%5d | %${name_length}s | %-${feature_length}s | %11s | %10s | ",
                                     $host->id,
                                     $host->name,
                                     $features,
                                     $host->is_deleted ? 'deleted' : ( $host->active ? 'active' : 'deactivated' ),
                                     $host->free   ? 'free'   : "$testrun_id",
                                    );
                  if ($verbosity_level > 1) {
                        $output .= sprintf("%${comment_length}s | ", $host->comment);

                }
                $output .= sprintf("%-${bq_length}s | %-${dq_length}s",
                                   $host->queuehosts->count        ? join(", ", map {$_->queue->name} $host->queuehosts->all) : '',
                                   $host->denied_from_queue->count ? join(", ", map {$_->queue->name} $host->denied_from_queue->all) : ''
                                  );
                $output .= sprintf(" | %-${pool_length}s", $host->is_pool ? ($host->pool_count-$host->pool_free)."/".$host->pool_count : '-');
                say $output;
        }
}





sub select_hosts
{
        my ($opt) = @_;
        my %options= (order_by => 'name');
        my %search;
        $search{active}     = 1 if $opt->{active};
        $search{is_deleted} = [ 0, undef ] unless $opt->{all};
        $search{free}       = 1 if $opt->{free};
        $search{pool_count} = { not => undef } if $opt->{pool};

        # ignore all options if host is requested by name
        %search = (name   => $opt->{name}) if $opt->{name};

        require Tapper::Model;

        if ($opt->{queue}) {
                my @queue_ids       = map {$_->id} Tapper::Model::model('TestrunDB')->resultset('Queue')->search({name => {-in => [ @{$opt->{queue}} ]}});
                $search{queue_id}   = { -in => [ @queue_ids ]};
                $options{join}      = 'queuehosts';
                $options{'+select'} = 'queuehosts.queue_id';
                $options{'+as'}     = 'queue_id';
        }
        my $hosts = Tapper::Model::model('TestrunDB')->resultset('Host')->search(\%search, \%options);
        return $hosts;
}


sub print_hosts_yaml
{
        my ($hosts) = @_;
        while (my $host = $hosts->next ) {
                my %host_data = (name       => $host->name,
                                 comment    => $host->comment,
                                 free       => $host->free,
                                 active     => $host->active,
                                 is_deleted => $host->is_deleted,
                                 host_id    => $host->id,
                                 );
                my $job = $host->testrunschedulings->search({status => 'running'}, {rows => 1})->first; # this should always be only one
                if ($job) {
                        $host_data{running_testrun} = $job->testrun->id;
                        $host_data{running_since}   = $job->testrun->starttime_testrun->iso8601;
                }

                if ($host->queuehosts->count > 0) {
                        my @queues = map {$_->queue->name} $host->queuehosts->all;
                        $host_data{queues} = \@queues;
                }

                my %features;
                foreach my $feature ($host->features->all) {
                        $features{$feature->entry} = $feature->value;
                }
                $host_data{features} = \%features;

                require YAML::XS;
                print YAML::XS::Dump(\%host_data);
        }
        return;
}


sub print_hosts_json
{
        my ($hosts) = @_;
        my @info;
        while (my $host = $hosts->next ) {
                my %host_data = (name       => $host->name,
                                 comment    => $host->comment,
                                 free       => $host->free,
                                 active     => $host->active,
                                 is_deleted => $host->is_deleted,
                                 host_id    => $host->id,
                                 );
                my $job = $host->testrunschedulings->search({status => 'running'}, {rows => 1})->first; # this should always be only one
                if ($job) {
                        $host_data{running_testrun} = $job->testrun->id;
                        $host_data{running_since}   = $job->testrun->starttime_testrun->iso8601;
                }

                if ($host->queuehosts->count > 0) {
                        my @queues = map {$_->queue->name} $host->queuehosts->all;
                        $host_data{queues} = \@queues;
                }

                my %features;
                foreach my $feature ($host->features->all) {
                        $features{$feature->entry} = $feature->value;
                }
                $host_data{features} = \%features;

                push @info, \%host_data;
        }

        require JSON::XS;
        print JSON::XS->new->utf8->encode(\@info);
        print "\n";
        return;
}


sub listhost
{
        my ($c) = @_;
        $c->getopt( 'free', 'name=s@', 'active', 'queue=s@', 'pool', 'all|a', 'verbose|v+', 'yaml', 'json', 'help|?' );
        if ( $c->options->{help} ) {
                say STDERR "$0 host-list [ --verbose|v ] [ --free ] | [ --name=s ] [--pool] [ --active ] [ --queue=s@ ] [ --all|a] [ --yaml ] [ --json ]";
                say STDERR "    --verbose      Increase verbosity level, without show only names, level one shows all but comments, level two shows all including comments";
                say STDERR "    --free         List only free hosts";
                say STDERR "    --name         Find host by name, implies verbose";
                say STDERR "    --active       List only active hosts";
                say STDERR "    --queue        List only hosts bound to this queue";
                say STDERR "    --pool         List only pool hosts, even deleted ones";
                say STDERR "    --all          List all hosts, even deleted ones";
                say STDERR "    --help         Print this help message and exit";
                say STDERR "    --yaml         Print information in YAML format, implies verbose";
                say STDERR "    --json         Print information in JSON format, implies verbose, yaml takes precedence over json";
                return;
        }
        my $hosts = select_hosts($c->options);

        if ($c->options->{yaml}) {
                print_hosts_yaml($hosts);
        } elsif ($c->options->{json}) {
                print_hosts_json($hosts);
        } elsif ($c->options->{verbose}) {
                print_hosts_verbose($hosts, $c->options->{verbose});
        } else {
                foreach my $host ($hosts->all) {
                        say sprintf("%10d | %s", $host->id, $host->name);
                }
        }

        return;
}


sub host_deny
{
        my ($c) = @_;
        $c->getopt( 'host=s@','queue=s@','really' ,'off','help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "At least one queuename has to be provided!" unless @{$c->options->{queue} || []};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 host-deny  --host=s@  --queue=s@ [--off] [--really]";
                say STDERR "    --host         Deny this host for testruns of all given queues";
                say STDERR "    --queue        Deny this queue to put testruns on all given hosts";
                say STDERR "    --off          Remove previously installed denial of host/queue combination";
                say STDERR "    --really       Force denial of host/queue combination even if it does not make sense (e.g. because host is also bound to queue)";
                return;
        }

        require Tapper::Model;

        my @queue_results; my @host_results;
        foreach my $queue_name ( @{$c->options->{queue}}) {
                my $queue_r = Tapper::Model::model('TestrunDB')->resultset('Queue')->search({name => $queue_name}, {rows => 1})->first;
                die "No such queue: '$queue_name'\n" unless $queue_r;
                push @queue_results, $queue_r;
        }
        foreach my $host_name ( @{$c->options->{host}}) {
                my $host_r = Tapper::Model::model('TestrunDB')->resultset('Host')->search({name => $host_name}, {rows => 1})->first;
                die "No such host: '$host_name'\n" unless $host_r;
                push @host_results, $host_r;
        }

        foreach my $queue_r (@queue_results) {
        HOST:
                foreach my $host_r (@host_results) {
                        if ($c->options->{off}) {
                                my $deny_r = Tapper::Model::model('TestrunDB')->resultset('DeniedHost')->search({queue_id => $queue_r->id,
                                                                                                  host_id  => $host_r->id, },
                                                                                                 {rows => 1}
                                                                                                )->first;
                                $deny_r->delete if $deny_r;
                        } else {

                                if ($host_r->queuehosts->search({queue_id => $queue_r->id}, {rows => 1})->first) {
                                        my $msg = 'Host '.$host_r->name.' is bound to from queue '.$queue_r->name;
                                        if ($c->options->{really}) {
                                                say STDERR "SUCCESS: $msg. Will still deny it too, because you requested it.";
                                        } else {
                                                say STDERR "ERROR: $msg. This does not make sense. Will not deny it from the queue. You can override it with --really";
                                                next HOST;
                                        }
                                }
                                # don't deny twice
                                next HOST if $host_r->denied_from_queue->search({queue_id => $queue_r->id}, {rows => 1})->first;
                                Tapper::Model::model('TestrunDB')->resultset('DeniedHost')->new({queue_id => $queue_r->id,
                                                                                  host_id  => $host_r->id,
                                                                                 })->insert;
                        }
                }
        }
        return;
}


sub host_bind
{
        my ($c) = @_;
        $c->getopt( 'host=s@','queue=s@','really' ,'off','help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "At least one queuename has to be provided!" unless @{$c->options->{queue} || []};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 host-bind  --host=s@  --queue=s@ [--off] [--really]";
                say STDERR "    --host         Bind this hosts to all given queues (can be given multiple times)";
                say STDERR "    --queue        Bind all given hosts to this queue (can be given multiple times)";
                say STDERR "    --off          Remove previously installed host/queue bindings";
                say STDERR "    --really       Force binding host/queue combination even if it does not make sense (e.g. because host is also denied from queue)";
                return;
        }

        require Tapper::Model;

        my @queue_results; my @host_results;
        foreach my $queue_name ( @{$c->options->{queue}}) {
                my $queue_r = Tapper::Model::model('TestrunDB')->resultset('Queue')->search({name => $queue_name}, {rows => 1})->first;
                die "No such queue: '$queue_name'\n" unless $queue_r;
                push @queue_results, $queue_r;
        }
        foreach my $host_name ( @{$c->options->{host}}) {
                my $host_r = Tapper::Model::model('TestrunDB')->resultset('Host')->search({name => $host_name}, {rows => 1})->first;
                die "No such host: '$host_name'\n" unless $host_r;
                push @host_results, $host_r;
        }

        foreach my $queue_r (@queue_results) {
                foreach my $host_r (@host_results) {
                        if ($c->options->{off}) {
                                my $bind_r = Tapper::Model::model('TestrunDB')->resultset('QueueHost')->search({queue_id => $queue_r->id,
                                                                                                 host_id  => $host_r->id },
                                                                                                {rows => 1}
                                                                                               )->first;
                                $bind_r->delete if $bind_r;
                        } else {
                                if ($host_r->denied_from_queue->single({queue_id => $queue_r->id})) {
                                        my $msg = 'Host '.$host_r->name.' is denied from from queue '.$queue_r->name;
                                        if ($c->options->{really}) {
                                                say STDERR "SUCCESS: $msg. Will still deny it too, because you requested it.";
                                        } else {
                                                say STDERR "ERROR: $msg. This does not make sense. Will not bind it to the queue. You can override it with --really";
                                                next HOST;
                                        }
                                }
                                # don't bind twice
                                next HOST if $host_r->queuehosts->search({queue_id => $queue_r->id}, {rows => 1})->first;
                                Tapper::Model::model('TestrunDB')->resultset('QueueHost')->new({queue_id => $queue_r->id,
                                                                                  host_id  => $host_r->id,
                                                                                 })->insert;
                        }
                }
        }
        return;
}



sub host_new
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'queue=s@', 'active', 'pool_count=s', 'verbose|v', 'help|?' );
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Host name missing!" unless $c->options->{name};
                say STDERR "$0 host-new  --name=s [ --queue=s@ ] [--pool_count=s] [--verbose|-v] [--help|-?]";
                say STDERR "    --name         Name of the new host)";
                say STDERR "    --queue        Bind host to this queue, can be given multiple times)";
                say STDERR "    --active       Make host active; without it host will be initially deactivated)";
                say STDERR "    --verbose      More verbose output)";
                return;
        }

        require Tapper::Model;

        if ($c->options->{queue}) {
                foreach my $queue (@{$c->options->{queue}}) {
                        my $queue_rs = Tapper::Model::model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                say STDERR "No such queue: $queue";
                                my @queue_names = map {$_->name} Tapper::Model::model('TestrunDB')->resultset('Queue')->all;
                                say STDERR "Existing queues: ",join ", ",@queue_names;
                        }
                }
        }
        my $host = {
                    name       => $c->options->{name},
                    active     => $c->options->{active},
                    free       => 1,
                    pool_free  => $c->options->{pool_count} ? $c->options->{pool_count} : undef, # need to turn 0 into undef, because 0 makes $host->is_pool true
                   };

        my $newhost = Tapper::Model::model('TestrunDB')->resultset('Host')->new($host);
        $newhost->insert();
        die "Can't create new host\n" if not $newhost; # actually, on this place DBIC should have died already

        if ($c->options->{queue}) {
                foreach my $queue (@{$c->options->{queue}}) {
                        my $queue_rs   = Tapper::Model::model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                $newhost->delete();
                                say STDERR qq(Did not find queue "$queue");
                        }
                        my $queue_host = Tapper::Model::model('TestrunDB')->resultset('QueueHost')->new({
                                                                                          host_id  => $newhost->id,
                                                                                          queue_id => $queue_rs->search({}, {rows => 1})->first->id,
                                                                                         });
                        $queue_host->insert();
                }
        }
        return $newhost->id;
}


sub ar_get_host_update_parameters {
    return [
        [ 'id|i=i'              , 'change host with this id; this or selectbyname is required',                             ],
        [ 'selectbyname=s'      , 'change host with this name; this or id is required',                                     ],
        [ 'name|n=s'            , 'update name',                                                                            ],
        [ 'comment|c:s'         , 'Set a new comment for the host',                                                         ],
        [ 'addboundqueue=s@'    , 'Bind host to named queue without deleting other bindings (queue has to exists already)', ],
        [ 'delboundqueue:s@'    , q#delete queue from this host's bindings, empty string means 'all bindings'#,             ],
        [ 'adddeniedqueue=s@'   , 'mark host as denied for a specific queue',                                               ],
        [ 'deldeniedqueue:s@'   , 'remove denied queue for host',                                                           ],
        [ 'active|a=i'          , 'set active flag to this value, possible values 0 (inactive) and 1 (active)',             ],
        [ 'free=i'              , 'set free flag; possible values: 0=not-free, 1=free; setting free=1 fails when a testrun runs there', ],
        [ 'verbose|v'           , 'some more informational output',                                                         ],
        [ 'help|?'              , 'Print this help message and exit.',                                                      ],
    ];
}


sub b_host_update {

    my ( $or_app_rad ) = @_;

    my $ar_parameters = ar_get_host_update_parameters();
    $or_app_rad->getopt( map { $_->[0] } @{$ar_parameters} );
    my $hr_options = $or_app_rad->options;

    if ( $hr_options->{help} ) {
        say {*STDERR} "Usage: $PROGRAM_NAME host-update [options]";
        require Tapper::CLI::Base;
        Tapper::CLI::Base::b_print_help( $ar_parameters );
        return;
    }

    if ( defined $hr_options->{active} && !grep { $hr_options->{active} == $_ } 0,1 ) {
        die "error: parameter '$hr_options->{active}' is not valid for 'active'\n";
    }

    my $or_host;

    require Tapper::Model;
    if ( $hr_options->{id} ) {
        $or_host = Tapper::Model::model('TestrunDB')->resultset('Host')->find( $hr_options->{id} );
    } elsif ( $hr_options->{selectbyname} ) {
        # There should be only one host with the name
        $or_host = Tapper::Model::model('TestrunDB')->resultset('Host')->search({ name => $hr_options->{selectbyname} })->first;
    } else {
        die "error: missing required parameter 'id' or 'selectbyname'\n";
    }

    if ( $or_host ) {

        my $b_update = 0;
        if ( defined $hr_options->{active} && $hr_options->{active} != $or_host->active ) {
            $b_update = 1;
            $or_host->active( $hr_options->{active} );
            if ( $hr_options->{active} == 0 ) {
                b_update_grub( $or_host->name );
            }
        }

        if ( $hr_options->{name} && $hr_options->{name} ne $or_host->name ) {
            $b_update = 1;
            $or_host->name( $hr_options->{name} );
        }
        if ( defined $hr_options->{comment} && $hr_options->{comment} ne $or_host->comment ) {
            $b_update = 1;
            $or_host->comment( $hr_options->{comment} );
        }
        if ( defined $hr_options->{free} ) {
            $b_update = 1;
            if ($hr_options->{free} == 1 and
                not $or_host->free and
                Tapper::Model::model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $or_host->id, status => 'running'})->count)
            {
                die "error: cannot free a used host (id=".$or_host->id.")\n";
            }
            else {
                $or_host->free( $hr_options->{free} );
            }
        }
        for my $s_type (qw/ bound denied /) {
            if ( $hr_options->{"add${s_type}queue"} ) {
                $b_update ||= i_add_queues( $or_host, $s_type, $hr_options->{"add${s_type}queue"} );
            }
            if ( defined $hr_options->{"del${s_type}queue"} ) {
                $b_update ||= i_delete_queues( $or_host, $s_type, $hr_options->{"del${s_type}queue"} );
            }
        }

        if ( $b_update ) {

            require DateTime;
            $or_host->updated_at( DateTime->now->strftime('%F %T') );

            if (! $or_host->update ) {
                die "error: cannot update host\n";
            }

        }
        else {
            say {*STDERR} "info: nothing to update";
        }
        if ( $hr_options->{verbose} ) {
            print_hosts_verbose( $or_host );
        }

    }
    else {
        die "error: no such host = $hr_options->{id}\n";
    }

    return;

}


sub setup
{
        my ($c) = @_;

        $c->register('host-list'            , \&listhost                , 'Show all hosts matching a given condition');
        $c->register('host-deny'            , \&host_deny               , 'Setup or remove forbidden host/queue combinations');
        $c->register('host-bind'            , \&host_bind               , 'Setup or remove host/queue bindings');
        $c->register('host-new'             , \&host_new                , 'Create a new host by name');
        $c->register('host-update'          , \&b_host_update           , 'update host data');
        $c->register('host-delete'          , \&b_delete                , 'Delete a host');

        #TODO: full implementation remaining
        # $c->register('host-free'    , \&b_free_host , 'Free host');

        if ($c->can('group_commands')) {
                $c->group_commands(
                    'Host commands',
                        'host-list',
                        'host-new',
                        'host-update',
                        'host-delete',
                        'host-bind',
                        'host-deny',
                );
        }
        return;
}

1; # End of Tapper::CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::Host

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg} unless otherwise stated.

    use App::Rad;
    use Tapper::CLI::Host;
    Tapper::CLI::Host::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Host - Tapper - host related commands for the tapper CLI

=head1 FUNCTIONS

=head2

Generate a feature summary for a given host. This summary only includes
key_word, socket_type and revision. These are the most important
information and having all features would make a to long list. These
features are concatenated together with commas.

@param host object

@return string - containing features

=head2 i_add_queues

add relations between host and queues

=head2 i_delete_queues

remove relations between host and queues

=head2 b_b_update_grub

Install a default grub config for host so that it does no longer try to
execute Tapper testruns.

@return success - inserted message object
@return error   - die()

=head2 hr_get_hosts_by_options

load host objects for given command line parameters

=head2 ar_get_free_host_parameters

get parameters for free host

=head2 b_free_host

free host

=head2 ar_get_delete_parameters

get "delete host" parameters

=head2 b_delete

remove a host

=head2 print_hosts_verbose

=head2 select_hosts

=head2 print_hosts_yaml

Print given host with all available information in YAML.

@param host object

=head2 print_hosts_json

Print information in JSON format.

=head2 listhost

List hosts matching given criteria.

=head2 host_deny

Don't use given hosts for testruns of this queue.

=head2 host_bind

Bind given hosts to given queues.

=head2 host_new

Create a new host.

=head2 ar_get_host_update

get "update host" parameters

=head2 b_host_update

update host data

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
