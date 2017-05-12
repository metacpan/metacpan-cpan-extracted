#!/usr/bin/perl
use Net::AIML;
use POE::Component::Generic;
use IO::Prompt;
use POE;

my $bot = POE::Component::Generic->spawn(
    package        => 'Net::AIML',
	alias 		   => 'net-aiml',
    object_options => [ botid => a84468c2ae36697b ], # gir
    debug          => 0,
    verbose        => 1,
);

POE::Session->create(
    inline_states => {
        _start => sub { $poe_kernel->delay('input', 1) },
        
		input => sub { 
		    my $line = prompt "You: ";
		    $bot->tell( { event => 'output' } => $line );		
		},
		
        output  => sub {
		    my ( $data, $result ) = @_[ ARG0, ARG1 ];
		    print "Alice: $result\n";
		    $poe_kernel->delay('input', 1);
		},		
    },
);

$poe_kernel->run;