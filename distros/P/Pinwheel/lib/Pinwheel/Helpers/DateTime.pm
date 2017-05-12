package Pinwheel::Helpers::DateTime;

use strict;
use warnings;

use Exporter;

use Pinwheel::Context;
use Pinwheel::Model::Time;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(now hh_mm format_time);


sub now
{
    return Pinwheel::Model::Time::now();
}

# TOOD: this is available as a method in the Time Model
sub hh_mm
{
    my ($time) = @_;
    return sprintf('%02d:%02d', $time->hour, $time->min);
}

sub format_time
{
    return $_[1]->strftime($_[0]);
}



1;
