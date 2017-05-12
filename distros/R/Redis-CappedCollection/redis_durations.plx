#!/usr/bin/perl
use 5.010;
use warnings;
use strict;

use Date::Parse;

my $MIN_DISPLAYED_DURATION = 0.1; # sec (100 ms)

my ( $tm_start, $tm_finish, $prev_script, $operation, $start_line, @previous_lines );
while ( <> ) {
    my $line = $_;
    chomp $line;

    if ( $line =~ / lua-script (start|finish): (\S+)/ ) {
        my $first_val   = $1;
        my $second_val  = $2;

        ++$operation;
        my $tm = get_time( $line );
        if ( $first_val eq 'start' ) {
            $tm_start = $tm;
            $prev_script = $second_val;
            $start_line = $line;
        } elsif ( defined( $tm_start ) && $second_val eq $prev_script && $first_val eq 'finish' ) {
            $tm_finish = $tm;
            my $duration = $tm_finish - $tm_start;
            if ( $duration >= $MIN_DISPLAYED_DURATION ) {
                say sprintf( "operation = %d, '%s' duration: %.3f",
                    $operation,
                    $second_val,
                    $duration,
                );
                unshift @previous_lines, $start_line;
                push @previous_lines, $line;
                say "\t$_" foreach @previous_lines;
            }
            undef $tm_start;
            undef $prev_script;
        } else {
            warn sprintf( "not synchronized line: tm_start = %s, prev_script = '%s'",
                $tm_start // '<undef>',
                $prev_script // '<undef>',
            );
            push @previous_lines, $line;
            say "\t$_" foreach @previous_lines;
        }

        @previous_lines = ();
        next;
    }

    push @previous_lines, $line;
}

sub get_time {
    my ( $line ) = @_;

    my ( $tm_str, $tm_ms ) = $line =~ / (\d\d \S\S\S \d\d:\d\d:\d\d)\.(\d\d\d) /;
    return str2time( $tm_str ) + $tm_ms / 1_000;
}