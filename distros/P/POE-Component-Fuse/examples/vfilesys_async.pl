#!/usr/bin/perl
use strict; use warnings;

# uncomment this to have debugging
sub POE::Component::Fuse::DEBUG { 1 }

# loopback to our home directory!
use Filesys::Virtual::Async::Plain;
my $vfs = Filesys::Virtual::Async::Plain->new(
	'cwd'		=> '/',
	'root'		=> $ENV{'PWD'},
	'home_path'	=> '/',
);

# load FUSE goodness
use POE::Component::Fuse;
POE::Component::Fuse->spawn(
	'vfilesys'	=> $vfs,
	'umount'	=> 1,
);

print "Check us out at the default place: /tmp/poefuse\n";
print "In it you should see the contents of the directory you ran this script from.\n";
print "LOOPBACK MAGIC! :)\n";

# fire up POE
POE::Kernel->run();
exit;
