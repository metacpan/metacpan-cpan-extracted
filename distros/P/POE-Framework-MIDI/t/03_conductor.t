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
	use_ok('POE::Framework::MIDI::Conductor');
	use_ok('POE::Framework::MIDI::Note');
	use_ok('POE::Framework::MIDI::Rest');
	use_ok('POE::Framework::MIDI::Bar');

}

ok(my $config = {
	bars      => 4,
    filename  => 'example1-output.mid',
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
    ],

});

ok(my $conductor = new POE::Framework::MIDI::Conductor($config));
ok(my $musician_names = $conductor->musician_names);
ok(my $bar = POE::Framework::MIDI::Bar->new);
ok($bar->add_event(POE::Framework::MIDI::Note->new( name => 'C3', duration => 'wm')));
ok($conductor->add_bar( { musician_name => 'frank', barnum => 2, bar => $bar }));
ok($bars = $conductor->bars, 'Bars');
ok($conductor->perl_from_event( 
	event => POE::Framework::MIDI::Note->new( 
		name => 'C3', 
		duration => 'wm'), 
		musician_name => 'frank', ),'Perl from event');
ok($conductor->perl_head);

SKIP: {

	skip 1, 'P:F:M:Musician interface not upgraded yet';
	ok(my $musician = POE::Framework::MIDI::Musician->new('config data here')); 

	skip(1,'Query strings not supported yet');
	ok($conductor->query('some query string')); 

	skip (1,'subroutine header requires a musician object - not done yet');
	ok($conductor->musician_subroutine_header( 'data' ));
	
	skip(1,'Rendering support not done pending musician interface update');
	ok($conductor->render);
}



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
