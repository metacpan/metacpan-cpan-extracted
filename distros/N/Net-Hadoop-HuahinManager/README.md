# NAME

Net::Hadoop::HuahinManager - Client library for Huahin Manager.

# SYNOPSIS

    use Net::Hadoop::HuahinManager;
    my $client = Net::Hadoop::HuahinManager->new(server => 'manager.local');

    my $all_jobs = $client->list();

    my $failed_jobs = $client->list('failed');

    my $status = $client->status($jobid);
    my $detail = $client->detail($jobid);

    $client->kill($jobid)
      or die "failed to kill jobid: $jobid";

# DESCRIPTION

This module is for systems with Huahin Manager, REST API proxy tool for Hadoop JobTracker.

About Huahin Manager: http://huahin.github.com/huahin-manager/

At just now, Net::Hadoop::HuahinManager supports only list/status/kill (not register).

# METHODS

Net::Hadoop::HuahinManager class method and instance methods.

## CLASS METHODS

### `Net::Hadoop::HuahinManager->new( %args ) :Net::Hadoop::HuahinManager`

Creates and returns a new client instance with _%args_, might be:

- server :Str = "manager.local"
- port :Int = 9010 (default)
- useragent :Str
- timeout :Int = 10

## INSTANCE METHODS

### `$client->list( [ $op ] ) :ArrayRef`

Get list of jobs and returns these as arrayref.

- op :String (optional, one of 'all' (default), 'failed', 'killed', 'prep', 'running' and 'succeeded')

### `$client->status( $jobid ) :HashRef`

Gets job status specified by _$jobid_ string, and returns it.

### `$client->detail( $jobid ) :HashRef`

Gets job detail status specified by _$jobid_ string, and returns it.

### `$client->kill( $jobid ) :Bool`

Kill the job of _$jobid_.

### `$client->kill_by_name( $jobname ) :Bool`

Kill the job specified by job name _$jobname_.

# AUTHOR

TAGOMORI Satoshi <tagomoris {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
