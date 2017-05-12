# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-SLP.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 31 };
use Net::SLP;
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	SLP_AUTHENTICATION_ABSENT SLP_AUTHENTICATION_FAILED SLP_BUFFER_OVERFLOW
	SLP_FALSE SLP_HANDLE_IN_USE SLP_INTERNAL_SYSTEM_ERROR
	SLP_INVALID_REGISTRATION SLP_INVALID_UPDATE SLP_LANGUAGE_NOT_SUPPORTED
	SLP_LAST_CALL SLP_LIFETIME_DEFAULT SLP_LIFETIME_MAXIMUM
	SLP_MEMORY_ALLOC_FAILED SLP_NETWORK_ERROR SLP_NETWORK_INIT_FAILED
	SLP_NETWORK_TIMED_OUT SLP_NOT_IMPLEMENTED SLP_OK SLP_PARAMETER_BAD
	SLP_PARSE_ERROR SLP_REFRESH_REJECTED SLP_SCOPE_NOT_SUPPORTED SLP_TRUE
	SLP_TYPE_ERROR)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Net::SLP macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}
ok(!$fail);


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Caution: openslp SLPOpen does not handle async yet
my $handle;
my $urlcallbackcount;
my $srvtypecallbackcount;
my $attrcallbackcount;
my $regcallbackcount;
my $gotattrs;
my $lasterr;

# Check SLPGetProperty and the version
ok(Net::SLP::SLPGetProperty('net.slp.OpenSLPVersion') ge '1.0.11');
# Openslp ignores calls to SLPSetProperty
Net::SLP::SLPSetProperty('openslp_ignores_this', 'openslp_ignores_this');

ok(Net::SLP::SLPOpen('', 0, $handle) == Net::SLP::SLP_OK);
ok($handle);
ok(Net::SLP::SLPGetRefreshInterval() >= 0);

# Test escaping of URLs
my $unescaped = 'test.test=test';
my $escaped = '';
my $testunescaped = '';
ok(Net::SLP::SLPEscape($unescaped, $escaped, 0) == Net::SLP::SLP_OK);
ok($escaped eq 'test.test\3Dtest');
ok(Net::SLP::SLPUnescape($escaped, $testunescaped, 0) == Net::SLP::SLP_OK);
ok($testunescaped eq $unescaped);

my $scopelist;
ok(Net::SLP::SLPFindScopes($handle, $scopelist) == Net::SLP::SLP_OK);
ok($scopelist eq 'default' || $scopelist eq 'DEFAULT');

###
my $ret = Net::SLP::SLPReg
    ($handle, 
     'service:mytestservice.x://zulu.open.com.au:9048', # URL
     Net::SLP::SLP_LIFETIME_MAXIMUM,                # lifetime
     '',                                             # srvtype (ignored)
     '(attr1=val1),(attr2=val2),(attr3=val3)',          # attrs
     1,                             # Register. SLP does not support reregister.
     \&regcallback);

if ($ret == Net::SLP::SLP_NETWORK_INIT_FAILED)
{
    # Could not contact slpd
    die 'Unable to complete tests because no slp server could be contacted. Check that there is an slp server running';
}
ok($ret == Net::SLP::SLP_OK);
ok($regcallbackcount == 1);

# Check that the registration worked, no filter
ok(Net::SLP::SLPFindSrvs($handle, 'mytestservice.x', '', '', \&urlcallback) == Net::SLP::SLP_OK);
ok($urlcallbackcount == 2);

# This filter should succeed
ok(Net::SLP::SLPFindSrvs($handle, 'mytestservice.x', '', '(attr1=val1)', \&urlcallback) == Net::SLP::SLP_OK);
ok($urlcallbackcount == 4);
# This filter should fail
ok(Net::SLP::SLPFindSrvs($handle, 'mytestservice.x', '', '(attr1=unknown)', \&urlcallback) == Net::SLP::SLP_OK);
ok($urlcallbackcount == 5);

# Get types from all naming authorities
ok(Net::SLP::SLPFindSrvTypes($handle, '*', '', \&srvtypecallback) == Net::SLP::SLP_OK);
ok($srvtypecallbackcount == 2);

# Make sure we get the same attrs back
ok(Net::SLP::SLPFindAttrs($handle, 'mytestservice.x', '', '', \&attrcallback) == Net::SLP::SLP_OK);
ok($attrcallbackcount == 2);
ok($gotattrs eq '(attr1=val1),(attr2=val2),(attr3=val3)');

######### SLPDelAttrs is not implemented in Openslp
## Now delete some attrs
#ok(Net::SLP::SLPDelAttrs($handle, 
#			     'service:mytestservice.x://zulu.open.com.au:9048', # URL
#			     'attr1,attr3',
#			     \&regcallback) == Net::SLP::SLP_OK);
#ok($regcallbackcount == 3);
#ok($lasterr ==  Net::SLP::SLP_OK);
#
## Make sure we get the adjusted
#ok(Net::SLP::SLPFindAttrs($handle, 'mytestservice.x', '', undef, \&attrcallback) == Net::SLP::SLP_OK);
#ok($attrcallbackcount == 3);
#ok($gotattrs eq '(attr2=val2)');


xxx:
# Now delete the service
ok(Net::SLP::SLPDereg($handle, 
		      'service:mytestservice.x://zulu.open.com.au:9048', # URL
		      \&regcallback) == Net::SLP::SLP_OK);
ok($regcallbackcount == 2);
ok($lasterr ==  Net::SLP::SLP_OK);

# Make sure its not there any more
ok(Net::SLP::SLPFindSrvs($handle, 'mytestservice.x', '', '', \&urlcallback) == Net::SLP::SLP_OK);
ok($urlcallbackcount == 6);

# Now close up
Net::SLP::SLPClose($handle);
ok(1);

# Called when a service URL is available from SLPFindSrvs
# This callback returns SLP_TRUE if it wishes to be called again if there is more
# data, else SLP_FALSE
# If $errcode == SLP_LAST_CALL, then there is no more data
sub urlcallback
{
    my ($srvurl, $lifetime, $errcode) = @_;

    $lasterr = $errcode;
    $urlcallbackcount++;
    return Net::SLP::SLP_TRUE;
}

# Called when a service type is available from SLPFindSrvTypes
# $srvtypes kis a comma separated list of service types
# This callback returns SLP_TRUE if it wishes to be called again if there is more
# data, else SLP_FALSE
# If $errcode == SLP_LAST_CALL, then there is no more data
sub srvtypecallback
{
    my ($srvtypes, $errcode) = @_;

    $lasterr = $errcode;
    $srvtypecallbackcount++;
    return Net::SLP::SLP_TRUE;
}

# Called when a service type is available from SLPFindSrvTypes
# $attlist is a comma separated list of service types
# This callback returns SLP_TRUE if it wishes to be called again if there is more
# data, else SLP_FALSE
# If $errcode == SLP_LAST_CALL, then there is no more data
sub attrcallback
{
    my ($attrlist, $errcode) = @_;

    $gotattrs = $attrlist if $errcode == Net::SLP::SLP_OK; # SAve the second last
    $lasterr = $errcode;
    $attrcallbackcount++;
    return Net::SLP::SLP_TRUE;
}

# Called when a service is registered or deregisted with 
# SLPReg(), SLPDeReg() and SLPDelAttrs() functions.
sub regcallback
{
    my ($errcode) = @_;

    $lasterr = $errcode;
    $regcallbackcount++;
}

