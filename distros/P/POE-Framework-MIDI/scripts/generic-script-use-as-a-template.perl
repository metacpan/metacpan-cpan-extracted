#!/usr/bin/perl
#
# this is an example script that you can use as a template
#
# it won't run as-is...it needs your custom musician packages.
#
# see POE::Framework::MIDI::Musician::Generic for a template 
# for creating musicians


use POE;
use strict;
use lib '../..';
use POE::Framework::MIDI::POEConductor;
use POE::Framework::MIDI::POEMusician;
 
# add your musician objects ...
use POE::Framework::MIDI::Musician::YourCustomModule;


POE::Framework::MIDI::POEConductor->spawn(

{
bars => 30,
verbose => 1,
debug => 1,
filename => 'test_output.mid',
musicians =>
[
{
	name => 'frank',
	
	# specify which module you want to have "play" this track. 
	# 
	# the only real requirement for a musician object is
	# that it define a 'make_bar' method.  ideally that should
	# return POE::Framework::MIDI::Bar( { number => $barnum } );
	# or a ::Phrase( { number => $barnum } );
	
	package => 'POE::Framework::MIDI::Musician::YourCustomModule',
	
	channel => 1,
	patch => '77',
},
{
	name => 'ian',
	package => 'POE::Framework::MIDI::Musician::YourCustomModule',
	channel => 2,
	patch => '60',
},
{
	name => 'ike',
	package => 'POE::Framework::MIDI::Musician::YourCustomModule',
	channel => 3,
	patch => '88',
},
{
	name => 'ainsley',
	package => 'POE::Framework::MIDI::Musician::YourCustomModule',
	channel => 4,
	patch => '86',
},
{
	name => 'ahmet',
	package => 'POE::Framework::MIDI::Musician::YourCustomModule',
	channel => 5,
	patch => '80',
}

],
} ); 

$poe_kernel->run;