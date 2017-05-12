package RAPNAP::client;

use strict;

use vars qw/$VERSION $key/;

$VERSION = '0.02';

use Socket;
my $eol = "\015\012";
sub rapnap_check{ # RA, PNA, optional Subject Line, optional Target Address
	my ($remote,$port, $iaddr, $paddr, $proto, $line);

        $remote  = 'www.pay2send.com';
        $port    = 80;  # http
        $iaddr   = inet_aton($remote)               || die "no host: $remote";
        $paddr   = sockaddr_in($port, $iaddr);
        $proto   = getprotobyname('tcp');
        socket(SOCK, PF_INET, SOCK_STREAM, $proto)  || die "socket: $!";
        connect(SOCK, $paddr)    || die "connect: $!";
	my $S = select SOCK;
	$| = 1;
	select $S;
	my $query="key=$key&ra=$_[0]&pna=$_[1]";
	$_[2] and $query .= "&sl=$_[2]";
	$_[3] and $query .= "&ta=$_[3]";
	$query =~ s/([^\w\.\=\&])/sprintf('%%%02X',ord($1))/ge;
# print "DEBUG: QUERY: $query\n\n";
	my $length = length $query;

	print SOCK join $eol,
		'POST /cgi/rapnap/check HTTP/1.1',
		'Host: www.pay2send.com',
		"User-Agent: RAPNAP::client $VERSION",
		# 'Transfer-Encoding:',
		'Connection: close',
		"Content-length: $length",
		'',
		$query,
		''
		;

	 my $response = join '', (<SOCK>);

# print "DEBUG: FULL RESPONSE:\n$response\nEND FULL RESPONSE\n\n";

	$response =~ m#Content-Type: \S+\s+([0-9a-fA-F]+)\s+(.+)#s;

	return substr($2,0,hex($1));

};



sub import{

	no strict 'refs';
	*{caller() . '::rapnap_check'} = \&rapnap_check;
	$key = $_[1] || 'ipv4';

};



1;
__END__

=head1 NAME

RAPNAP::client - perform a check against the RAPNAP database

=head1 SYNOPSIS

  use RAPNAP::client; # use default key, limited and accounted by IP
  # use RAPNAP::client 'AssignedKey'; # contact pay2send.com for a key
  ... # parse the headers of an e-mail or SMTP data block
  $RAPNAP_RESULT = rapnap_check($return_address,$peer_network_address,
     $subject_line,$target_recipient);
  if ($RAPNAP_RESULT =~ /> GOOD\b/){
	# continue delivering message
	...
  }else{
	# refuse or defer delivery
	...
  };

=head1 DESCRIPTION


RAPNAP::client provides a client for the pay2send.com RAPNAP
database, which is
a database of valid e-mail senders and the e-mail relays
that their e-mail originates from.

Pay2send.com  pursues a vision of e-mail that costs money
to send, except for whitelisted correspondents.  This client
module connects to http://pay2send.com/cgi/rapnap/check and
offers the RA ("Return Address") and PNA ("Peer Network Address")
specified as the first and second arguments to the <Crapnap_check()>
function which is exported by this module.

The rapnap_check() function takes two required and three optional arguments:

=over

=item ra

Return Address (in dotted quad form.  ipv6 addresses are not supported yet.)

=item pna

Peer Network Address

=item sl

Subject Line -- the subject line of the e-mail we are evaluating

=item ta

TArget -- to whom the e-mail we are evaluating is addressed

=item te

TEmplate -- the message template to use in the confirmation message

=back

and returns the text of the web page.  ra and pna are required to
get a response.  If a dns lookup on pna produces a name that does not
map back to the provided address, that is considered an error.

Subject Line and TArget are required to fill in the blanks in the
message template, and the rapnap checking routine will not send
e-mails unless they are provided.

TEmplate is parameterized so that you can compose your own message
template, following the example at
http://www.pay2send.com/rapnap/default_template.txt
and have messages sent to people because they are sending you or yours
mail from unlisted sources customized. Information about the
source of queries is provided in the e-mail headers, before the
template is streamed in.

By default, RAPNAP::client uses a pay2send account key of "ipv4"
which allows a limited number of accesses per day from an IP address.

See the http://www.pay2send.com web site for information on 
getting a pay2send RAPNAP client key which will allow more
accesses per day.

The rapnap_check function returns the text of the web page,
which will begin "error" is something went wrong, and
will match

	($RA2, $dnsname, $PNA2, $result, $count, $more) =
	($QueryResult = rapnap_check($RA, $PNA)) =~ 
	m/^(\S+) VIA (\S+) \[([\d\.]+)\] -> (UNKNOWN|GOOD|BAD) (\d+)(.*)/s;

otherwise, that is, if the query was syntacticly valid and the
network address was not mapped to a name that does not map back
to the same address.

There may be additional information after the restatement of
the query, the result, and the count of queries so far today,
for the provided key,
or $QueryResult might begin /^error / in which case something
went wrong, such as the RA containing a percent sign,
or being over the limit of queries.

When a sender has agreed to pay to send e-mail, the $more field
will contain information about this, in the form of text matching

	($USD_amount) = $more =~ /WILL_PAY (\d*\.?\d*) USD/;

At this time there is no concrete plan for the pay2send infrastructure
to work with currencies other than the United States Dollar.

=head2 EXPORT

the rapnap_check() function, described above, is exported.

=head2 BUGS AND GOALS

The to-do list includes:

=item cache

keep a cache of results, so we don't make redundant queries.

=item keepalive

support http/1.1 keepalive for use with RAPNAP clients that are
going to last longer than evaluating one message

=item http/1.1 cacheing support

use If-Modified-Since and a local cache of results.  Right now the
RAPNAP server doesn't issue etags, so this wouldn't help. Caching
the results from a particular RAPNAP for a day or so is a best practice,
at this time.

=item DNS-based RAPNAP checking

first we need to serve the RAPNAP database via DNS, which we aren't
doing yet.



=head1 HISTORY

=item 0.01

21 March 2003.  Written during the U.S. assault on Iraq.  Support
for HTTP/1.1 POST request with default key.

=item 0.02

15 April 2003.  Documented optional parameters, WILL PAY syntax.  Iraq
is secure.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2003 David Nicol / pay2send.com / Tipjar LLC
(I have a patent pending on using RAPNAP pairs for identity
verification stronger than available in SMTP return address
claims, which are trivially forged.)
 
this module is released GPL/AL: the same terms as Perl


=head1 SEE ALSO

http://www.pay2send.com

=cut
