#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Gtk3 '-init';
use RogersMine;

RogersMine::main;
Gtk3::main;
