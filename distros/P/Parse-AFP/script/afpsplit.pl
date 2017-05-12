#!/usr/bin/perl

use strict;
use Encode;
use Parse::AFP;
use File::Path 'rmtree';

die "Usage: $0 input.afp dir\n" unless @ARGV >= 1;

my $input = shift;
my $output = shift || 'dir';

rmtree([ $output ]) if -d $output;

mkdir $output;
my $afp = Parse::AFP->new($input, { lazy => 1 });
$afp->callback_members([qw( BR ER * )]);

sub Parse::AFP::BR::ENCODING () { 'cp500' };

sub BR {
    my $name = substr($_[0]->Data, 0, 8);
    print "Writing to $output/$name.afp\n";
    $afp->set_output_file("$output/$name.afp");
    $_[0]->remove;
}

sub ER { $_[0]->remove }

sub __ {
    $_[0]->write; $_[0]->remove;
}
