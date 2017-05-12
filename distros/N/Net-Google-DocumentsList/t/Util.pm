package t::Util;
use strict;
use warnings;
use utf8;
use Test::More;
use Net::Google::DocumentsList;

sub PIT_KEY { 'google.com' }

my (
    $config,
    $service,
);

BEGIN {
    my $builder = Test::More->builder;
    binmode($builder->output, ':utf8');
    binmode($builder->failure_output, ':utf8');
    binmode($builder->todo_output, ':utf8');
}

sub import {
    my ($class, %args) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;
    utf8->import;
    check_env('NET_GOOGLE_DOCUMENTSLIST_LIVE_TEST') or exit;
    {
        no warnings;
        check_use(qw(Config::Pit)) or exit;
    }
    check_config(PIT_KEY) or exit;
    {
        no strict 'refs';
        for (qw(config service)) {
            *{"$caller\::$_"} = \&{$_};
        }
    }
}

sub check_env {
    my (@env) = @_;
    for (@env) {
        unless ($ENV{$_}) {
            plan skip_all => "set $_ to run this test";
            return;
        }
    }
    return 1;
}

sub check_use {
    my (@module) = @_;
    for (@module) {
        eval "use $_";
        if ($@) {
            plan skip_all => "this test needs $_";
            return;
        }
    }
    1;
}

sub check_config {
    my $key = shift;
    my $config = &config($key);
    unless ($config) {
        plan skip_all 
            => "set username and password for $key via 'ppit set $key'";
        return;
    }
    return $config;
}

sub config {
    my $key = shift;
    return $config if $config;
    my $c = Config::Pit::get($key);
    unless ($c->{username} && $c->{password}) {
        return;
    }
    $config = $c;
    return $config;
}

sub service {
    return $service if $service;
    my $c = &config or return;
    my $s = Net::Google::DocumentsList->new(
        {
            username => $c->{username},
            password => $c->{password},
        }
    ) or return;
    $service = $s;
    return $service;
}

1;
