# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Wurfl.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 16;
BEGIN { use_ok('Mobile::Libwurfl') };


my $fail = 0;
foreach my $constname (qw(
	WURFL_CACHE_PROVIDER_DOUBLE_LRU WURFL_CACHE_PROVIDER_LRU
	WURFL_CACHE_PROVIDER_NONE WURFL_ENGINE_TARGET_HIGH_ACCURACY
	WURFL_ENGINE_TARGET_HIGH_PERFORMANCE WURFL_ERROR_ALREADY_LOAD
	WURFL_ERROR_CANT_LOAD_CAPABILITY_NOT_FOUND
	WURFL_ERROR_CANT_LOAD_VIRTUAL_CAPABILITY_NOT_FOUND
	WURFL_ERROR_CAPABILITY_GROUP_MISMATCH
	WURFL_ERROR_CAPABILITY_GROUP_NOT_FOUND WURFL_ERROR_CAPABILITY_NOT_FOUND
	WURFL_ERROR_DEVICE_ALREADY_DEFINED
	WURFL_ERROR_DEVICE_HIERARCHY_CIRCULAR_REFERENCE
	WURFL_ERROR_DEVICE_NOT_FOUND WURFL_ERROR_EMPTY_ID
	WURFL_ERROR_FILE_NOT_FOUND WURFL_ERROR_INPUT_OUTPUT_FAILURE
	WURFL_ERROR_INVALID_CAPABILITY_VALUE WURFL_ERROR_INVALID_HANDLE
	WURFL_ERROR_INVALID_PARAMETER WURFL_ERROR_UNEXPECTED_END_OF_FILE
	WURFL_ERROR_UNKNOWN WURFL_ERROR_USERAGENT_ALREADY_DEFINED
	WURFL_ERROR_VIRTUAL_CAPABILITY_NOT_FOUND WURFL_MATCH_TYPE_CACHED
	WURFL_MATCH_TYPE_CATCHALL WURFL_MATCH_TYPE_CONCLUSIVE
	WURFL_MATCH_TYPE_EXACT WURFL_MATCH_TYPE_HIGHPERFORMANCE
	WURFL_MATCH_TYPE_NONE WURFL_MATCH_TYPE_RECOVERY WURFL_OK)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Wurfl macro $constname/) {
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

my $wurfl = Mobile::Libwurfl->new();

my $err = $wurfl->set_engine(WURFL_ENGINE_TARGET_HIGH_PERFORMANCE);
ok ( $err == WURFL_OK, "set_engine()" );

$err = $wurfl->set_cache_provider(WURFL_CACHE_PROVIDER_DOUBLE_LRU, "10000,3000");
ok ( $err == WURFL_OK, "set_cache_provider()" );

$wurfl->load("/usr/share/wurfl/wurfl.xml");

$err = $wurfl->set_engine(WURFL_ENGINE_TARGET_HIGH_PERFORMANCE);
ok ($err == WURFL_ERROR_ALREADY_LOAD, $wurfl->error_message);
ok ($wurfl->has_error_message, "has_error_message()");
$wurfl->clear_error_message;
ok (!$wurfl->has_error_message, "clear_error_message()");

my $d = $wurfl->lookup_useragent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1");
ok (scalar keys %{$d->capabilities} > 50, "capabilities()");

ok ($d->has_capability('doja_3_0'), "has_capability()");
ok (!$d->has_capability('missing_capability'), "has_capability() (again ... with a missing capability)");
ok (!$d->get_capability('doja_3_0'), "get_capability()");

my $id = $d->id;
ok ($id, "id() : $id");

my $ua = $d->useragent;
ok ($ua, "useragent() : $ua");

my $d2 = $wurfl->get_device($id);
ok ($d2, "get_device($id) : ($d2)");

ok ($d2->has_virtual_capability('is_mobile'), "has_virtual_capability()");
ok (!$d2->get_virtual_capability('is_mobile'), "get_virtual_capability()");

