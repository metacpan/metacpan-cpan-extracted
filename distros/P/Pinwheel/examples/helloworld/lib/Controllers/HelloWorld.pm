package Controllers::HelloWorld;

use strict;
use warnings;

use Pinwheel::Context;
use Pinwheel::Controller;
use Pinwheel::Helpers qw(link_to);

our @ACTIONS = qw(index);
our @HELPERS = qw();

sub index
{
    return unless accepts('html');

    Pinwheel::Context::set('template',
       message => 'This is a message passed through from the controller.' 
    );
	
    respond_to(
        'html' => sub { render() },
    );
}

1;
