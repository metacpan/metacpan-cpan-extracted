#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 3 }
BEGIN { require "t/test_utils.pl"; }

use IO::File;
use SystemC::Parser;
ok(1);
mkdir 'test_dir', 0777;

######################################################################
package Trialparser;
use vars qw(@ISA);
@ISA = qw(SystemC::Parser);

sub _common {
    my $comment = shift;
    my $self = shift;
    print $::Fdump "Parser.pm::$comment: ",$self->filename,":",$self->lineno
	,": '",join("','", @_),"'\n";
}

sub text {
    my $self = shift;
    my $txt = $_[0];
    # Edit text to make file smaller
    $txt=~ s/\s+/ /g;
    $txt=~ s/^(....................).*(....................)$/$1 ... $2/m;
    _common('TEXT',$self,$txt);
    $self->writetext($_[0], 0);
}

sub include {
    my $self = shift;
    my $auto = shift;
    if ($auto =~ /AUTOINCLUDE/) {
	$self->read_include(filename=>"t/20_parser.spinc");
    }
}

sub auto {	_common ('AUTO',@_); include(@_);}
sub module {	_common ('MODULE',@_); }
sub ctor {	_common ('CTOR',@_); }
sub cell {	_common ('CELL',@_); }
sub class {	_common ('CLASS',@_); }
sub pin {	_common ('PIN',@_); }
sub signal {	_common ('SIGNAL',@_); }
sub preproc_sp {_common ('PREPROC_SP',@_); }
sub enum_value {_common ('ENUM_VALUE',@_); }

sub writetext {
    my $self = shift;
    my $text = shift;
    my $add_lines = shift;

    my $fn = $self->filename;
    my $ln = $self->lineno();
    if ($self->{lastline} != $ln && $add_lines) {
	if ($self->{lastfile} ne $fn) {
	    print $::Fh "#line $ln \"$fn\"\n";
	} else {
	    print $::Fh "#line $ln\n";
	}
	$self->{lastfile} = $fn;
	$self->{lastline} = $ln;
    }
    print $::Fh $text;
    while ($text =~ /\n/g) {
	$self->{lastline}++;
    }
}

sub writesyms {
    my $self = shift;
    my $fh = shift;

    my $syms = $self->symbols;
    foreach my $sym (sort (keys %{$syms})) {
	printf $fh "%s => %d\n", $sym, $syms->{$sym};
    }
}

package main;
######################################################################

{
    # We'll write out all text, to make sure nothing gets dropped
    $::Fh = IO::File->new (">test_dir/20_parser.out");
    $::Fdump = IO::File->new (">test_dir/20_parser.parse");
    $::Fsyms = IO::File->new (">test_dir/20_parser.syms");
    my $sp = Trialparser->new();
    $sp->{lastfile} = "t/20_parser.sp";
    $sp->{lastline} = 1;
    $sp->read (filename=>"t/20_parser.sp");
    $sp->writesyms ($::Fsyms);
    $::Fh->close();
    $::Fdump->close();
    $::Fsyms->close();
}
ok(1);

{
    # Ok, let's make sure the right data went through
    my $f1 = wholefile_filter ("t/20_parser.sp") or die;
    my $f2 = wholefile_filter ("test_dir/20_parser.out") or die;
    $f1 =~ s/(\/\*)?AUTOINCLUDE(;|\*\/)/${1}AUTOINCLUDE${2}\/\*AUTO_FROM_INCLUDE\*\/\n/g;
    my @l1 = split ("\n", $f1);
    my @l2 = split ("\n", $f2);
    for (my $l=0; $l<($#l1 | $#l2); $l++) {
	($l1[$l] eq $l2[$l]) or die "not ok 3: Line $l mismatches\n$l1[$l]\n$l2[$l]\n";
    }
}
ok(1);

sub wholefile_filter {
    my $file = shift;
    my $wholefile = wholefile($file);

    $wholefile =~ s/[ \t]*#sp[^\n]*\n//mg;
    $wholefile =~ s/[ \t]*#line[^\n]*\n//mg;
    $wholefile =~ s![ \t]*// Beginning of SystemPerl[^*]*// End of SystemPerl[^\n]+\n!!mg;

    return $wholefile;
}
