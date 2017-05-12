package Pgtools::Config_diff;
use strict;
use warnings;

use Pgtools;
use Pgtools::Conf;
use Pgtools::Connection;
use List::MoreUtils qw(uniq);
use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(argv));

sub exec {
    my $self = shift;
    my $default = {
        "host"     => "localhost",
        "port"     => "5432",
        "user"     => "postgres",
        "password" => "",
        "database" => "postgres"
    };
    my @dbs, my @confs;
    my $db_cnt = scalar(@{$self->argv});

    for(my $i=0; $i<$db_cnt; $i++) {
        my $db = Pgtools::Connection->new($default);
        $db->set_args($self->argv->[$i]);
        $db->create_connection();

        my $c = get_db_config($self, $db);
        my $v = get_db_version($self, $db);
        my $obj = {
            "version" => $v,
            "items"   => $c
        };

        push(@dbs, $db);
        push(@confs, Pgtools::Conf->new($obj));

        $db->dbh->disconnect;
    }

    my $is_different = &check_version(\@confs);
    &warn_difference() if $is_different == 1;;

    my $diff_keys = &get_different_keys(\@confs);
    if(scalar(@$diff_keys) == 0) {
        print "There is no differenct settings.\n" ;
        return;
    }
    &print_difference(\@confs, \@dbs, $diff_keys);
}

sub check_version {
    my $confs = shift @_;
    my $version = @$confs[0]->version;
    for(my $i=1; $i<scalar(@_); $i++) {
        if($version ne @$confs[$i]->version) {
            return 1;
        }
    }
    return 0;
}

sub warn_difference {
    print "************************\n";
    print "  Different Version !!  \n";
    print "************************\n";
}

sub get_different_keys {
    my $confs = shift @_;
    my $db_cnt = scalar(@$confs);
    my $tmp, my $tmp_item;
    my @keys, my @diff_keys;

    for(my $i=0; $i<$db_cnt; $i++) {
        $tmp = @$confs[$i]->items;
        push(@keys, keys(%$tmp));
    }
    @keys = uniq(@keys);
    @keys = sort(@keys);

    for my $key (@keys) {
        for(my $i=0; $i<$db_cnt; $i++) {
            if(!defined @$confs[$i]->items->{$key}){
                @$confs[$i]->items->{$key} = "";
            }
        }

        $tmp_item = @$confs[0]->items->{$key};
        for(my $i=1; $i<$db_cnt; $i++) {
            if($tmp_item ne @$confs[$i]->items->{$key}) {
                push(@diff_keys, $key);
                last;
            }
        }
    }
    return \@diff_keys;
}

sub print_difference {
    my ($confs, $dbs, $diff_keys) = @_;
    my $db_cnt = scalar(@$confs);
    my $key_cnt = scalar(@$diff_keys);
    printf("<Setting Name>           ");
    for(my $j=0; $j<$db_cnt; $j++) {
        printf("%-24s", @$dbs[$j]->host);
    }
    printf("\n--------------------");
    for(my $j=0; $j<$db_cnt; $j++) {
        printf("------------------------");
    }
    printf("\n");
    for(my $i=0; $i<$key_cnt; $i++) {
        my $key = @$diff_keys[$i];
        printf("%-24s ", $key);
        for(my $j=0; $j<$db_cnt; $j++) {
            printf("%-23s ", @$confs[$j]->items->{$key});
        }
        printf("\n");
    }
}

sub get_db_config {
    my ($self, $db) = @_;
    
    my $sth = $db->dbh->prepare("SELECT name, setting FROM pg_settings");
    $sth->execute();

    my $items = {};
    while (my $hash_ref = $sth->fetchrow_hashref) {
        my %row = %$hash_ref;
        $items = {%{$items}, $row{name} => $row{setting}};
    }
    $sth->finish;

    return $items;
}

sub get_db_version {
    my ($self, $db) = @_;
    
    my $sth = $db->dbh->prepare("SELECT version()");
    $sth->execute();

    my $ref = $sth->fetchrow_arrayref;
    my @v = split(/ /, @$ref[0], -1);
    $sth->finish;

    return $v[1];
}


1;

