#!perl

use strict;
use warnings;

use Test::More 1.0;
use Capture::Tiny qw( capture_stdout );

require 't/lib/setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

my $release = $class->new;

{
no warnings 'redefine';
local *Module::Release::get_recent_contributors =
  sub { return ('Joe Bloggs <joe@bloggs.com>') };
is(
	$release->get_recent_contributors,
	('Joe Bloggs <joe@bloggs.com>'),
	"Can get defined recent contributor list"
	);
}

{
my $output = capture_stdout { $release->show_recent_contributors };
is( $output, '',
	"No contributor output without subclassed get_recent_contributors" );
}

{
no warnings 'redefine';
local *Module::Release::get_recent_contributors =
  sub { ( 'Jane Smith <jane@smith.com>', 'Joe Bloggs <joe@bloggs.com>' ) };

my $output = capture_stdout { $release->show_recent_contributors };
my $expected_output = <<'EOF';
Contributors since last release:
	Jane Smith <jane@smith.com>
	Joe Bloggs <joe@bloggs.com>
EOF
is( $output, $expected_output,
	"Contributors since last release are shown" );
}

done_testing();
