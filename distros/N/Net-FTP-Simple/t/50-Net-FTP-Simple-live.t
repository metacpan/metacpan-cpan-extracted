#!perl -T
#
use strict;
use warnings;
use Data::Dumper;
use English         qw( -no_match_vars );
use File::Basename  qw( basename );
use File::Spec;
use POSIX           qw( strftime );
use Test::More;

BEGIN {
    unless (exists $ENV{'NET_FTP_SIMPLE_LOGIN'}) {
        plan skip_all => 'FTP conn info missing; set env var'
                    . ' NET_FTP_SIMPLE_LOGIN="user:pass:server"';
    }
    else {
        plan tests => 13;
        use_ok('Net::FTP::Simple');
    }
}


my @base_test_files = qw( file-a file-b file-c );

my @files_to_send 
    = map {
        File::Spec->join('test-data', 'test-subdir', $_)
    } @base_test_files;

my %conn_info = parse_login_env();

{
    my $test = "list_files";
    my @expected = qw(test-file);
    my @remote_files;

    my $test_conn = {
        %conn_info,
        remote_dir  => 'listing',
    };

    ########################################
    # Test w/o filter
    ########################################
    delete $test_conn->{'file_filter'};

    ok(@remote_files = Net::FTP::Simple->list_files($test_conn), 
        "$test: Returned something positive"
    );

    is_deeply(\@remote_files, \@expected, 
              "$test: Returned expected items w/o filter");

    ########################################
    # Test w/filter
    ########################################
    $test_conn->{'file_filter'} = qr/test/;

    ok(@remote_files = Net::FTP::Simple->list_files($test_conn), 
        "$test: Returned something positive"
    );

    is_deeply(\@remote_files, \@expected, 
              "$test: Returned expected items w/filter");


    ########################################
    # Test w/non-matching filter
    ########################################
    $test_conn->{'file_filter'} = qr/testBOGUS/;

    @remote_files = Net::FTP::Simple->list_files($test_conn);
    
    is_deeply(\@remote_files, [], 
        "$test: non-matching filter returns empty list");

}

{
    my $test = "send_files";

    # Creates a very deep directory structure by getting the time in UNIX time
    # (seconds since the epoch) and putting a slash between each number
    my $remote_dir = File::Spec->join('sending', 
            join('/', split(//, strftime("%s", localtime(time)))));

    my $test_conn = {
        %conn_info,
        remote_dir  => $remote_dir,
        files       => \@files_to_send,
    };

    ok(my @sent_files = Net::FTP::Simple->send_files($test_conn),
        "$test: Returned something positive");

    is_deeply(\@sent_files, \@files_to_send,
              "$test: Sent all files successfully");

    delete $test_conn->{'files'};
    ok(my @list_files = Net::FTP::Simple->list_files($test_conn),
        "$test: Listing sent files returned non-empty list");

    is_deeply(\@list_files, [ map { basename($_) } @sent_files ],
        "$test: list_files returned same list as send_files");

}

{
    my $test = "rename_files";

    my $remote_dir = File::Spec->join('renaming', 
                                      strftime("%s", localtime(time)));

    my $test_conn = {
        %conn_info,
        remote_dir  => $remote_dir,
        files       => \@files_to_send,
    };

    my %rename_to = map { $_ => $_ . '.FOO' } @base_test_files;

    ok(my @sent_files = Net::FTP::Simple->send_files($test_conn),
        "$test: Returned something positive");

    $test_conn->{'rename_files'} = \%rename_to;
    ok(my @renamed_files = Net::FTP::Simple->rename_files($test_conn),
        "$test: Returned non-empty list");

    is_deeply(\@renamed_files, \@base_test_files,
        "$test: Renamed correctly");

}

sub parse_login_env {
    my %conn_info;

    @conn_info{ qw( username password server ) }
        = split(/:/, $ENV{'NET_FTP_SIMPLE_LOGIN'}, 3);

    # Wholesale untaint; trust test environment
    for my $key (keys %conn_info) {
        ($conn_info{$key}) = ($conn_info{$key} =~ m{ \A (.*) \z }xms);
    }

    return %conn_info;
} 
