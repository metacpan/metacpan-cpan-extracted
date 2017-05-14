# tests for generic musician object.  this object is to be subclassed

BEGIN
{
	use strict;	
	use Test::More 'no_plan';
	# MIDI::Simple uses unquoted strings, but it's yummy.
	$SIG{__WARN__} = sub { return $_[0] unless $_[0] =~ /Unquoted string/ };

	#################
	# test module use
	#################
	use_ok('POE');
	use_ok('POE::Framework::MIDI::Musician');
	
}

ok(my $musician = POE::Framework::MIDI::Musician->new( {
		name => 'Frank', 
		package => 'Mytest',
		channel => 1,
		data => [ 'foo', 'bar', 'blah' ],
		}));
ok(my $pkg = $musician->package,'Package');
ok(my $name = $musician->name, 'Name');
ok(my $chan = $musician->channel, 'Channel');
ok($musician->data);


package MyTest;
use base 'POE::Framework::MIDI::Musician';
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Bar;
sub make_bar {
	my $self = shift;
	my $barnum = shift or die "called make_bar with no barnum";
	my $bar = POE::Framework::MIDI::Bar->new(barnum => 1);
	my $note = POE::Framewor::MIDI::Note->new( name => 'C3', duration => 'qn' );
	$bar->add_event($note);
	return $bar;
	
}

1;