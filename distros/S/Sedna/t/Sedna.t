# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sedna.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Sedna') };


my $fail = 0;
foreach my $constname (qw(
	BULK_LOAD_PORTION QUERY_EXECUTION_TIME SEDNA_AUTHENTICATION_FAILED
	SEDNA_AUTOCOMMIT_OFF SEDNA_AUTOCOMMIT_ON SEDNA_BEGIN_TRANSACTION_FAILED
	SEDNA_BEGIN_TRANSACTION_SUCCEEDED SEDNA_BOUNDARY_SPACE_PRESERVE_OFF
	SEDNA_BOUNDARY_SPACE_PRESERVE_ON SEDNA_BULK_LOAD_FAILED
	SEDNA_BULK_LOAD_SUCCEEDED SEDNA_CLOSE_SESSION_FAILED
	SEDNA_COMMIT_TRANSACTION_FAILED SEDNA_COMMIT_TRANSACTION_SUCCEEDED
	SEDNA_CONNECTION_CLOSED SEDNA_CONNECTION_FAILED SEDNA_CONNECTION_OK
	SEDNA_DATA_CHUNK_LOADED SEDNA_ERROR SEDNA_GET_ATTRIBUTE_SUCCEEDED
	SEDNA_NEXT_ITEM_FAILED SEDNA_NEXT_ITEM_SUCCEEDED SEDNA_NO_ITEM
	SEDNA_NO_TRANSACTION SEDNA_OPEN_SESSION_FAILED
	SEDNA_OPERATION_SUCCEEDED SEDNA_QUERY_FAILED SEDNA_QUERY_SUCCEEDED
	SEDNA_RESET_ATTRIBUTES_SUCCEEDED SEDNA_RESULT_END
	SEDNA_ROLLBACK_TRANSACTION_FAILED SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED
	SEDNA_SESSION_CLOSED SEDNA_SESSION_OPEN SEDNA_SET_ATTRIBUTE_SUCCEEDED
	SEDNA_TRANSACTION_ACTIVE SEDNA_UPDATE_FAILED SEDNA_UPDATE_SUCCEEDED)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Sedna macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

