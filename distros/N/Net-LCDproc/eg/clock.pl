#!/usr/bin/env perl

use v5.10.2;

use strict;
use warnings;

use DateTime;
use Log::Any::Adapter;
use Log::Dispatch;

use Net::LCDproc;

my $lcdproc;
my $screen1;
my $screen2;
my $widget = {};

my $loglevel = 'info';

if (defined $ARGV[0]) {
    $loglevel = $ARGV[0];
}

sub start_logging {

    my $log = Log::Dispatch->new(
        outputs => [[
                'Screen',
                min_level => $loglevel,
                newline   => 1,
            ],
        ]);
    Log::Any::Adapter->set('Dispatch', dispatcher => $log);

    return $log;
}

sub add_screen {
    my ($id, $title_str) = @_;

    my $screen = Net::LCDproc::Screen->new(id => $id);

    if (defined $title_str) {
        my $title = Net::LCDproc::Widget::Title->new(
            id   => $id . "_title",
            text => $title_str
        );
        $screen->add_widget($title);
    }

    $lcdproc->add_screen($screen);
    $screen->set('name',      'clock');
    $screen->set('heartbeat', 'off');

    return $screen;
}

sub get_date_time {
    my $dt = DateTime->now;
    my $date_str = sprintf "%s %d %s %d", $dt->day_abbr, $dt->day,
      $dt->month_abbr, $dt->year;
    return ($dt->hms, $date_str);
}

sub add_time_date_widgets {

    my ($time_str, $date_str) = get_date_time;

    $widget->{time} = Net::LCDproc::Widget::String->new(
        id   => 'time',
        x    => 1,
        y    => 2,
        text => $time_str,
    );

    $screen1->add_widget($widget->{time});

    $widget->{date} = Net::LCDproc::Widget::String->new(
        id   => 'date',
        x    => 1,
        y    => 3,
        text => $date_str,
    );

    $screen1->add_widget($widget->{date});
}

sub add_clock_widget {
    my ($int, $x) = @_;

    my $w = Net::LCDproc::Widget::Num->new(
        id  => "clock_$x",
        x   => $x,
        int => $int,
    );
    $widget->{clock}->{$x} = $w;
    $screen2->add_widget($w);
}

sub get_hms {
    my $dt = DateTime->now;
    my $h  = $dt->strftime('%H');
    my $m  = $dt->strftime('%M');
    my $s  = $dt->strftime('%S');

    return ($h, $m, $s);
}

sub add_clock_widgets {
    my ($hour, $min, $sec) = get_hms;

    # add the separators
    add_clock_widget(10, 7);
    add_clock_widget(10, 14);
    my $char = 0;

    $char = substr $hour, 0, 1;
    add_clock_widget($char, 1);
    $char = substr $hour, 1, 1;
    add_clock_widget($char, 4);

    $char = substr $min, 0, 1;
    add_clock_widget($char, 8);
    $char = substr $min, 1, 1;
    add_clock_widget($char, 11);

    $char = substr $sec, 0, 1;
    add_clock_widget($char, 15);
    $char = substr $sec, 1, 1;
    add_clock_widget($char, 18);

}

sub update_clock_widgets {

    my ($hour, $min, $sec) = get_hms;

    my $char = substr $hour, 0, 1;
    $widget->{clock}->{1}->int($char);

    $char = substr $hour, 1, 1;
    $widget->{clock}->{4}->int($char);

    $char = substr $min, 0, 1;
    $widget->{clock}->{8}->int($char);
    $char = substr $min, 1, 1;
    $widget->{clock}->{11}->int($char);

    $char = substr $sec, 0, 1;
    $widget->{clock}->{15}->int($char);
    $char = substr $sec, 1, 1;
    $widget->{clock}->{18}->int($char);

}

sub update_widgets {
    my ($time_str, $date_str) = get_date_time;

    $widget->{time}->text($time_str);

    # if day hasn't changed, don't update
    if ($widget->{date}->text ne $date_str) {
        $widget->{date}->text($date_str);
    }

    update_clock_widgets;
}

start_logging;
$lcdproc = Net::LCDproc->new;
$screen1 = add_screen('screen1', 'Time & Date');
$screen2 = add_screen('screen2');

add_time_date_widgets;
add_clock_widgets;

while (1) {
    update_widgets;
    $lcdproc->update;
    sleep(1);
}
