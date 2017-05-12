#!/usr/bin/env perl

use strict;
use warnings;

use Moose;

with 'Env';
extends 'POSIX';
extends "Fnctrl";
extends qw/Getopt::Long Getopt::Std/;
extends ("Carp", 'Cwd');
+{
    with => 'Find::Bin', # Must be ignore
};
extends "perlIO", "Opcode";

no Moose;
