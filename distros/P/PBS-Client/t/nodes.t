#!/usr/bin/perl -w
use strict;
use PBS::Client;
use Test::More (tests => 3);

#---------------------------------------
# Test requesting nodes in string format
#---------------------------------------
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        nodes => "node01.abc.com + node03.abc.com",
        ppn   => 2,
        wd    => '.',
        cmd   => 'date',
    );

    $pbs->genScript($job);

    my $diff = &diff($job->{_tempScript}, "t/nodes_1.sh");
    is($diff, 0, "nodes option in string format");
    unlink($job->{_tempScript});
}


#-------------------------------
# Test specifying nodes in array
#-------------------------------
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        nodes => [qw(node01.abc.com node03.abc.com)],
        ppn   => 2,
        wd    => '.',
        cmd   => 'date',
    );
    
    $pbs->genScript($job);

    my $diff = &diff($job->{_tempScript}, "t/nodes_1.sh");
    is($diff, 0, "nodes option in array format");
    unlink($job->{_tempScript});
}


#------------------------------
# Test specifying nodes in hash
#------------------------------
{
    my $pbs = PBS::Client->new;
    my $job = PBS::Client::Job->new(
        nodes => {'node01.abc.com' => 2},
        wd    => '.',
        cmd   => 'date',
    );
    
    $pbs->genScript($job);

    my $diff = &diff($job->{_tempScript}, "t/nodes_2.sh");
    is($diff, 0, "nodes option in hash format");
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
