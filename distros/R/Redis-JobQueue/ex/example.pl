#!/usr/bin/perl -w

# NAME: JobQueue client demonstration

#-- Common ---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Redis::JobQueue qw(
    DEFAULT_SERVER
    DEFAULT_PORT

    E_NO_ERROR
    E_MISMATCH_ARG
    E_DATA_TOO_LARGE
    E_NETWORK
    E_MAX_MEMORY_LIMIT
    E_JOB_DELETED
    E_REDIS
    );
use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    );

my $server = DEFAULT_SERVER.":".DEFAULT_PORT;   # the Redis Server

sub exception {
    my $jq  = shift;
    my $err = shift;

    if ( $jq->last_errorcode == E_NO_ERROR )
    {
        # For example, to ignore
        return unless $err;
    }
    elsif ( $jq->last_errorcode == E_MISMATCH_ARG )
    {
        # Necessary to correct the code
    }
    elsif ( $jq->last_errorcode == E_DATA_TOO_LARGE )
    {
        # You must use the control data length
    }
    elsif ( $jq->last_errorcode == E_NETWORK )
    {
        # For example, sleep
        #sleep 60;
        # and return code to repeat the operation
        #return "to repeat";
    }
    elsif ( $jq->last_errorcode == E_MAX_MEMORY_LIMIT )
    {
        # For example, return code to restart the server
        #return "to restart the redis server";
    }
    elsif ( $jq->last_errorcode == E_JOB_DELETED )
    {
        # For example, return code to ignore
        my $id = $err =~ /^(\S+)/;
        #return "to ignore $id";
    }
    elsif ( $jq->last_errorcode == E_REDIS )
    {
        # Independently analyze the $jq->last_error
    }
    else
    {
        # Unknown error code
    }
    die $err if $err;
}

my $jq;

eval {
    $jq = Redis::JobQueue->new(
        redis   => $server,
        timeout => 1,   # DEFAULT_TIMEOUT = 0 for an unlimited timeout
        );
};
exception( $jq, $@ ) if $@;

#-- Producer -------------------------------------------------------------------

#-- Adding new job

my $job;
eval {
    $job = $jq->add_job(
        {
            queue       => 'xxx',
            job         => 'Some comment',
            workload    => \'Some stuff up to 512MB long',
            expire      => 12*60*60,
        } );
};
exception( $jq, $@ ) if $@;
print "Added job ", $job->id, "\n" if $job;

eval {
    $job = $jq->add_job(
        {
            queue       => 'yyy',
            job         => 'Some comment',
            workload    => \'Some stuff up to 512MB long',
            expire      => 12*60*60,
        } );
};
exception( $jq, $@ ) if $@;
print "Added job ", $job->id, "\n" if $job;

#-- Worker ---------------------------------------------------------------------

#-- Run your jobs

sub xxx {
    my $job = shift;

    my $workload = ${$job->workload};
    # do something with workload;
    print "XXX workload: $workload\n";

    $job->result( 'XXX JOB result comes here, up to 512MB long' );
}

sub yyy {
    my $job = shift;

    my $workload = ${$job->workload};
    # do something with workload;
    print "YYY workload: $workload\n";

    $job->result( \'YYY JOB result comes here, up to 512MB long' );
}

eval {
    while ( my $job = $jq->get_next_job(
        queue       => [ 'xxx','yyy' ],
        blocking    => 1
        ) )
    {
        my $id = $job->id;

        my $status = $jq->get_job_data( $id, 'status' );
        print "Job '", $id, "' was '$status' status\n";

        $job->status( STATUS_WORKING );
        $jq->update_job( $job );

        $status = $jq->get_job_data( $id, 'status' );
        print "Job '", $id, "' has new '$status' status\n";

        # do my stuff
        if ( $job->queue eq 'xxx' )
        {
            xxx( $job );
        }
        elsif ( $job->queue eq 'yyy' )
        {
            yyy( $job );
        }

        $job->status( STATUS_COMPLETED );
        $jq->update_job( $job );

        $status = $jq->get_job_data( $id, 'status' );
        print "Job '", $id, "' has last '$status' status\n";
    }
};
exception( $jq, $@ ) if $@;

#-- Consumer -------------------------------------------------------------------

#-- Check the job status

eval {
    # For example:
    # my $status = $jq->get_job_data( $ARGV[0], 'status' );
    # or:
    my @ids = $jq->get_job_ids;

    foreach my $id ( @ids )
    {
        my $status = $jq->get_job_data( $id, 'status' );
        print "Job '$id' has '$status' status\n";
    }
};
exception( $jq, $@ ) if $@;

#-- Fetching the result

eval {
    # For example:
    # my $id = $ARGV[0];
    # or:
    my @ids = $jq->get_job_ids;

    foreach my $id ( @ids )
    {
        my $status = $jq->get_job_data( $id, 'status' );
        print "Job '$id' has '$status' status\n";

        if ( $status eq STATUS_COMPLETED )
        {
            my $job = $jq->load_job( $id );

            # it is now safe to remove it from JobQueue, since it is completed
            $jq->delete_job( $id );

            print "Job result: ", ${$job->result}, "\n";
        }
        else
        {
            print "Job is not complete, has current '$status' status\n";
        }
    }
};
exception( $jq, $@ ) if $@;

#-- Closes and cleans up -------------------------------------------------------

eval { $jq->quit };
exception( $jq, $@ ) if $@;

exit;

__END__
