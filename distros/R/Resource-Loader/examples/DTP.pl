#!/usr/local/bin/perl -w
#
# DTP.pl - Dev/Test/Prod database loader
#
# Joshua Keroes - 24 Apr 2003

use strict;
use Resource::Loader;
use Sys::Hostname;
use Data::Dumper;

# Things to note:
#
# cont() is not set. That means that only one of the resources will 
# be returned.
#
# I assume that we're in development if the box is named "sandbox" and
# there's a CVS directory present. It's a reasonable heuristic for us.
#
# 'test' is pretty straightforward. If the machine is named 'test',
# load the appropriate vars.
#
# The prod case is the default case. Prod's 'when' case will always
# succeed. This lets us deploy on any machine and have it hit the
# production data.

my $mgr = Resource::Loader->new(
	verbose => 1, # default is 0
	testing => 0, # default is 0
	cont    => 0, # default is 0
	resources => [
		{ name => 'dev',
		  when => sub { hostname() eq "sandbox" && -d 'CVS' },
 		  what => sub { { ds   => 'dbi:mysql:host=sandbox.eli.net;sid=foodev',
				  user => 'readonly',
				  pass => '',
			        }
			      },
		},
		{ name => 'test',
		  when => sub { hostname() eq "test" },
 		  what => sub { { ds   => 'dbi:mysql:host=db.eli.net;sid=footest',
				  user => 'foo',
				  pass => '$Dd%f1qA$s',
			        }
			      },
		},
		{ name => 'prod',
		  when => sub { 1 }, # default case
 		  what => sub { { ds   => 'dbi:mysql:host=db.eli.net;sid=fooprod',
				  user => 'foo',
				  pass => '$Dd%f1qA$s',
			        }
			      },
		},
	]
);

my $loaded = $mgr->load;
my $status = $mgr->status;

print "Resource::Loader::loaded():\n  " . Data::Dumper->Dump([$loaded], ['loaded']);
print "Resource::Loader::status():\n  " . Data::Dumper->Dump([$status], ['status']);
