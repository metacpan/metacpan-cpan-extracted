package Pgtools::Kill;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use DBI;

use Pgtools;
use Pgtools::Connection;
use Pgtools::Query;
use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(help ignore_match_query ignore_match_state kill match_query match_state print run_time version));

our ($now, $qt) ;
our $qt_format = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S.%N'
);
our $start_time = DateTime->now( time_zone => 'Asia/Tokyo' );

sub exec {
    my ($self, $arg) = @_;
    my $default = {
        "host"     => "localhost",
        "port"     => "5432",
        "user"     => "postgres",
        "password" => "",
        "database" => "postgres"
    };

    my $db = Pgtools::Connection->new($default);
    $db->set_args($arg);
    $db->create_connection();

    # return hash reference
    my $queries = &search_queries($self, $db);

    if($self->print and !$self->kill) {
        &print_query($queries);
    }
    if($self->kill){
        &kill_queries($db, $self, $queries);
        print "Killed matched queries!\n";
    }

    $db->dbh->disconnect;
}

sub kill_queries {
    my ($db, $self, $queries) = @_;
    my ($sth, $now);

    foreach my $pid (keys(%$queries)) {
        $sth = $db->dbh->prepare("SELECT pg_terminate_backend(".$pid.");");
        $now = DateTime->now( time_zone => 'local' );
        $sth->execute();
        if($self->print) {
            print "-------------------------------\n";
            print "Killed-pid: ".$pid."\n";
            print "At        : ".$now->strftime('%Y/%m/%d %H:%M:%S')."\n";
            print "Query     : ".$queries->{$pid}->{query}."\n";
        }
    }
}

sub search_queries {
    my ($self, $db) = @_;
    my @pids;
    my $queries = {};

    my $sth = $db->dbh->prepare("
        SELECT
            datname,
            pid,
            query_start,
            state,
            query
        FROM
            pg_stat_activity
        WHERE
            pid <> pg_backend_pid()
    ");
    $sth->execute();

    while (my $hash_ref = $sth->fetchrow_hashref) {
        my %row = %$hash_ref;
        if($db->database ne $row{datname}) {
            next;
        }
        if($self->match_state ne '' and $row{state} ne $self->match_state) { 
            next;
        }
        if($self->match_query ne '' and $row{query} !~ /$self->{match_query}/im ) {
            next;
        }
        if($self->ignore_match_state ne '' and $row{state} eq $self->ignore_match_state) { 
            next;
        }
        if($self->ignore_match_query ne '' and $row{query} =~ /$self->{ignore_match_query}/im ) {
            next;
        }
        if($self->run_time != 0) {
            $qt = $qt_format->parse_datetime($row{query_start});
            $qt->set_time_zone('local');
            my $diff = $start_time->epoch() - $qt->epoch();
            if($diff < $self->run_time) {
                next;
            }
        }

        my $tmp = {
            "datname"         => $row{datname},
            "pid"             => $row{pid},
            "query_start"   => $row{query_start},
            "state"           => $row{state},
            "query"           => $row{query}
        };
        my $q = Pgtools::Query->new($tmp);
        $queries = {%{$queries}, $row{pid} => $q};
    }
    $sth->finish;

    return $queries;
}

sub print_query {
    my $queries = shift @_;
    foreach my $q (keys(%$queries)) {
        print "-------------------------------\n";
        print "pid       : ".$queries->{$q}->{pid}."\n";
        print "start_time: ".$queries->{$q}->{query_start}."\n";
        print "state     : ".$queries->{$q}->{state}."\n";
        print "query     : ".$queries->{$q}->{query}."\n";
    }
}

1;
