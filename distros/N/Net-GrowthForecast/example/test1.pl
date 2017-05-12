#!/usr/bin/env perl

use strict;
use warnings;
use English;

use Data::Dumper;

use Net::GrowthForecast;

my $gf = Net::GrowthForecast->new();
my $r;

# total graph number on start
my $startgraphs = scalar(@{$gf->all()});

# value update
$r = $gf->post('example', 'test', 'graph1', 30);

my $g1a = $gf->graph($r->{id});
my $g1b = $gf->post('example', 'test', 'graph1', 0, 'mode' => 'count');
die "if number changed, its wrong...." unless $g1a->{number} == $g1b->{number};

# get graph
$r = $gf->graph('99999'); # maybe not existing graph id...

die "may be undef" if defined $r;
my $glist = $gf->graphs();
die "lists must be not undef" unless $glist and scalar(@$glist) >= 0;

# add graph and edit it
$r = $gf->add_graph('example', 'test', 'graph' . $PID . 'a', 0, '#ff0000');

die "add_graph failed with return value $r" unless $r;
my $g2 = $gf->by_name('example', 'test', 'graph' . $PID . 'a');
die "added graph color must be #ffff00, but $g2->{color}" unless $g2->{color} eq '#ff0000';
die "initial type of graph may be AREA, but $g2->{type}" unless $g2->{type} eq 'AREA';

$g2->{type} = 'LINE2';

$r = $gf->edit($g2);

my $g3 = $gf->graph($g2->{id});
die "type not changed correctly $g3->{type}" unless $g3->{type} eq 'LINE2';
my $glist2 = $gf->graphs();
die "graphs not added 1 anyway, " . scalar(@$glist) . " into " . scalar(@$glist2) unless scalar(@$glist2) == scalar(@$glist) + 1;

# add graph by spec
$r = $gf->add({
    service_name => 'example', section_name => 'test', graph_name => 'graph' . $PID . 'b',
    color => '#00FF00',
    mode => 'derive',
});

die "add failed with return value $r" unless $r;
my $g4 = $gf->by_name('example', 'test', 'graph' . $PID . 'b');
$g4 = $gf->graph($g4->{id});
die "mode should be derive, but $g4->{derive}" unless $g4->{mode} eq 'derive';

# complex
$r = $gf->complex('99999'); # may also be un-exist
die "may be undef" if defined $r;

my $clist = $gf->complexes();
die "lists must be not undef" unless $clist and scalar(@$clist) >= 0;

$r = $gf->add_complex('example', 'test', 'graph' . $PID . 'c', 'testing now', 1, 19, 'LINE1', 'gauge', 1, $g1b->{id}, $g2->{id}, $g4->{id});

die "add_complex failed with return value $r" unless $r;
my $c1 = $gf->by_name('example', 'test', 'graph' . $PID . 'c');
die "c1 is not complex, why?" unless $c1->{complex};
my $c2spec = $gf->complex($c1->{id});
$c2spec->{graph_name} = 'graph' . $PID . 'd';
$c2spec->{data} = [{graph_id => $g2->{id}}, {graph_id => $g4->{id}}];

$r = $gf->add($c2spec);

die "add failed with return value $r" unless $r;
my $c2 = $gf->by_name('example', 'test', 'graph' . $PID . 'd');

$c2->{sort} = 0;

$r = $gf->edit($c2);

$c2 = $gf->complex($c2->{id});
die "sort value not updated correctly" unless $c2->{sort} eq '0';

# delete graphs
($gf->delete($c2) and $gf->delete($c1) and $gf->delete($g4) and $gf->delete($g2) and $gf->delete($g1b))
    or die "failed to delete graphs...";

my $endgraphs = scalar(@{$gf->all()});
die "start graph nums and end graph nums mismatch: $startgraphs -> $endgraphs" unless $startgraphs == $endgraphs;

