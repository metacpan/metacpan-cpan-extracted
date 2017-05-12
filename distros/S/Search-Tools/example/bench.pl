#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Benchmark qw(:all);
use File::Slurp;

my $greek     = to_utf8( read_file('t/docs/greek_and_ojibwe.txt') );
my $ascii     = to_utf8( read_file('t/docs/ascii.txt') );
my $tokenizer = Search::Tools::Tokenizer->new();

cmpthese(
    10000,
    {   'pure-perl-greek' => sub {
            my $tokens = $tokenizer->tokenize_pp( $greek, \&heat_seeker );
        },
        'xs-greek' => sub {
            my $tokens = $tokenizer->tokenize( $greek, \&heat_seeker );
        },
        'pure-perl-ascii' => sub {
            my $tokens = $tokenizer->tokenize_pp( $ascii, \&heat_seeker );
        },
        'xs-ascii' => sub {
            my $tokens = $tokenizer->tokenize( $ascii, \&heat_seeker );
        },
        'xs-ascii-heatseeker-qr' => sub {
            my $tokens = $tokenizer->tokenize( $ascii, qr/\w/ );
        },
    }
);

sub heat_seeker {

    # trivial case to measure sub call overhead vs qr//
    $_[0]->set_hot( $_[0] =~ m/\w/ );
}

