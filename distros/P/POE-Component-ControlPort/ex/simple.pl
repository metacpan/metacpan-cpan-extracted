#!/usr/bin/perl

use warnings;
use strict;

use POE;
use POE::Component::ControlPort;


my @commands = (

    {
        name => 'rot13',
        help_text => "rot13's text. sure, its lame.",
        usage => 'rot13 [ some text ]',
        topic => 'silly',
        command => sub {
            my %input = @_;
            my $str;
            foreach my $bit (@{ $input{args} }) {
                $bit =~ y/A-Za-z/N-ZA-Mn-za-m/;
                $str .= $bit;
            }
            return $str;
        },
    },
    {
        name => '+',
        help_text => 'add numbers',
        usage => '+ [ numbers ]',
        topic => 'math',
        command => sub {
            my %input = @_;
            my $total = 0;
            foreach my $num (@{ $input{args} }) {
                $total += $num;
            }
            return $total;
        },
    },
    {
        name => '-',
        help_text => 'subtract numbers',
        usage => '- [ numbers ]',
        topic => 'math',
        command => sub {
            my %input = @_;
            my $total = 0;
            foreach my $num (@{ $input{args} }) {
                if($total != 0) {
                    $total -= $num;
                } else {
                    $total = $num;
                }
            }
            return $total;
        },
    }

);


POE::Component::ControlPort->create(
    local_address => '127.0.0.1',
    local_port => '31337',

    commands => \@commands,
    
);

POE::Kernel->run();

