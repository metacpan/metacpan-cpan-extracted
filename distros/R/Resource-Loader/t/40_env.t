# -*- perl -*-

#use Test::More qw/no_plan/;
use Test::More tests => 27;

use Resource::Loader;

$ENV{RMTESTING}	 = 1;
$ENV{RMVERBOSE}	 = 1;
$ENV{RMCONT}	 = 1;
$ENV{RMSTATES}	 = 'always:sometimes';

ok $m = Resource::Loader->new( testing => 0,
				verbose => 0,
				cont    => 0,
				resources => [ { name => 'never',
						 when => sub { 1 },
						 what => sub { die "should never run this" },
					       },
					       { name => 'sometimes',
						 when => sub { 1 },
						 what => sub { 1 },
					       },
					       { name => 'always',
						 when => sub { 1 },
						 what => sub { 1 },
					       },
					     ],
			      ),		"new( args )";

#--- always, while testing

$loaded = $m->load;
ok ! $loaded, 				'no $loaded';
ok $status = $m->status,		"status()";
ok $m->verbose,			       	"verbose()";
ok $m->testing,			       	"testing()";
ok $m->cont,			       	"cont()";
is $status->{always}, 'notrun',		"always skipped in testing";
is $status->{sometimes}, 'notrun',     	"sometimes skipped in testing";
is $status->{never}, 'skipped',		"never ignored in testing";

#--- sometimes, not testing

$ENV{RMCONT}	 = 1;
$ENV{RMVERBOSE}	 = 0;
$ENV{RMSTATES}	 = 'sometimes';
$ENV{RMTESTING}  = 0;

ok $loaded = $m->load,			"load()";
is_deeply $loaded, { sometimes => 1 },	'$loaded';
ok $status = $m->status,		"status()";
is $status->{always}, 'skipped',       	"always ignored because not present in RMSTATES";
is $status->{sometimes}, 'loaded',     	"sometimes run because present in RMSTATES";
is $status->{never}, 'skipped',		"never ignored because not present in RMSTATES";

#--- sometimes, testing

$ENV{RMCONT}	 = 1;
$ENV{RMVERBOSE}	 = 0;
$ENV{RMSTATES}	 = 'sometimes';
$ENV{RMTESTING}  = 1;

$loaded = $m->load;
ok ! $loaded, 				'no $loaded';
ok $status = $m->status,		"status()";
is $status->{always}, 'skipped',       	"always ignored because not present in RMSTATES";
is $status->{sometimes}, 'notrun',     	"sometimes not run. While present in RMSTATES, we're testing";
is $status->{never}, 'skipped',		"never ignored because not present in RMSTATES";

#--- RMSTATES = ''; nothing should be run

$ENV{RMTESTING}	 = 0;
$ENV{RMVERBOSE}	 = 1;
$ENV{RMCONT}	 = 0;
$ENV{RMSTATES}	 = '';

ok $m = Resource::Loader->new( testing => 1,
				verbose => 1,
				cont    => 1,
				resources => [ { name => 'never',
						 when => sub { 1 },
						 what => sub { die "should never get here" },
					       },
					       { name => 'sometimes',
						 when => sub { 1 },
						 what => sub { 1 },
					       },
					       { name => 'always',
						 when => sub { 1 },
						 what => sub { 1 },
					       },
					     ],
			      ),		"new( args )";

$loaded = $m->load;
ok ! $loaded, 				'no $loaded';
ok $status = $m->status,		"status()";
is $m->testing, 0,		       	"testing()";
is $status->{always}, 'skipped',       	"always status";
is $status->{sometimes}, 'skipped',    	"sometimes status";
is $status->{never}, 'skipped',		"never status";
