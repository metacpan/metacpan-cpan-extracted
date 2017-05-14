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
	use_ok('POE::Framework::MIDI::Bar');      
	use_ok('POE::Framework::MIDI::Conductor');      
	use_ok('POE::Framework::MIDI::Key');        
	use_ok('POE::Framework::MIDI::Musician');        
	use_ok('POE::Framework::MIDI::Musician::Generic');        
	use_ok('POE::Framework::MIDI::Musician::Test');        
	use_ok('POE::Framework::MIDI::Noop');        
	use_ok('POE::Framework::MIDI::Note');        
	use_ok('POE::Framework::MIDI::Phrase');        
	use_ok('POE::Framework::MIDI::POEConductor');        
	use_ok('POE::Framework::MIDI::POEMusician');        
	use_ok('POE::Framework::MIDI::Rest');        
	use_ok('POE::Framework::MIDI::Rule');        
	use_ok('POE::Framework::MIDI::Rule::MinimumNoteCount');        
	use_ok('POE::Framework::MIDI::Ruleset');        
	use_ok('POE::Framework::MIDI::Utility');
	use_ok('POE::Framework::MIDI');
	use_ok('POE::Framework::MIDI::Interval');
}

my $musician_config =  {
            name    => 'frank',		           
            package => 'MyTest',
            channel => 1,
            patch   => 10,
};   



###################
# Test Constructors
###################
ok(my $_musician = POE::Framework::MIDI::Musician->new($musician_config),'constructor test');
isa_ok($_musician, 'POE::Framework::MIDI::Musician');

# this object is used as a starter template to make musicians
#ok(my $_generic_musician = POE::Framework::MIDI::Musician::Generic->new($musician_config), 'generic musician constructor');
#isa_ok($_generic_musician, 'POE::Framework::MIDI::Musician::Generic');

my $_bar = POE::Framework::MIDI::Bar->new;
isa_ok($_bar,'POE::Framework::MIDI::Bar');      

my $_conductor = POE::Framework::MIDI::Conductor->new({ honk => 1 });
isa_ok($_conductor,'POE::Framework::MIDI::Conductor');      

my $_noop = POE::Framework::MIDI::Noop->new;      
isa_ok($_noop,'POE::Framework::MIDI::Noop');

my $_note = POE::Framework::MIDI::Note->new( name => C, duration => en);        
isa_ok($_note, 'POE::Framework::MIDI::Note'); 

my $key = POE::Framework::MIDI::Key->new( name => 'major' );
isa_ok($key,'POE::Framework::MIDI::Key');

my $_poeconductor = POE::Framework::MIDI::POEConductor->new( { honk => 1 });       
isa_ok($_poeconductor,'POE::Framework::MIDI::POEConductor'); 

my $_poemusician = POE::Framework::MIDI::POEMusician->new( { package => 'MyTest', name => 'fred', channel => 1 });       
isa_ok($_poemusician, 'POE::Framework::MIDI::POEMusician');        

my $_phrase = POE::Framework::MIDI::Phrase->new( { honk => 1 });
isa_ok($_phrase, 'POE::Framework::MIDI::Phrase');      

my $_rest = POE::Framework::MIDI::Rest->new;
isa_ok($_rest,'POE::Framework::MIDI::Rest'); 

my $_rule = POE::Framework::MIDI::Rule->new( context => 'event', type => 'test');        

isa_ok($_rule,'POE::Framework::MIDI::Rule'); 

my $_minimumnotecount = POE::Framework::MIDI::Rule::MinimumNoteCount->new( context => 'bar' );
isa_ok($_minimumnotecount,'POE::Framework::MIDI::Rule::MinimumNoteCount');

my $_ruleset = POE::Framework::MIDI::Ruleset->new( context => 'bar', type => 'test');  
isa_ok($_ruleset,'POE::Framework::MIDI::Ruleset');        

my $outfile = 'test-output.mid';

POE::Framework::MIDI::POEConductor->spawn({
    verbose   => 1,
    #debug 	  => 1,
    bars      => 4,
    filename  => $outfile,
    musicians => [
        {
            name    => 'frank',		
            # specify which module you want to have "play" this track. 
            # 
            # the only real requirement for a musician object is
            # that it define a 'make_bar' method.  ideally that should
            # return POE::Framework::MIDI::Bar( { number => $barnum } );		
            package => 'MyTest',
            channel => 1,
            patch   => 10,
           },
       {
            name    => 'ainsley',
            package => 'MyTest',
            channel => 2,
            patch   => 20,
        },
        {
            name    => 'ike',
            package => 'MyTest',
            channel => 3,
            patch   => 56,
        },
    ]
}); 

ok(defined $poe_kernel, 'POE seems to be working..');
# $poe_kernel is exported by POE
$poe_kernel->run;

#SKIP: {
#	skip 2, 'Musician interface not yet updated';
	#$poe_kernel->run;
	ok(-e $outfile, 'POE::Framework::MIDI seems to have created a midi file..');
	ok((stat($outfile))[7] > 300, "the MIDI file's size looks ok..");
#}

# cleanup
unlink($outfile);
############
# A musician used by the test script

package MyTest;
use POE::Framework::MIDI::Musician;
use POE::Framework::MIDI::Bar;
use POE::Framework::MIDI::Note;
use POE::Framework::MIDI::Rest;

use vars qw/@ISA/;
use base 'POE::Framework::MIDI::Musician';


sub new {
    my($self,$class) = ({},shift);
    $self->{cfg} = shift;
    bless($self,$class);
    return $self;
}

sub make_bar {
	my $self = shift;
	my $barnum = shift;

	# make a bar
	my $bar = new POE::Framework::MIDI::Bar(  number => $barnum  );
	# add some notes & rests 
	my $note1 = new POE::Framework::MIDI::Note( name => 'C', duration => 'sn' );
	my $note2 = new POE::Framework::MIDI::Note( name => 'D', duration => 'en' );
	my $rest1 = new POE::Framework::MIDI::Rest( duration => 'qn' );

	$bar->add_events(($note1,$rest1,$note1,$note2));  

	return $bar;
}

sub name
{
	my $self = shift;
	return $self->{cfg}->{name};
}

sub channel
{
	my $self = shift;
	return $self->{cfg}->{channel};
}

1;
