#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;
use Data::Dumper;

use lib './lib';
use Term::ReadLine::Repl;

my %O = (
    dry => 1,
);

# Used for both regular getopts cli args parse and repl -flags parsing.
sub get_opts_parse {
    GetOptions(\%O,
        'dry|n!',
        'force',
        'mem_buffer=i',
        'timeout=i',
        'verbose!',
    ) or die "cant!";
}

sub custom_logic {
    my $args = shift;

    print Dumper \%O;

    # Testing return
    if ($args->[0] eq 'test') {
        return {
            action => 'next'
        };
    }

    if ($args->[0] eq 'end') {
        return {
            action => 'last'
        };
    }

    if ($args->[0] eq 'fart') {
        return {
            schema => {
                blah => {
                    exec => sub {print "fart\n";},
                    args => [{
                        refresh => undef,
                    }] 
                } 
            } 
        };
    }
}

sub get_stats {
    my $arg = shift;

    if ($arg eq 'a') {
        print "a\n";
        return;
    }
    print "1,2,3,4,5\n";
}

#my $term = Term::ReadLine::Repl->new(
#    {
#        name => 'myrepl',
#        prompt => '(%s)>',
#        cmd_schema => {
#            stats => {
#                exec => \&get_stats,
#                args => [{
#                    refresh => undef,
#                    host => 'hostname',
#                    guest => 'guestname',
#                    list => 'host|guest',
#                    cluster => undef,
#                }, 
#                { 
#                    test => undef,
#                    another => undef,
#                }],
#            },
#            xml => {
#                exec => \&list_items,
#                args => [{refresh=>undef, 'cluster|host'=>undef, 'hostname'=>undef}],
#            }
#        },
#        passthrough => 1,
#        get_opts => \&get_opts_parse,
#        custom_logic => \&custom_logic,
#    }
#);

# A simple repl
my $term = Term::ReadLine::Repl->new(
    {
        name => 'myrepl',
        cmd_schema => {
            ls => { 
                exec => sub {my @list = qw(a b c); print for @list},  # Coderef to custom function for cmd
            }
        }
    }
);   

## A simple repl
#my $term = Term::ReadLine::Repl->new(
#    {
#        name => 'myrepl',
#        cmd_schema => {
#            ls => { 
#                exec => sub {my @list = qw(a b c); print for @list},  # Coderef to custom function for cmd
#            }
#        }
#    }
#);   

#print Dumper $term;

$term->run();


