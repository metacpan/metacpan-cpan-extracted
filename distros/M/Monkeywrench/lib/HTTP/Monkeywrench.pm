# HTTP::Monkeywrench.pm
# ---------------------------------------------------------
# $Revision: 1.13 $
# $Date: 2000/09/12 00:14:54 $
# ---------------------------------------------------------

=head1 NAME

HTTP::Monkeywrench - Web testing application

=head1 SYNOPSIS

  use HTTP::Monkeywrench;
   $session = [
     {
     name  =E<gt> 'URL Name',
     url   =E<gt> 'http://url',
     }
   ];
   HTTP::Monkeywrench-E<gt>test($session);

=head1 REQUIRES

 CGI
 Net::SMTP
 HTTP::Cookies
 LWP::UserAgent
 Time::HiRes
 Data::Dumper

=cut

=head1 EXPORTS

None

=head1 DESCRIPTION

HTTP::Monkeywrench is a test-harness application to test the integrity
of a user's path through a web site.

To run HTTP::Monkeywrench-E<gt>test(), first set up a Perl script that contains
sessions (described below), settings if desired (also described below),
and a call to HTTP::Monkeywrench-E<gt>test(), passing it the settings hashref first, 
followed by the desired session hashrefs you want to test.
HTTP::Monkeywrench-E<gt>test($settings, $session1,... $sessionN)

HTTP::Monkeywrench can also be used in an object-oriented fashion -- simply
take the result of HTTP::Monkeywrench-E<gt>new (optionally passing the settings
hashref) and call the test() method against it as above (optionally omitting
the settings hashref.)

Each session arrayref contains one or more hashrefs, called clicks,  
which contain descriptive elements of a specific web page to be tested. 
The elements are described below under SESSION.

=head1 SESSION

=over 4

=item C<$session1> (ARRAYREF of HASHREFS)

A session is an arrayref of complex hashrefs that can be sent to the
C<HTTP::Monkeywrench-E<gt>test> application to perform tests on a website
as a virtual user.

The following keys can be in each 'Click' hashref. 
Fields with a "*" are required:

=back

=over 8

=item name (SCALAR)

A name to visually reference that 'click' in the reports

=item *url (SCALAR)

The url for Monkeywrench to test for that click.

=item params (HASHREF)

The params to send to dynamic pages and cgi's.
Params should be set up as such: { username => 'joe', password => 'blow' }

=item method (SCALAR)

'method' should be either 'POST' or 'GET'. If method is left
blank, method will default to 'GET'.

=item auth (ARRAYREF)

'auth' is the username and password if the site your are testing
is password protected. 'auth' params must be passed to each
element of a session that is accessing the same site.
Example: ['username','password']

=item success_res (ARRAYREF)

An arrayref of items for Monkeywrench to test for their existence.
Each element of the array can either be a text string or a regexp object.
If a string from success_res is not found in the page, Monkeywrench
will report an error.
EXAMPLE: ['string',qr/regexp_object/,'etc']

=item error_res (ARRAYREF)

The same as success_res, except that an error will only be reported
if strings in error_res ARE found on the page being tested.

=item cookies (ARRAYREF of ARRAYREFS)

A preset cookie can be sent to a page. In order to send a cookie to
a page the following elements should be included as an arrayref:

[$version, $key, $val, $path, $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest]

An example cookie would look like:

[['0', 'sessnum', 'expires&2592000&type&consumer', '/','cookiemonster.org', '8014', '', '', '2000-09-11 16:15:15Z', '']],

=item acceptcookie (BIT)

A numeric flag set to 1 or 0 to tell Monkeywrench if it should accept and
save a cookie passed from a server.
Default is 0, cookies will not be accepted.

=item sendcookie (BIT)

A numeric flag set to 1 or 0 to tell Monkeywrench to send a saved or
pre made cookie back to the server. Default is 0, cookies will not be sent.

=item showhtml (BIT)

A numeric flag set to 1 or 0 to have the source html of a page displayed
within the report. When set to 1 the reports can get messy if the page
is heavy on html.

=back

=head1 SETTINGS HASH

=over 4

=item $settings (HASHREF)

The settings hash is optional as are each of the elements of $settings.
Elements that are not declared or set are defaulted to 0 (off).

=back

=over 8

=item match_detail (BIT)

A numeric flag set to 1 or 0. If set to 1 Match detail shows all of
the reports of success_res and error_res no matter if they pass or fail.

=item show_cookies (BIT)

A numeric flag set to 1 or 0. If set to 1 show_cookies will show all
the cookies in the report, either passed from the session or sent
from the server.

=item smtp_server (SCALAR)

The SMTP server to be used by Net::SMTP. Only required if user wants
output of Monkeywrench to be sent to an email address.

=item send_mail (ARRAYREF)

The send_mail arrayref is also only required if user plans on sending
output to one or more email addresses.

=item send_if_err (BIT)

The send_if_err bit is a flag that should be set to either 1 or 0 and
is only used if the user wants the Monkeywrench output sent via email.
If set to 1 the output will only be sent to the email address(es) in
the event of a failure in the success or error checking or any result
code other than 200.

=item print_results (BIT)

If set to 1, the results will be printed to the screen. If set to 0 nothing
will be printed to the screen. The default setting is 1.


=back

=cut

=head1 METHODS

=over 4

=cut

package HTTP::Monkeywrench;

use strict;
use vars qw($totaltime $totalerrs @sessiontime $debug $default_settings $content);

use CGI;
use Net::SMTP;
use HTTP::Cookies;
use LWP::UserAgent;
#use LWP::Debug qw(+); # spits out a lot of helpful LWP debugging

use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper; # also used for debugging purposes

BEGIN {
	$HTTP::Monkeywrench::REVISION	= (qw$Revision: 1.13 $)[-1];
	$HTTP::Monkeywrench::VERSION	= '1.0';

	$CGI::NO_DEBUG	= 1; # again, debugging
	$debug			= undef; # set to 1 if you want to see debugging output
	$default_settings = {
			match_detail	=> 1,
			show_cookies	=> 1,
			smtp_server		=> undef,
			send_mail		=> undef,
			send_if_err		=> 0,
			print_results	=> 1
	};
}

$totalerrs = 0; # initialize the total errors string

=item C<new> ( [ \%settings ] )

Returns a new Monkeywrench object.  Optionally takes a settings hash.

=cut
sub new {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $self	= bless({}, $class);
	$self->settings(shift);
	$self->{'ua'} = new LWP::UserAgent;
	$self->{'ua'}->agent('Monkeywrench/'.$HTTP::Monkeywrench::VERSION . $self->{'ua'}->agent);
	$self->{'cookie_jar'} = HTTP::Cookies->new;
	$self->{'cgi'} = CGI->new('');
	return $self;
} # END method new

=item C<settings> ( $self, [ \%settings ] )

Returns settings hash.  Passing hashref will change settings in object.

=cut
sub settings {
	my $self = shift;
	return undef unless (ref $self);
	if (my $settings = shift) {
		warn "SETTINGS ==> " . Dumper($settings) if ($debug);
		unless (ref($settings) eq 'HASH') {
			carp('Settings must be called with hashref...\n');
			return undef;
		}

		$self->{'settings'} = {
			map { $_ => defined($settings->{$_}) ? $settings->{$_} : $default_settings->{$_} } 
			keys %$default_settings };
	}
	
	return $self->{'settings'};
} # END method settings
	
sub ua			{ $_[0]->{'ua'}; }
sub cookie_jar 	{ $_[0]->{'cookie_jar'}; }
sub cgi			{ $_[0]->{'cgi'}; }

=item C<test> ( [ \%settings ], \@session [ , \@session, ... ] )

Usable as both a static method and object method.
Runs a series Monkeywrench tests on a web server using the parameters set forth in the
sessions you pass.

=cut
sub test {
	my $self		= shift;
	unless (ref($self)) {
		$self = $self->new(ref($_[0]) eq 'HASH' ? shift : ());
	}
	#my $settings	= $self->settings((ref($_[0]) eq 'HASH') && shift);
	my @sessions	= @_;
	my $q			= $self->cgi();
	my $sessnum 	= 0;
	my $return		= {};
	my $res;

	$content .= sprintf("============================== Monkeywrench %.2f ==============================\n",($HTTP::Monkeywrench::REVISION));

	foreach my $session (@sessions) {
		$content .= "Session $sessnum\n";
		my $clicknum = 0;
		foreach (@$session) {
			my $click = { %$_ };	# Make a copy so we don't stomp on the original
			$click->{'params'}		= join('&', map{ $q->escape($_) . '=' . $q->escape($click->{'params'}{$_} )   } keys %{$click->{'params'}} );
			$click->{'method'}		= $click->{'method'} ? $click->{'method'} : 'GET';
			$click->{'showhtml'}	= $click->{'showhtml'} || 0;
			push(@{ $click->{'urls'} },$click->{'url'});
			
			if ($click->{'cookies'}) {
				foreach my $cookie (@{ $click->{'cookies'} }) {
					$self->cookie_jar->set_cookie(@$cookie);
				}
			}

			my $t1 = [ gettimeofday ];
			$res = $self->get_response($click);
			$return->{ session }[ $sessnum ][ $clicknum ]{ res } = $res->code;
			my $t2  = [ gettimeofday ];
			
			$content .= " Summary for: " . $click->{'name'} . "\n";
			my $r = 1;
			foreach my $url (@{ $click->{'urls'} }) {
				$content .= scalar (($r==1) ? '         URL: ' : '    Redirect: ') . "$url\n";
				$r++;
			}
			if (($click->{'sendcookie'}) && ($self->settings->{'show_cookies'})) {
				my $cookie_to_print = $self->cookie_jar->as_string;
				$~ = "COOKIES";
				write;
				format COOKIES =
      Cookie: 
~~            ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
              $cookie_to_print
.
			}
			my $failed = 0;
			my $success = 0;

			$content .= '        Code: ' . $res->code . ' ' . $res->message . "\n";
			if ($res->is_redirect || $res->is_success) {
				$content .= "   Match Res:\n" if ($click->{'success_res'});
				foreach my $sr (@{ $click->{'success_res'} }) {
					my $result;
					if ($res->content =~ $sr) {
						$result = "PASS" if ($self->settings->{'match_detail'});
					} else {
						$result = "FAIL";
						$failed++;
						$totalerrs++;
					}
					pipe (RFH,WFH);
					format WFH =
              ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>
              $sr,                                                      $result
.
					write WFH if ($result);
					close WFH;
					local $/ = undef;
					$content .= <RFH>;
				}
				
				$content .= " Match Error:\n" if ($click->{'error_res'});
				foreach my $er (@{ $click->{'error_res'} }) {
					my $result;
					if ($res->content =~ $er) {
						$result = "FAIL";
						$failed++;
						$totalerrs++;
					} else {
						$result = "PASS" if ($self->settings->{'match_detail'});
					}
					pipe (ERR_RFH,ERR_WFH);
					format ERR_WFH =
              ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>
              $er,                                                      $result
.
					write ERR_WFH if ($result);
					close ERR_WFH;
					local $/ = undef;
					$content .= <ERR_RFH>;
				}	
				
			} else {
			    $content .= "              *** Request Failed ***\n"; #. $res->error_as_HTML;
			}

			$return->{ session }[ $sessnum ][ $clicknum ]{ clicktime } = my $clicktime = tv_interval($t1,$t2);
			$totaltime += $clicktime;
			$return->{ session }[ $sessnum ][ $clicknum ]{ sessiontime } = $sessiontime[$sessnum] += $clicktime;
			$content .= "\n   Pageclick: $clicktime second\n"; # must kill clicktime nazis
			$content .= "-------------------------------------------------------------------------------\n";
			$clicknum++;
		}
		
		$content .= "   Session $sessnum: $sessiontime[$sessnum]\n";
		$content .= "===============================================================================\n";
		$sessnum++;
	}
	
	$content .= "Total Errors: $totalerrs\n";
	$content .= "  Total Test: $totaltime seconds\n\n";
	$return->{ totaltime } = $totaltime;
	
	if ($self->settings->{'send_mail'}) {
		if (($self->settings->{'send_if_err'} == 0) ||
			(($self->settings->{'send_if_err'} == 1) && ((($res->code != 200) || ($totalerrs > 0))))) {
				$self->send_monkeymail($content,$self->settings->{'smtp_server'},$self->settings->{'send_mail'})
					|| warn "Unable to send monkeymail";
		}
	}
	print $content if $self->settings->{'print_results'};
	return $return;
} # end method test


=item C<get_response> ($click)

get_response is a recursive method that loops through all
possible redirects until a final response is returned,
which is then returned to the caller.

=cut
sub get_response {
	my $self	= shift;
	my $click	= shift;
	my $method	= ($click->{'REDIRECT'} ? 'GET' : $click->{'method'});
	my $req 	= HTTP::Request->new($method => $click->{'urls'}->[-1] . (($method eq 'GET') ? '?'.$click->{'params'} : ''));
	
	$req->authorization_basic($click->{'auth'}->[0], $click->{'auth'}->[1]) if ($click->{'auth'});
	$req->content($click->{'params'}) unless ($click->{'REDIRECT'});
    $self->cookie_jar->add_cookie_header($req) if ($click->{'sendcookie'});
	
	$content .= "\$req ==> " . Dumper($req) if ($debug);

	my $res = $self->ua->request($req);
	
	$content .= "\$res ==> " . Dumper($res) if ($debug);
	$content .= "RESPONSE ==> " . $res->content . "\n" if ($click->{'showhtml'});

	$self->cookie_jar->extract_cookies($res) if ($click->{'acceptcookie'});

	if ($res->is_redirect) {
		$click->{'REDIRECT'} = 1;
		push(@{ $click->{'urls'} },$res->header('Location'));
		return $self->get_response($click)
	} else {
		return $res;
	}
} # end method get_response


=item C<send_monkeymail> ( $content, \$smtp_server \@address )

send_monkeymail is called if the config script has an
email address and depending on how send_if_err is setup.
$content is the output of the session(s) called by the
config script and the \@address arrayref contains the
address(es) that the output will be sent to. $smtp_server
is the smtp server for Net::SMTP to connect to and is also
required in order for send_monkeymail to be called.

=cut
sub send_monkeymail {
	my $self = shift;
	my $content = shift || 'ERROR: NO OUTPUT';
	my $smtp_server = shift || return undef;
	my $address = shift || return undef;
		
	my $smtp = Net::SMTP->new($smtp_server) || return undef;
	$smtp->mail($ENV{'USER'});
	$smtp->to(@{$address});

	$smtp->data();
	$smtp->datasend("From: " . $ENV{'USER'} . "\n");
	$smtp->datasend("To: @{$address}\n");
	$smtp->datasend("Subject: Monkeywrench Output\n");
	$smtp->datasend( "\n" . $content );
	$smtp->dataend();
	
	$smtp->quit;
}


1;

__END__

=back

=head1 REVISION HISTORY
 $Log: Monkeywrench.pm,v $
 Revision 1.13  2000/09/12 00:14:54  david
 More POD fixes.

 Revision 1.12  2000/09/08 01:40:23  greg
 removed C<> surrounding SYNOPSIS as it was breaking pod2html.

 Revision 1.10  2000/09/08 01:01:10  greg
 fixed POD

 Revision 1.9  2000/09/08 00:37:49  david
  - Moved and rearranged some POD.

 Revision 1.8  2000/09/07 22:26:26  derek
  - Removed _init method and incoporated code into new method.
  - Added a return obj that is populated during the test method and is returned
    at the end of the test method.
  - Other misc code changes for efficiency and readability.
  - Fixed minor POD problems and added documentation for new settings.

 Revision 1.7  2000/09/06 21:49:35  david
  - Changed POD formatting (looks better in a POD reader, not in an editor.)
  - added some extra sanity to send_monkeymail()

 Revision 1.6  2000/09/01 23:10:51  derek
  - Documentation fixes, additions.

 Revision 1.5  2000/08/23 21:25:37  derek
  - Added send_monkeymail method to handle sending reports via email.
  - Modified test method to put all output data into $content variable instead
    of printing each chunk separately.
  - Added documentation for send_monkeymail method, new oop features, and new
    settings options for the config files.

 Revision 1.4  2000/08/03 01:03:34  david
  now uses strict (no change required)
 OO enhancements
  - initialization portion of test() method moved to methods new(), _init(),
    and settings(), test() works as an object method, but still works as a
    static method. Objects are reusable (you can call test any number of times.)
  - settings(), cgi(), cookie_jar(), and ua() access methods set up to make
    more extensible

 Revision 1.3  2000/02/28 23:52:07  derek
  - Added and changed lots of POD
  - Added new report element, Code, to display the response code of the page

 Revision 1.2  2000/02/18 03:36:18  derek
  - Fixed logic problem in reading the settings from what user passes
  - Fixed minor display issue

 Revision 1.1.1.1  2000/02/17 21:04:05  derek
  - Start


=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

None

=head1 TODO

=over 4

=item * B<Recorder Utility>

=item * B<Recorder Utility> - Currently, scenarios must be created painstakenly
by editing complex conf files.  A better solution would be a CGI or
mod_perl handler which 'watches' you surf a site and creates the 
configuration script for you.

=item * B<Link checking ability>
(checks integrity of all links on the pages it checks)

=item * B<HTML checking> - Checks the HTML on pages for HTML compliance
(you can optionally specify the HTML w3c spec you want to comply to). 
We might integrate WebLINT or other packages which do this 
(they may even check links).  

=item * B<Load Testing> - Most load testing tools hit one page over and over
measuring how many simultaneous requests per second a site can handle.
This approach is highly flawed since it does not approximate true traffic
on your site where lots of people might be performing different actions
on your site at the same time (not just pounding one page.)  Monkeywrench
is well suited to being a true load testing tool where multiple sessions, 
mimicking actual users doing lots of different things on your site, are run 
simultaneously to see how many requests a second your site can handle under
more realistic conditions.  We envision adding a client server componant
to the load balancing tool that would let you run Monkeywrench clients
on lots of machines all hitting the same site.  Then a Monkeywrench server
would collect and report on the results.  

=item *	B<Configuration> - Currently, the test scenarios reside in
configuration scripts which you run directly.  It would be better if the
configuration information was separated from the script which reads and runs
the configuration information.  One idea is to store configuration/session info
into XML files which you could just pass to Monkeywrench at the command line.
		
=item * Write more, longer TODOs.

=back

=head1 COPYRIGHT

Copyright (c) 2000, Cnation Inc. All Rights Reserved. This program is free
software; you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


=head1 AUTHORS

 Derek Cline 	<derek@cnation.com>
 Adam Pisoni	<adam@cnation.com>
 David Pisoni	<david@cnation.com>

=cut
