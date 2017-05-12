#!/usr/bin/perl
use strict; use warnings;

# uncomment this to have debugging
sub POE::Component::Fuse::DEBUG { 1 }

# loopback to our home directory!
use Filesys::Virtual::Async::inMemory;
my $vfs = Filesys::Virtual::Async::inMemory->new;

# load FUSE goodness
use POE::Component::Fuse;
POE::Component::Fuse->spawn(
	'vfilesys'	=> $vfs,
	'umount'	=> 1,
);

print "Check us out at the default place: /tmp/poefuse\n";
print "This is an entirely in-memory filesystem, some things might not work...\n";

# fire up POE
POE::Kernel->run();
exit;
