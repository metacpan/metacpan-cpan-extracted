#!/usr/bin/env perl

use strict;
use warnings;

use parent qw(NativeCall);
use feature 'say';

sub cdio_eject_media_drive :Args(string) :Native(cdio) {}
sub cdio_close_tray :Args(string, int) :Native(cdio) {}

say "Gimme a CD!";
cdio_eject_media_drive undef;

sleep 1;
say "Ha! Too slow!";
cdio_close_tray undef, 0;

sub fmax :Args(double, double) :Native :Returns(double) {}
say "fmax(2.0, 3.0) = " . fmax(2.0, 3.0);
