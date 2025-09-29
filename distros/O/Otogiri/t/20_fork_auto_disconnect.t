#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Check if fork is available
plan skip_all => "fork not available" unless $^O ne 'MSWin32';

# Create test package to track disconnect method calls
{
    package TestOtogiri;
    use parent 'DBIx::Otogiri';
    
    our $disconnect_called_count = 0;
    
    sub disconnect {
        my $self = shift;
        $disconnect_called_count++;
        $self->SUPER::disconnect(@_);
    }
}

# Test with SQLite in-memory database
my $db = TestOtogiri->new(
    connect_info => ['dbi:SQLite::memory:', '', '']
);

# Verify that database handle is connected
ok($db->dbh->FETCH('Active'), 'Database is connected');

# Reset disconnect call count before fork
$TestOtogiri::disconnect_called_count = 0;

# Fork test
my $pid = fork();

if ($pid == 0) {
    # Child process
    # Reconnect occurs automatically in child process, so owner_pid is updated
    $db->dbh;  # Calling dbh method triggers reconnect
    exit 0;
} elsif (defined $pid) {
    # Parent process
    waitpid($pid, 0);
    
    # Destroy object in parent process
    undef $db;
    
    # Verify that disconnect is called only in parent process
    # (Not called in child process, so count should be 1)
    is($TestOtogiri::disconnect_called_count, 1, 'disconnect called only in parent process');
    
} else {
    # Fork failed
    plan skip_all => "fork failed: $!";
}

done_testing;