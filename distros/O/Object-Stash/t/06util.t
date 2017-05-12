use Test::More tests => 25;

{
	package Local::Example;
	use Object::Stash::Util qw/has_stash/;
	
	has_stash stash1 => ();
	has_stash stash2 => (
		isa    => 'HashRef',
		);
	has_stash stash3 => (
		isa    => 'Object',
		);
	has_stash stash4 => (
		handles   => 'fish',
		);
	has_stash stash5 => (
		handles   => [
			'ape',
			'gibbon' => { is => 'ro' },
			'monkey',
			],
		);
	has_stash stash6 => (
		handles   => {
			'lion'    => { default => 'leo' },
			'panther' => { default => 'pantera', is => 'ro' },
			'tiger'   => { default => sub { 'tigris' } },
			'lynx'    => { default => sub { $_[0] } },
			},
		);
	
	sub new { my @x = @_ and bless \@x }
}

my $obj = Local::Example->new;

use Data::Printer;
p $obj;

can_ok
	'Local::Example',
	$_
	foreach qw/stash1 stash2 stash3 stash4 stash5 stash6/;

is
	ref $obj->stash1,
	'Local::Example::stash1',
	'by default we create object stashes';

is
	ref $obj->stash2,
	'HASH',
	'can explicitly create hashref stashes';

is
	ref $obj->stash3,
	'Local::Example::stash3',
	'can explicitly create object stashes';

can_ok
	$obj => 'fish';

$obj->fish = 'carp';

is
	$obj->fish,
	'carp',
	'accessor works';
	
is
	$obj->stash4->{fish},
	'carp',
	'data stored correctly in stash4';

can_ok
	$obj => $_
	foreach qw/ape gibbon monkey/;

$obj->stash5->{gibbon} = 'gibbus';
$obj->gibbon('gilbert'); # read-only, so should not do anything

is
	$obj->gibbon,
	'gibbus',
	'read only works';

can_ok
	$obj => $_
	foreach qw/lion panther tiger/;

is
	$obj->lion,
	'leo',
	'default works';

is
	$obj->panther,
	'pantera',
	'default works for read-only attributes';

is
	$obj->tiger,
	'tigris',
	'coderef default works';

is
	$obj->lynx,
	$obj,
	'coderef is called as a method';

$obj->lion  = 'leo 2';
$obj->tiger = 'tigris 2';

is
	$obj->lion,
	'leo 2',
	'default can be overridden';

is
	$obj->tiger,
	'tigris 2',
	'coderef default can be overridden';
