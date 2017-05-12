package Net::OpenID::Server::Standalone::Config;

use strict;
use warnings;

our $config;

=pod

=head1 NAME

  Net::OpenID::Server::Standalone::Config - configuration package for Nossa

=head1 SYNOPSIS

used internally by Net::OpenID::Server::Standalone. The only sub is:

=head2 get( @args )

follows your $config as a hash of hashes consequentially.

=head2 $config

used to store all your configuration like this:
     
  our $config = {
    #users stuff
    users => {
      # nickname is a key
      'the_your_nickname' => {
        # hashFunction from password, MD5 by default
        pass        => 'md5_base64 of your password',
        # OpenID URL
        url         => 'http://your.openid.url/',
        # function to recognise sites that you trust to be asking about your OpenID, you'd be asked about it otherwise.
        trust_root  => sub{
                            shift =~ m/(blogger\.com|cpan\.org|ccmixter\.org|stickr\.com|mychores\.co\.uk\/openid|qdos\.com
                                        |demand-openid\.rpxnow\.com|livejournal\.com|sourceforge\.net)\/?$/x;
                        },
        # http://openid.net/specs/openid-simple-registration-extension-1_0.html
        sre         => {
          'sreg.nickname'     => 'nickname_for_outside_world',
          'sreg.fullname'     => 'Your Fullname',
        },
      },
    },
    # Where to redirect in case of wrong login/pass or the wrong OpenID url
    setupUrl => '/setup',
    # your id script URL
    idSvrUrl => '/id',
    # your OpenID server key
    serverSecret => 'some_random_sequence_put_your_own',
    # whether to redirect a user to the SSL URL of id
    requireSsl=> 0,
    # arguments for L<CGI::Session>
    session  =>  {
      dsn  =>"driver:DB_File;serializer:FreezeThaw",
      name  => 'nossa_cookie',
      expire  => '+1h',
    },
  };

=head1 ETCETERA

is at L<Net::Server::OpenID::Standalone>.

=cut

###  No user-serviceable part below this line ###

sub get{
  my $pkg = shift if ( $_[0] eq __PACKAGE__ ) or defined ref $_[0] ;
	no strict 'refs';
  my $rv = ${ *{ $pkg. '::' }->{ config } };
	use strict 'refs';
  if( @_ > 0 ){
    while( $_ = shift @_ ){
      if( defined $rv->{ $_ } ){
        $rv = $rv->{ $_ };
      } else {
        $rv = undef;
        last;
      }
    }
  }
  return $rv;
}

1;
