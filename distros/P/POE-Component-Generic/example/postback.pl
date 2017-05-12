#!/usr/bin/perl -w

use strict;

$|++;

# sub POE::Kernel::TRACE_DEFAULT () { 1 }

use POE;
use POE::Component::Generic;

my $obj = POE::Component::Generic->spawn(
	package => 'My::Package',
        alias   => 'my-object',
        debug	=> 1,
        verbose => 1,
        object_options => [ wait => 5, answer=>42 ],
                        # first argument of ->setup is a postback
        postbacks => { setup=>0 }
        
    );         

POE::Session->create(
    inline_states => {
        _start => sub {
            $poe_kernel->delay( 'first', 1);	# give child some time
        },

        # 'answer' is a postback
        first => sub {
            print "Setting a postback\n";
            $obj->setup( { event=>'setup_done' }, 'got_answer' );
        
            return;
        },
      
        setup_done => sub {
            print "Calling the postback\n";
            # This will cause the object to use our postback
            $obj->doit( {} );
        },
      
        # This is the postback.  Notice that ARG0 isn't the data hash
        # like a response.
        got_answer => sub {
            my( $answer ) = $_[ ARG0 ];

            print "$answer == 42\n";

            $obj->shutdown;          
        },
    }
);


$poe_kernel->run;
    


#############################################################
package My::Package;

use strict;


sub new
{
    my $package=shift;
    return bless { @_ }, $package;
}

sub setup
{
    my( $self, $coderef ) = @_;
    $self->{coderef} = $coderef;
    print "Coderef set\n";
}

sub doit
{
    my( $self ) = @_;
    print "Sleeping $self->{wait} seconds\n";
    sleep( $self->{wait} );
    print "Calling coderf\n";
    $self->{coderef}->( $self->{answer} );
    return;
}

