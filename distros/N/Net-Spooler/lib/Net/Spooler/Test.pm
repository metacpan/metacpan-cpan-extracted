# -*- perl -*-

require 5.004;
use strict;

package Net::Spooler::Test;

use Net::Daemon::Test ();
use Net::Spooler ();
use Symbol ();


$Net::Spooler::Test::VERSION = '0.01';
@Net::Spooler::Test::ISA = qw(Net::Spooler Net::Daemon::Test);


sub Options ($) {
    my $self = shift;
    my $options = $self->SUPER::Options();
    $options->{'timeout'} = {
	'template' => 'timeout=i',
	'description' => '--timeout <secs>        '
	    . "The server will die if the test takes longer\n"
	    . '                        than this number of seconds.'
	};
    $options;
}


sub Bind ($) {
    my $self = shift;
    $self->Net::Daemon::Test::Bind();
}


1;

