package Runops::Recorder::Viewer::Exceptions;

use strict;
use warnings;

sub new { bless {}, shift; }

sub on_next_statement {
    my ($self, $line_no) = @_;
    $self->{last_line} = $line_no;
}

sub on_switch_file {
    my ($self, undef, $path) = @_;
    $self->{current_file} = $path;
}

sub on_keyframe_timestamp { $_[0]->{tzsec} = $_[1]; }
sub on_keyframe_timestamp_usec { $_[0]->{tzusec} = $_[1]; }

sub on_die {
    my $self = shift;    
    
    my ($sec, $min, $hour, $day, $month, $year) = localtime($self->{tzsec});
    my $tz = sprintf("%04d-%02d-%02d %02d:%02d:%02d.%6d", 
        $year + 1900, $month + 1, $day, $hour, $min, $sec, $self->{tzusec});
    
    print "$tz: Died at line: $self->{last_line} in $self->{current_file}\n";
}

1;