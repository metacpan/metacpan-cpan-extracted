package t::Util;
use strict;
use warnings;
use utf8;
use Test::More;
use Net::Google::Spreadsheets;

sub PIT_KEY { 'google.com' }

our $SPREADSHEET_TITLE;
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

    check_env(qw(
        SPREADSHEETS_TITLE
    )) or exit;
    {
        no warnings;
        check_use(qw(Config::Pit)) or exit;
    }
    check_config(PIT_KEY) or exit;
    $SPREADSHEET_TITLE = $ENV{SPREADSHEETS_TITLE};
    check_spreadsheet_exists({title => $SPREADSHEET_TITLE}) or exit;
    {
        no strict 'refs';
        for (qw(config service spreadsheet)) {
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

sub check_spreadsheet_exists {
    my ($args) = @_;
    $args->{title} or return 1;
    my $service = &service or die;
    my $sheet = $service->spreadsheet({title => $args->{title}});
    unless ($sheet) {
        plan skip_all => "spreadsheet named '$args->{title}' doesn't exist";
        return;
    }
    return $sheet;
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
    my $s = Net::Google::Spreadsheets->new(
        {
            username => $c->{username},
            password => $c->{password},
        }
    ) or return;
    $service = $s;
    return $service;
}

sub spreadsheet {
    my $title = shift || $SPREADSHEET_TITLE;
    return service->spreadsheet({title => $title});
}

1;
