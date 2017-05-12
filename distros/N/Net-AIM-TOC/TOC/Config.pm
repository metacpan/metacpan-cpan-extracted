package Net::AIM::TOC::Config;

use strict;

use constant	DEBUG				=> 0;
use constant	REMOVE_HTML_TAGS	=> 1;

use constant	AUTH_SERVER	=> 'login.oscar.aol.com';
use constant	AUTH_PORT	=> 5159;
use constant	TOC_SERVER	=> 'toc.oscar.aol.com';
use constant	TOC_PORT	=> 9898;

use constant	AGENT		=> 'Net::AIM::TOC';

my $error_lookup = {
   901   => '%s not currently available',
   902   => 'Warning of %s not currently available',
   903   => 'A message has been dropped, you are exceeding the server speed limit',
#   * Chat Errors  *',
   950   => 'Chat in %s is unavailable.',

#   * IM & Info Errors *',
   960   => 'You are sending message too fast to %s',
   961   => 'You missed an im from %s because it was too big.',
   962   => 'You missed an im from %s because it was sent too fast.',
   
#   * Dir Errors *',
   970   => 'Failure',
   971   => 'Too many matches',
   972   => 'Need more qualifiers',
   973   => 'Dir service temporarily unavailable',
   974   => 'Email lookup restricted',
   975   => 'Keyword Ignored',
   976   => 'No Keywords',
   977   => 'Language not supported',
   978   => 'Country not supported',
   979   => 'Failure unknown %s',
   
#  * Auth errors *',
   980   => 'Incorrect nickname or password.',
   981   => 'The service is temporarily unavailable.',
   982   => 'Your warning level is currently too high to sign on.',
   983   => 'You have been connecting and disconnecting too frequently.  Wait 10 minutes and try again.  If you continue to try, you will need to wait even longer.',
   989   => 'An unknown signon error has occurred %s'
};


sub EVENT_ERROR_STRING {
	my $error = shift;
	my $extra = shift || undef;

	if( defined($error_lookup->{$error}) ) {
		if( defined($extra) ) {
			return( sprintf($error_lookup->{$error}, $extra) );
		}
		else {
			return( $error_lookup->{$error} );
		};
	}

	return( "Event error undefined: $error" );
};


1;

