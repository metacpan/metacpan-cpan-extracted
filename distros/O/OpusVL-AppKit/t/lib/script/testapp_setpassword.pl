
use strict;
use File::ShareDir;
use Getopt::Compact;
use TestApp;
use OpusVL::AppKit::Schema::AppKitAuthDB;

my $username;
my $password;

# .. set option the arguments prefs..
my $go = new Getopt::Compact
(
    name => 'TestApp Users admin script', 
    struct =>
    [
        [[qw(u user)],      qq(specify a username), '=s', \$username],
        [[qw(p password)],  qq(specify a password), '=s', \$password],
     ]
);

# test we have something..it is gay we have to do this.. but Getopt::Compact seems to ignore the '=s'!
die ( $go->usage() ) unless $username && $password; 

# .. get the path for this name space..
my $path = File::ShareDir::module_dir( 'TestApp' );

# get the DBIx::Class schema..
my $schema = OpusVL::AppKit::Schema::AppKitAuthDB->connect
(
  'dbi:SQLite:' . $path . '/root/db/appkit_auth.db',
  '',
  '',
  { AutoCommit => 1 },
);

print "Appying password $password to user $username...\n";

my $user = $schema->resultset('User')->find( { username => $username } );

die ("Could not find user called $username !") unless $user;

print " Changing password from '" . $user->password. "' to '" . $password . "' \n";

$user->update( { password => $password } );

print "done.\n";

__END__
