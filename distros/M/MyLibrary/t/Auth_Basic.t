use Test::More tests => 10;
use Test::LongString;
use strict;

# use Auth module
use_ok('MyLibrary::Auth::Basic');

# create an auth object
my $auth = MyLibrary::Auth::Basic->new();
isa_ok($auth, 'MyLibrary::Auth::Basic');

# get initial status
my $sessid = $auth->sessid();
is ($auth->status(), 'not authenticated', 'get status()');

# create a test patron
use MyLibrary::Patron;
my $patron = MyLibrary::Patron->new();
$patron->patron_firstname('Robert');
$patron->patron_surname('Fox');
$patron->patron_username('rfox2');
$patron->patron_stylesheet_id(1);
$patron->patron_password('testpass');
$patron->commit();
my $patron_id = $patron->patron_id();

# authenticate patron
is ($auth->authenticate(username => 'rfox2', password => 'testpass'), 'success', 'authenticate()');

# get current status
is ($auth->status(), 'authenticated', 'status() authenticated');

# see if patron ids match
is ($auth->user_id(), $patron->patron_id(), 'user_id() matches');

# see if username is a match
is ($auth->username(), 'rfox2', 'username() matches');

# test output for place_cookie()
like_string($auth->place_cookie(), qr/Cookie/, 'place_cookie()');

# now, remove a cookie
like_string($auth->remove_cookie(), qr/Action: remove/, 'remove_cookie()');

# delete the session data
is ($auth->close_session(), 1, 'close_session()');

# remove test patron
$patron->delete();
