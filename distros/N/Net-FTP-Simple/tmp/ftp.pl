#!/usr/bin/perl
#
use strict;
use warnings;
use English             qw( -no_match_vars );
use File::Basename      qw( basename );
use Net::FTP::Simple;

my @test_files = qw(
    test-data/merccurl-file-list-bca.html
    test-data/merccurl-auth-page.html
    test-data/merccurl-file-list-fsa.html
    test-data/merccurl-file-list-ods.html
);



my $user = 'testy';
my $pass = 't3st1';
my $host = 'localhost';

my @remote = Net::FTP::Simple->list_files({
        username        => $user,
        password        => $pass,
        server          => $host,
        remote_dir      => 'whehere',
        debug_ftp       => 1,
        file_filter     => qr/file/,
    });

print "List:\n\t", join("\n\t", @remote), "\n"
    if @remote;

#exit;

my @sent = Net::FTP::Simple->send_files({
        username        => $user,
        password        => $pass,
        server          => $host,
        files           => \@test_files,
        remote_dir      => 'whehere',
        debug_ftp       => 1,
    });

print "The following files were sent successfully:\n\t",
      join("\n\t", @sent), "\n";

chdir 'test-data-tmp'
    or die "Error chdir: '$OS_ERROR'";

my @received = Net::FTP::Simple->retrieve_files({
        username        => $user,
        password        => $pass,
        server          => $host,
        remote_dir      => 'whehere',
        debug_ftp       => 1,
        #files           => [ map { basename($_) } @test_files ],
        file_filter     => qr/file/,
        delete_after    => 1,
    });

print "The following files were retrieved successfully:\n\t",
    join("\n\t", @received), "\n";
