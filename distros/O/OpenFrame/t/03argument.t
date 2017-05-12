#!/usr/bin/perl

use strict;
use OpenFrame::Argument::Blob;

use Test::Simple tests => 3;

my $blob = OpenFrame::Argument::Blob->new();
ok( $blob->filename("ten"), "setting filename");
ok( $blob->filename() eq 'ten', "getting filename");
ok( $blob->filehandle->isa('IO::Handle'), "getting/setting handle");


