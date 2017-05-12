#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools;
use Search::Tools::HiLiter;
use Search::Tools::XML;
use File::Slurp;
use Benchmark qw(:all);

my $buf     = read_file('t/docs/ascii.txt');
my $query   = Search::Tools->parser->parse('thronger');
my $hiliter = Search::Tools::HiLiter->new( query => $query, );
cmpthese(
    1000,
    {   'hilite' => sub {
            my $lit = $hiliter->light($buf);
        },
    }
);
