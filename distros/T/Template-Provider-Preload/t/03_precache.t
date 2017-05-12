#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use Test::SubCalls;
use File::Spec::Functions       ':ALL';
use File::Temp                  ();
use Template                    ();
use Template::Provider          ();
use Template::Provider::Preload ();

my $INCLUDE_PATH = catdir( 't', 'template' );
my $COMPILE_DIR  = File::Temp::tempdir( CLEANUP => 1 );
ok( -d $INCLUDE_PATH, 'Found template directory' );
ok( -d $COMPILE_DIR,  'Found compile directory'  );

# Create the preloader
my $provider = Template::Provider::Preload->new(
	CACHE_SIZE   => 10,
	PRECACHE     => 1,
        INCLUDE_PATH => $INCLUDE_PATH,
        # COMPILE_DIR  => $COMPILE_DIR,
);
isa_ok( $provider, 'Template::Provider' );
isa_ok( $provider->_OBJECT_, 'Template::Provider' );
is_deeply(
	[
		$provider->_OBJECT_->{SLOTS},
		$provider->_OBJECT_->{LOOKUP},
		$provider->_OBJECT_->{SIZE},
	],
	[ 0, {}, 10 ],
	'Externals look as expected',
);

# Can we get the transformed paths
is_deeply( $provider->paths, [ $INCLUDE_PATH ], '->paths ok' );

# Fetch a compiled template directly
sub_track( 'Template::Provider::fetch' );
ok( $provider->prefetch, '->prefetch returns true' );
sub_calls( 'Template::Provider::fetch', 6, 'Initial fetches called' );

# Internals should remain unchanged
is_deeply(
	[
		$provider->_OBJECT_->{SLOTS},
		$provider->_OBJECT_->{LOOKUP},
		$provider->_OBJECT_->{SIZE},
	],
	[ 0, {}, 10 ],
	'Externals look as expected',
);

# Create a Template processor
my $template = Template->new(
	DEBUG          => 1,
	LOAD_TEMPLATES => [ $provider ],
);
isa_ok( $template, 'Template' );

# Do a template run
my $output = '';
sub_reset( 'Template::Provider::fetch' );
$template->process('a/b/c/hello.tt', { name => 'Ingy' }, \$output )
	or do {
		die $template->error;
	};
is( $output, "Hello, Ingy.\n", "output is correct" );
sub_calls( 'Template::Provider::fetch', 0, 'Provider fetch not called' );

# Internals should remain unchanged
is_deeply(
	[
		$provider->_OBJECT_->{SLOTS},
		$provider->_OBJECT_->{LOOKUP},
		$provider->_OBJECT_->{SIZE},
	],
	[ 0, {}, 10 ],
	'Externals look as expected',
);
