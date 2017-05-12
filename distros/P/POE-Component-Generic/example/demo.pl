#!/usr/bin/perl -w

use strict;

use POE;
use POE::Component::Generic;

my $obj = POE::Component::Generic->spawn(
	package => 'My::Package',
        alias   => 'my-object',
        debug	=> 0,
        object_options => [ ten => 10, answer=>42 ]
    );         

POE::Session->create(
    inline_states => {
      _start => sub {
          $poe_kernel->delay( 'first', 1);	# give child some time
      },

      # Almost direct object method
      first => sub {
          $obj->fetch( {event=>'got_ten'}, 'ten' );
          return;
      },
      
      # POE-style post to component
      got_ten => sub {
          my( $data, $ten ) = @_[ARG0, ARG1];

          print "$ten == 10\n";
          print "$data->{result}[0] == 10\n";
          
          $poe_kernel->post( 'my-object',
                             fetch => {event=>'got_answer'}, 'answer' );
      },
      
      # ->yield to the component object, showing off wantarray
      got_answer => sub {
          my( $data, $answer ) = @_[ARG0, ARG1];

          print "$answer == 42\n";
          print "$data->{result}[0] == 42\n";
          
          $obj->yield( all_keys => {event=>'the_keys', wantarray=>1} );
      },
      
      # ->call to the component object
      the_keys => sub {
          my( $data, @keys ) = @_[ ARG0, ARG1..$#_ ];
          
          print join ', ', @keys;
          print " == qw( ten answer )\n";
          
          $obj->call( badness => {event=>'yow'} );
      },
      
      # Show error reporting
      yow => sub {
          my( $data ) = @_[ ARG0 ];

          # $data->{result} eq undef
          print qq($data->{error} eq "KABLOUIE! at line ..."\n);

          $poe_kernel->post( 'my-object' => 'shutdown' );
      }
    },
    
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

sub fetch
{
    my( $self, $key ) = @_;
    warn "Returning $key";
    return $self->{$key};
}

sub all_keys
{
    my( $self ) = @_;
    return keys %$self;
}

sub badness
{
    die "KABLOUIE!";
}
