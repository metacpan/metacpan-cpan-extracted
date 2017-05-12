#!perl -T
#
# t/10-Net-FTP-Simple.t - Tests for Net::FTP::Simple
#
# Written by Wil Cooley
#
use lib             qw( tlib );
use strict;
use warnings;
use English         qw( -no_match_vars );
use File::Spec;
use Test::More;

BEGIN {
    eval 'use Test::MockObject';

    if ($EVAL_ERROR) {
        plan skip_all => 'Test::MockObject required for unit tests';
    }
    else {
        plan tests => 76;
    }
}

BEGIN {
    use_ok('Net::FTP::Simple');
}

my @base_files_to_send = qw( file-a file-b file-c );

my @files_to_send 
    = map { 
        File::Spec->join('test-data', 'test-subdir', $_)
    } @base_files_to_send;

my @input_file_list = (
    'drwxr-xr-x  2 2171 2172  4096 Sep 29 17:35 dir with spaces',
    'prw-r--r--  1 0    0        0 Sep 29 17:37 fifo-test',
    '-rw-r--r--  1 2171 2172 55082 Sep 29 20:42 merccurl-auth-page.html',
    'drwxr-xr-x  2 0    0     4096 Sep 29 16:46 testdir',
    '-rwxr-xr-x  1 0    0     6660 Oct 16 18:08 foo',
);

my @expected_list = (
    'merccurl-auth-page.html',
    'foo',
);

# Treat all warnings as failing tests
setup_warning_handler();

#######################################################################
# basic setup
#######################################################################
{
    my $test = "Basic";
    my ($ftp_simple, $fake_conn);

    # Croak if no 'server'
    eval {
        Net::FTP::Simple->_new({});
    };
    if ($EVAL_ERROR =~ m/requires at least 'server' parameter/) { 
        pass("$test: Correctly fail on missing parameters");
    }
    else {
        fail("$test: Did not fail with missing parameters");
    }

    # Non-empty but bogus server name
    eval {
        $ftp_simple = Net::FTP::Simple->_new({ 
                username => undef, 
                password => undef,
                server => 1,
            });
    };

    if ($EVAL_ERROR =~ m/Error creating Net::FTP object/) {
        pass("$test: Correctly fail on bogus parameters");
    }
    else {
        fail("$test: Should have thrown an error here");
    }

    is($ftp_simple, undef, "Bogus connection produces undef object");


    ok($fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");

    ok($ftp_simple = Net::FTP::Simple->_new({
            conn    => $fake_conn,
            server  => 'localhost',
    }), "$test: New object with fake connection");

    is($ftp_simple->_set_conn(undef), undef, 
        "$test: _set_conn() sets and returns undef");

    is($ftp_simple->_conn(), undef, 
        "$test: _conn() returns undef when set to undef");

    {
        my $caller = $ftp_simple->_caller();
        ok($ftp_simple->_caller(), "$test: Caller is '$caller'");
    }

    eval {
        $ftp_simple->_error("Test error");
    };

    if ($EVAL_ERROR) {
        fail("$test: _error() should not have caused exception '$EVAL_ERROR'");
    }
    else {
        pass("$test: _error() did not cause exception w/bad _conn");
    }

}

#######################################################################
# _op_retry
#######################################################################
{
    my $test    = '_op_retry';
    my $op      = 'test_op';
    my $op_msg  = 'retry test message';

    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");

    $fake_conn->set_always('message', $op_msg);

    $Net::FTP::Simple::retry_max{$op} = 3;
    $Net::FTP::Simple::retryable_errors{$op} = [ $op_msg, ];
    $Net::FTP::Simple::retry_wait{$op} = 0;

    ok(my $obj = Net::FTP::Simple->_new({
                conn    => $fake_conn,
                server  => 'localhost',
    }), "$test: Net::FTP::Simple->_new()");

    my @test_data = (
        # Tries     Sequence
        [ 1,        [ 1, ],         ],
        [ 2,        [ 0, 1 ],       ],
        [ 3,        [ 0, 0, 1 ],    ],
    );

    for my $test_args_ref (@test_data) {
        my $tries   =    $test_args_ref->[0];
        my @series  = @{ $test_args_ref->[1] };

        $fake_conn->set_series($op, @series);

        is($obj->_op_retry($op), $tries, 
           "$test: $op succeeded after $tries tries");
    }


    $fake_conn->set_series($op, 0, 0, 0, 1);

    eval {
        $obj->_op_retry($op);
    };

    if ($EVAL_ERROR =~ m/'$op' failed after 4 attempts/) {
        pass("$test: $op correctly failed after 4 tries");
    }
    elsif ($EVAL_ERROR) {
        fail("$test: $op failed after 4 tries with unexpected error"
             . "'$EVAL_ERROR'");
    }
    else {
        fail("$test: $op did not fail after 4 tries as expected");
    }

    $Net::FTP::Simple::retry_max{$op} = 0;

    # FIXME From here down is basically a copy and paste of the above;
    # refactor
    for my $test_args_ref ($test_data[0]) {
        my $tries   =    $test_args_ref->[0];
        my @series  = @{ $test_args_ref->[1] };

        $fake_conn->set_series($op, @series);

        is($obj->_op_retry($op), $tries, 
           "$test: $op succeeded after $tries tries (max 0)");
    }

    
    $fake_conn->set_series($op, 0, 1);

    eval {
        $obj->_op_retry($op);
    };

    if ($EVAL_ERROR =~ m/'$op' failed after 2 attempts/) {
        pass("$test: $op correctly failed after 2 tries");
    }
    elsif ($EVAL_ERROR) {
        fail("$test: $op failed after 2 tries with unexpected error"
             . "'$EVAL_ERROR'");
    }
    else {
        fail("$test: $op did not fail after 2 tries as expected");
    }

}


#######################################################################
# _list_and_filter
#######################################################################
{
    my $test = "_list_and_filter";
    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");
    my ($files_ref, @files);

    my %test_data = (
        "basic w/o filter" => {
            input_list_ref      => [ @input_file_list ],
            expected_list_ref   => [ @expected_list ],
            filter              => undef
        },

        "filename w/spaces, w/o filter" => {
            input_list_ref      => [ @input_file_list,
        '-rw-r--r--  1 2171 2172 55082 Sep 29 20:42 merccurl auth page.html',
                                   ],
            expected_list_ref   => [ @expected_list, 
                                    'merccurl auth page.html' 
                                   ],
            filter              => undef
        },

        "basic w/wide filter" => {
            input_list_ref      => [ @input_file_list ],
            expected_list_ref   => [ @expected_list ],
            filter              => qr/[aeou]+/,
        },

        "basic w/narrow filter" => {
            input_list_ref      => [ @input_file_list ],
            expected_list_ref   => [ grep { /merccurl/ } @expected_list ],
            filter              => qr/merccurl/,
        },

        "empty list"            => {
            input_list_ref      => [],
            expected_list_ref   => [],
            filter              => undef,
        },
    );

    for my $subtest_name (keys %test_data) {
        my $subtest_ref = $test_data{$subtest_name};
        my $subtest_name = "$test/$subtest_name";

        $fake_conn->set_list('dir', @{ $subtest_ref->{'input_list_ref'} });

        ok(my $obj = Net::FTP::Simple->_new({
                conn    => $fake_conn,
                server  => 'localhost',
                file_filter => $subtest_ref->{'filter'},
        }), "$subtest_name: Net::FTP::Simple->_new()");

        my @files = $obj->_list_and_filter(); 

        is_deeply(\@files, $subtest_ref->{'expected_list_ref'},
            "$subtest_name: Returned list correct (list context)");

        my $files_ref = $obj->_list_and_filter(); 

        if (defined $files_ref) {
            is_deeply($files_ref, $subtest_ref->{'expected_list_ref'}, 
                "$subtest_name: Returned list correct (scalar context)");
        }
        else {
            is($files_ref, undef,
                "$subtest_name: Returned undef (scalar context)");
        }

    }

}

#######################################################################
# list_files
#######################################################################
{
    my $test = "list_files (basic)";
    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");
    my @files;


    $fake_conn->set_list('dir', @input_file_list);

    ok(@files = Net::FTP::Simple->list_files({
            conn    => $fake_conn,
            server  => 'localhost',
    }), "$test: Returns something true");

    is_deeply(\@files, \@expected_list, "$test: Returned list correct");


    # Add a filter
    ok(@files = Net::FTP::Simple->list_files({
            conn        => $fake_conn,
            server      => 'localhost',
            file_filter => qr/merccurl/,
    }), "$test: Returns something true");

    is_deeply(\@files, [ $expected_list[0] ], 
              "$test: Returned list w/filter correct");

}

#######################################################################
# list_files
#   -> empty list
#######################################################################
{
    my $test = "list_files (empty list)";
    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");

    $fake_conn->set_list('dir', ());

    my @files = Net::FTP::Simple->list_files({
            conn    => $fake_conn,
            server  => 'localhost',
    });

    is_deeply(\@files, [], 
        "$test: Returns empty list (class method)");

    @files = Net::FTP::Simple::list_files({
            conn    => $fake_conn,
            server  => 'localhost',
    });

    is_deeply(\@files, [], 
        "$test: Returns empty list (module subroutine)");
}

#######################################################################
# send_files
#######################################################################
{
    my $test = "send_files (basic)";

    my @succ_transfers;

    ok(my $fake_conn = new_mock_ftp(), "$test: Net::FTP mock object");

    $fake_conn->set_true( qw( put rename message ) );

    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is_deeply(\@succ_transfers, \@files_to_send, 
        "$test: Sends all files (class method)");

    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is_deeply(\@succ_transfers, \@files_to_send, 
        "$test: Sends all files (module subroutine)");
}



#######################################################################
# send_files
#   -> test 'retry'
#######################################################################
{
    my $test = "send_files (retry)";

    # Don't really want it to wait the whole retry period
    $Net::FTP::Simple::retry_wait{'rename'} = 0;

    my ($retries, $pattern, $sub, @succ_transfers);

    my $warn_handlers = {
        qr/Error renaming '(file-.\.tmp)' to '(file-.)'/ms          
            => sub {
                my ($from, $to) = @_;
                pass("$test: Correctly failed to rename '$from' to '$to'");
            },
        };

    setup_warning_handler($test, $warn_handlers);

    ok(my $fake_conn = new_mock_ftp(), "$test: Net::FTP mock object");

    $fake_conn->set_true( qw( put ) );
    $fake_conn->set_always(
        'message' =>      qq/The process cannot access the file because /
                        . qq/it is being used by another process/
    );

=begin comment
    Test retries of file renaming

    Fail once on the first file.
    Fail once on the second file.
    Succeed immediately on the third file.
=end comment
=cut

    $fake_conn->set_series('rename', 0, 1, 0, 1, 1);
    ($pattern, $sub)  = _gen_sub_count_transfer_tries($test, 
        $files_to_send[0] => 2,
        $files_to_send[1] => 2,
        $files_to_send[2] => 0,
    );

    $warn_handlers->{ $pattern } = $sub;         

    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is(@succ_transfers, 3, "$test: 3 files sent");

=begin comment
    Test retries of file renaming

    Fail once on the first file
    Twice on the second file
    Four times (which is the max) on the third
      There is a final one to catch the potential case where the third does
      not fail after four tries.
    
    Note that there is a potential off-by-one here: The $retry_max{'rename'}
     is 3, which means there should be I<4> tries (which is one try and 
     I<3> retries!).
    
=end comment
=cut

    $fake_conn->set_series('rename', 0, 1, 0, 0, 1, 0, 0, 0, 0, 1);
    ($pattern, $sub) =  _gen_sub_count_transfer_tries($test, 
        $files_to_send[0]   => 2,
        $files_to_send[1]   => 3,
        $files_to_send[2]   => 0,
    );

    $warn_handlers->{ $pattern } = $sub;

    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is(@succ_transfers, 2, "$test: 2 files set, one failed");

    #-----------------------------------------------------

    #
    # Fail the max number of tries to ensure that failure will happen
    #

    $retries = $Net::FTP::Simple::retry_max{'rename'};

    $fake_conn->set_series('rename', map { 0 } 0..$retries );

    @succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => [ $files_to_send[0] ],
        });

    is_deeply(\@succ_transfers, [],
        "$test: 0 successes after max $retries retry failures");

    setup_warning_handler();
}

#######################################################################
# rename_files
#######################################################################
{
    my $test = "rename_files (basic)";

    my @succ_renames;

    ok(my $fake_conn = new_mock_ftp(), "$test: Net::FTP mock object");

    $fake_conn->set_true( qw( rename ) );

    ok(@succ_renames = Net::FTP::Simple->rename_files({
            conn            => $fake_conn,
            server          => 'localhost',
            rename_files    =>
                { map { $_ => $_ . '.FOO' } @base_files_to_send },
    }), "$test: Returned non-empty list");

    is_deeply(\@succ_renames, \@base_files_to_send,
        "$test: Renamed files correctly");
}


#######################################################################
# rename_files
#   -> retry
#######################################################################
{
    my $test = "rename_files (retry)";

    my ($pattern, $sub, $retries, @succ_renames);

    my %rename_files = map { $_ => $_ . '.FOO' } @base_files_to_send;

    # Don't really want it to wait the whole retry period
    $Net::FTP::Simple::retry_wait{'rename'} = 0;

    my $warn_handlers = {
        qr/Error renaming '(.*)' to '(.*)'/ms          
            => sub {
                my ($from, $to) = @_;
                pass("$test: Correctly failed to rename '$from' to '$to'");
            },
        };

    setup_warning_handler($test, $warn_handlers);

    ok(my $fake_conn = new_mock_ftp(), "$test: Net::FTP mock object");

    $fake_conn->set_always(
        'message' =>      qq/The process cannot access the file because /
                        . qq/it is being used by another process/
    );

=begin comment
    Fail once on the first file.
    Fail once on the second file.
    Succeed immediately on the third file.
=end comment
=cut

    $fake_conn->set_series('rename', 0, 1, 0, 1, 1);
   ($pattern, $sub)  = _gen_sub_count_rename_tries($test, 
        $base_files_to_send[0] => 2,
        $base_files_to_send[1] => 2,
        $base_files_to_send[2] => 0,
   );

   $warn_handlers->{ $pattern } = $sub;         


    ok(@succ_renames = Net::FTP::Simple->rename_files({
            conn            => $fake_conn,
            server          => 'localhost',
            rename_files    => \%rename_files,
    }), "$test: Returns non-empty list");

    is(@succ_renames, 3, "$test: 3 files sent");

=begin comment
   
     Fail once on the first file
     Twice on the second file
     Four times (which is the max) on the third
       There is a final one to catch the potential case where the third does
       not fail after four tries.
    
     Note that there is a potential off-by-one here: The $retry_max{'rename'}
     is 3, which means there should be I<4> tries (which is one try and 
     I<3> retries!).
    
=end comment
=cut

    $fake_conn->set_series('rename', 0, 1, 0, 0, 1, 0, 0, 0, 0, 1);
    ($pattern, $sub) =  _gen_sub_count_rename_tries($test, 
        $base_files_to_send[0]   => 2,
        $base_files_to_send[1]   => 3,
        $base_files_to_send[2]   => 0,
    );

    $warn_handlers->{ $pattern } = $sub;

    ok(@succ_renames = Net::FTP::Simple->rename_files({
            conn            => $fake_conn,
            server          => 'localhost',
            rename_files    => \%rename_files,
    }), "$test: Returns non-empty list");

    is(@succ_renames, 2, "$test: 2 files renamed, one failed");

    #-----------------------------------------------------
    #
    # Fail the max number of tries to ensure that failure will happen
    #

    $retries = $Net::FTP::Simple::retry_max{'rename'};

    $fake_conn->set_series('rename', map { 0 } 0..$retries );

    @succ_renames = Net::FTP::Simple->rename_files({
            conn            => $fake_conn,
            server          => 'localhost',
            rename_files    => \%rename_files,
        });

    is_deeply(\@succ_renames, [],
        "$test: 0 successes after max $retries retry failures");

    setup_warning_handler();
}


# Do some basic setup of the mock object
sub new_mock_ftp {
    my $fake_conn = Test::MockObject->new();

    $fake_conn->set_true( qw( login binary ok quit ) );

    return $fake_conn;
}

#
# Setup $SIG{__WARN__} with a hash of I<pattern> => I<action> items.
# I<pattern> should be a regexp.  I<action> may be either something true or
# false or a code ref.  If a code ref, the code ref is called with any matches
# from the pattern comparison.
#
# Does not re-throw the warnings as might be desirable in non-test code.
#
# Can be used as a universal warnings-as-test-failure with no parameters.
#
sub setup_warning_handler {
    # Clear handler
    my ($test, $expected_warnings);
    if (@_) {
        ($test, $expected_warnings) = @_;
    }

    else {
        $test = "Global";
        $expected_warnings = {};
    }


    $SIG{__WARN__} = sub {
        my ($err) = @_;
        chomp $err;

        for my $warning (keys %{ $expected_warnings }) {
            if (my @matches = $err =~ m{ $warning }xms) {
                if ( ref $expected_warnings->{ $warning } eq 'CODE' ) {
                    $expected_warnings->{ $warning }->(@matches);
                }
                elsif ( $expected_warnings->{ $warning } ) {
                    pass("$test: Expected warning '$err'");
                }
                else {
                    fail("$test: Expected but failing warning '$err'");
                }
                return;
            }
        }
        fail("$test: Unexpected warning '$err'");
    };
}

# Yay for closures!
#
# _gen_sub_count_transfer_tries - This generates a code ref/anonymous
# subroutine which is a (key, value) pair for use w/setup_warning_handler.
# The $pattern matches the warning message from Net::FTP::Simple after a number
# of tries.  It expects a hash containing filenames and the expected number
# of tries.
#
sub _gen_sub_count_transfer_tries {
    my ($test, %expected_tries) = @_;
    my $pattern = qr/Transfer of file '(.*)' succeeded after (\d+) tries/ms;

    return $pattern => sub {
            my ($filename, $tries) = @_;
            
            unless (exists $expected_tries{ $filename }) {
                fail("$test: Did not expect failure of file '$filename'");
                return;
            }

            is($tries, $expected_tries{ $filename },
                "$test: Successfully sent '$filename' after $tries tries");
        };
}

sub _gen_sub_count_rename_tries {
    my ($test, %expected_tries) = @_;
    my $pattern = 
        qr/Rename of file from '(.*)' to '(.*)' succeeded after (\d+) tries/ms;

    return $pattern => sub {
            my ($file_from, $file_to, $tries) = @_;
            
            unless (exists $expected_tries{ $file_from }) {
                fail("$test: Did not expect failure of file '$file_from'");
                return;
            }

            is($tries, $expected_tries{ $file_from },
            "$test: Successfully renamed '$file_from' to '$file_to' after $tries tries");
        };
}
