#!/usr/bin/perl -w
use strict;
use PBS::Client;
use Test::More (tests => 2);

#---------------------------------------
# Test packing matrix of commands (numQ)
#---------------------------------------
{
    my @cmd = (
        ['c00', 'c01'],
        ['c10', 'c11', 'c12'],
        ['c20'],
        ['c30'],
        ['c40', 'c41'],
        ['c50'],
        'c60',
        ['c70'],
        ['c80'],
        ['c90', 'c91', 'c92'],
    );
    
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        queue  => 'queue01',
        nodes  => 2,
        cmd    => \@cmd,
    );
    
    $job->pack(numQ => 3);
    my @res = @{$job->{cmd}};

    my @ans = (
        ['c00', 'c11', 'c30', 'c50', 'c80', 'c92'],
        ['c01', 'c12', 'c40', 'c60', 'c90'],
        ['c10', 'c20', 'c41', 'c70', 'c91'],
    );
    
    my $fail = 0;
    for(my $r = 0; $r < @ans; $r++)
    {
        for(my $c = 0; $c < @{$ans[$r]}; $c++)
        {
            $fail = 1 if ($res[$r][$c] ne $ans[$r][$c]);
        }
    }
    is($fail, 0, "packing array to a specified number of queue");
}


#--------------------------------------
# Test packing matrix of commands (cpq)
#--------------------------------------
{
    my @cmd = (
        ['c00', 'c01'],
        ['c10', 'c11', 'c12'],
        ['c20'],
        ['c30'],
        ['c40', 'c41'],
        ['c50'],
        'c60',
        ['c70'],
        ['c80'],
        ['c90', 'c91', 'c92'],
    );
    
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        queue  => 'queue01',
        nodes  => 2,
        cmd    => \@cmd,
    );
    
    $job->pack(cpq => 3);
    my @res = @{$job->{cmd}};

    my @ans = (
        ['c00', 'c01', 'c10'],
        ['c11', 'c12', 'c20'],
        ['c30', 'c40', 'c41'],
        ['c50', 'c60', 'c70'],
        ['c80', 'c90', 'c91'],
        ['c92'],
    );
    
    my $fail = 0;
    for(my $r = 0; $r < @ans; $r++)
    {
        for(my $c = 0; $c < @{$ans[$r]}; $c++)
        {
            $fail = 1 if ($res[$r][$c] ne $ans[$r][$c]);
        }
    }
    is($fail, 0, "packing array to a specified commands per queue");
}
