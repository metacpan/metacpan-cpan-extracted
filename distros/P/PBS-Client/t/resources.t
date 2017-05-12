#!/usr/bin/perl -w
use strict;
use PBS::Client;
use Test::More (tests => 4);

#-----------------------
# Test resources options
#-----------------------
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        partition => 'cluster01',
        queue     => 'queue01',
        nodes     => 2,
        ppn       => 1,
        cput      => '01:30:00',
        pcput     => '00:10:00',
        wallt     => '00:30:00',
        mem       => '600mb',
        pmem      => '200mb',
        vmem      => '1gb',
        pvmem     => '100mb',
        pri       => 10,
        nice      => 5,
        wd        => '.',
        cmd       => 'pwd',
    );
    
    $pbs->genScript($job);
    
    my $diff = &diff($job->{_tempScript}, "t/resources_1.sh");
    is($diff, 0, "resources options");
    unlink($job->{_tempScript});
}


#----------------------
# Test host
#----------------------
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        host => "node01.abc.com",
        wd   => '.',
        cmd  => 'pwd',
    );
    
    $pbs->genScript($job);
    
    my $diff = &diff($job->{_tempScript}, "t/resources_2.sh");
    is($diff, 0, "host");
    unlink($job->{_tempScript});
}


#----------------------
# Tests for begint
#----------------------
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        begint => "1145",
        wd     => '.',
        cmd    => 'pwd',
    );
    
    $pbs->genScript($job);
    
    my $diff = &diff($job->{_tempScript}, "t/resources_3.sh");
    is($diff, 0, "begint");
    unlink($job->{_tempScript});
}
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        begint => "14:48:33",
        wd     => '.',
        cmd    => 'pwd',
    );
    
    $pbs->genScript($job);
    
    my $diff = &diff($job->{_tempScript}, "t/resources_4.sh");
    is($diff, 0, "begint");
    unlink($job->{_tempScript});
}


#---------------------------------------------
# Compare two files
# - return 0 if two files are exactly the same
# - return 1 otherwise
#---------------------------------------------
sub diff
{
    my ($f1, $f2) = @_;
    open(F1, $f1);
    open(F2, $f2);
    my @c1 = <F1>;
    my @c2 = <F2>;
    close(F1);
    close(F2);
    return(0) if (join("", @c1) eq join("", @c2));
    return(1);
}
