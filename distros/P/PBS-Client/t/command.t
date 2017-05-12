#!/usr/bin/perl -w
use strict;
use PBS::Client;
use Test::More (tests => 2);

#-----------------------------
# Test vars
#-----------------------------

# String representation
{
    my $pbs = PBS::Client->new();
    my $job = PBS::Client::Job->new(
        vars => "A, B=b, C, D=d",
        wd   => '.',
        cmd  => 'pwd',
    );
    $pbs->genScript($job);
    
    my $diff = &diff($job->{_tempScript}, "t/command.sh");
    is($diff, 0, "environment variable setting");
    unlink($job->{_tempScript});
}


# Array representation
{
    my $pbs = PBS::Client->new();
    my $job = PBS::Client::Job->new(
        vars => [qw(A B=b C D=d)],
        wd   => '.',
        cmd  => 'pwd',
    );
    $pbs->genScript($job);
    
    my $diff = &diff($job->{_tempScript}, "t/command.sh");
    is($diff, 0, "environment variable setting");
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
