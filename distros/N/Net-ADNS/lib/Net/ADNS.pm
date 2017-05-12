package Net::ADNS;

use strict;
use warnings;

# code below goes inside a BEGIN block to make constants defined from
# XS available for the rest of the code
BEGIN {
    our $VERSION = '0.03';

    require XSLoader;
    XSLoader::load('Net::ADNS', $VERSION);
}

use Exporter 'import';
push our @EXPORT_OK, qw();

*new = \&init;

1;

__END__

=head1 NAME

Net::ADNS - Perl wrapper for the Asynchronous DNS client library

=head1 SYNOPSIS

  use Net::ADNS qw(ADNS_R_A ADNS_R_MX);

  $adns = Net::ADNS->new;

  use Data::Dumper;
  print Dumper $adns->synchronous("www.google.com", ADNS_R_A);

  my $query = $adns->submit("gmail.com", ADNS_R_MX);
  $query->{user} = 'my data';

  my ($r, $w, $e, $t) = $adns->before_select;

  if (select($r, $w, $e, $t)) {
    if (my $answer = $adns->check) {
      print "resolved query: ", Dumper $answer;
    }
  }

=head1 DESCRIPTION

From the adns library web site:

  ADNS: Advanced, easy to use, asynchronous-capable DNS client library
  and utilities.

  In contrast with the standard interfaces, gethostbyname et al and
  libresolv, it has the following features:

    - It is reasonably easy to use for simple programs which just want
      to translate names to addresses, look up MX records, etc.

    - It can be used in an asynchronous, non-blocking, manner. Many
      queries can be handled simultaneously.

    - Responses are decoded automatically into a natural
      representation - there is no need to deal with DNS packet
      formats.

    - Sanity checking (eg, name syntax checking, reverse/forward
      correspondence, CNAME pointing to CNAME) is performed
      automatically.

    - Time-to-live, CNAME and other similar information is returned in
      an easy-to-use form, without getting in the way.

    - There is no global state in the library; resolver state is an
      opaque data structure which the client creates explicitly. A
      program can have several instances of the resolver.

    - Errors are reported to the application in a way that
      distinguishes the various causes of failure properly.

    - Understands conventional resolv.conf, but this can overridden by
      environment variables.

    - Flexibility. For example, the application can tell adns to:
      ignore environment variables (for setuid programs), disable
      hostname syntax sanity checks to return arbitrary data, override
      or ignore resolv.conf in favour of supplied configuration, etc.

    - Believed to be correct! For example, will correctly back off to
      TCP in case of long replies or queries, or to other nameservers if
      several are available. It has sensible handling of bad responses
      etc.

=head2 CONSTANTS

All the constants defined on the C library can be imported from this
module (with uppercased names!):

  ADNS_IF_CHECKC_ENTEX, ADNS_IF_CHECKC_FREQ, ADNS_IF_DEBUG,
  ADNS_IF_EINTR, ADNS_IF_LOGPID, ADNS_IF_NOAUTOSYS, ADNS_IF_NOENV,
  ADNS_IF_NOERRPRINT, ADNS_IF_NONE, ADNS_IF_NOSERVERWARN,
  ADNS_IF_NOSIGPIPE

  ADNS_QF_CNAME_FORBID, ADNS_QF_CNAME_LOOSE, ADNS_QF_NONE,
  ADNS_QF_OWNER, ADNS_QF_QUOTEFAIL_CNAME, ADNS_QF_QUOTEOK_ANSHOST,
  ADNS_QF_QUOTEOK_CNAME, ADNS_QF_QUOTEOK_QUERY, ADNS_QF_SEARCH,
  ADNS_QF_USEVC,

  ADNS_RRT_TYPEMASK

  ADNS_R_A, ADNS_R_ADDR, ADNS_R_CNAME, ADNS_R_HINFO, ADNS_R_MX,
  ADNS_R_MX_RAW, ADNS_R_NONE, ADNS_R_NS, ADNS_R_NS_RAW, ADNS_R_PTR,
  ADNS_R_PTR_RAW, ADNS_R_RP, ADNS_R_RP_RAW, ADNS_R_SOA,
  ADNS_R_SOA_RAW, ADNS_R_SRV, ADNS_R_SRV_RAW, ADNS_R_TXT,
  ADNS_R_UNKNOWN

  ADNS_S_ALLSERVFAIL, ADNS_S_ANSWERDOMAININVALID,
  ADNS_S_ANSWERDOMAINTOOLONG, ADNS_S_INCONSISTENT, ADNS_S_INVALIDDATA,
  ADNS_S_INVALIDRESPONSE, ADNS_S_MAX_LOCALFAIL, ADNS_S_MAX_MISCONFIG,
  ADNS_S_MAX_MISQUERY, ADNS_S_MAX_PERMFAIL, ADNS_S_MAX_REMOTEFAIL,
  ADNS_S_MAX_TEMPFAIL, ADNS_S_NODATA, ADNS_S_NOMEMORY,
  ADNS_S_NORECURSE, ADNS_S_NXDOMAIN, ADNS_S_OK,
  ADNS_S_PROHIBITEDCNAME, ADNS_S_QUERYDOMAININVALID,
  ADNS_S_QUERYDOMAINTOOLONG, ADNS_S_QUERYDOMAINWRONG,
  ADNS_S_RCODEFORMATERROR, ADNS_S_RCODENOTIMPLEMENTED,
  ADNS_S_RCODEREFUSED, ADNS_S_RCODESERVFAIL, ADNS_S_RCODEUNKNOWN,
  ADNS_S_SYSTEMFAIL, ADNS_S_TIMEOUT, ADNS_S_UNKNOWNFORMAT,
  ADNS_S_UNKNOWNRRTYPE

  ADNS__QF_INTERNALMASK, ADNS__QTF_DEREF, ADNS__QTF_MAIL822


=head2 METHODS

The methods exposed from this package are as follows:

=over 4

=item Net::ADNS->init($flags, $cfg_string)

returns a new Net::ADNS object.

Both arguments are optional.

=item $adns->synchronous($owner, $type, $flags)

submits a DNS query, waits for the answer and returns it as a
hash. The C<$flags> argument is optional and defaults to 0.

Type has to be one of the ADNS_R_* constants.

For instance:

  $answer = $adns->synchronous('google.com', ADNS_R_A) or die "$!";

returns

  $answer = { owner => 'google.com',
              records => [ '72.14.207.99',
                           '64.233.167.99',
                           '64.233.187.99' ],
              status => 'OK',
              type => 'A' };

The status and type values are dual vars that render a numeric value
when used in numeric expresions. For instance, for the previous sample:

  $answer->{status} == ADNS_S_OK;
  $answer->{type} == ADNS_R_A;

=item $adns->submit($owner, $type, $flags)

submits a DNS query and returns an object representing it.

For instance:

  $query = $adns->submit('google.com', ADNS_R_A) or die "$!";

returns

  $query = bless { owner => 'google.com',
                   type => 'A' }, 'Net::ADNS::Query';

Custom data can be stored inside the C<%$query> hash. The use of the
keyword C<user> is recommended for this purpose (other keys could be
used by the library in the future):

  $query->{user} = "I store my script data here";


=item $adns->check()

=item $adns->check($query)

If the answer to the query is already available, adds its data to the
query object and returns it.

When a $query object is not passed as arguments, any pending one is
used.

Once, a positive response is obtained from this method, the $query
object becomes invalid and can not be used again as an argument for
any method call.

=item $adns->wait()

=item $adns->wait($query)

Similar to check but waits for the response to arrive or for the query
to timeout.

=item $adns->cancel($query)

Cancels a pending query.

=item $adns->open_queries()

Returns all the queries that have not been yet successfully waited,
checked or cancelled.

=item $adns->process()

Do IO, does not block.

Calling this method is usually not required, unless the
flag ADNS_IF_NOAUTOSYS is used on the constructor.

=item $adns->first_timeout()

Returns the time remaining until the first pending query times out.

=item ($read, $write, $excep, $timeout) = $adns->before_select()

Returns the fd_set vectors suitable for being passed to the select
call in order to combine Net::ADNS inside a select based loop.

For instance:

  my ($read, $write, $except, $timeout) = $adns->before_select;

  $read |= $other_read;
  $write |= $other_write;
  $except |= $other_except;

  $timeout = $other_timeout;
    if (!defined($timeout) or
        (defined($other_timeout) and $other_timeout < $timeout));

  if (select($read, $write, $except, $timeout)) {
    while (my $answer = $adns->check) {
      ...
    }
    ...
  }


=item $adns->after_select($read, $write, $excep)

Does IO using the fd_sets returned by a call to select.

Calling this method is usually not required.

=back

=head1 BUGS AND SUPPORT

This is a very early release, expect bugs on it.

To send bug reports, use the RT system at http://rt.cpan.org or send
my an email (or do both!).

Also, I visit L<PerlMonks|http://perlmonks.org/> almost daily and will
try to solve problems related to this module posted there.

=head1 SEE ALSO

The adns library L<web
site|http://www.chiark.greenend.org.uk/~ian/adns/> and the C header
file L<adns.h|http://www.chiark.greenend.org.uk/~ian/adns/adns.h.txt>.

There are other several DNS modules available from CPAN as for
instance L<Net::DNS>, L<POE::Component::Client::DNS> or
L<Net::DNS::Async>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Salvador FandiE<ntilde>o

Copyright (C) 2007 by Qindel Formacion y Servicios S.L.

The adns library is Copyright (C) 1997-2000, 2003, 2006 Ian Jackson;
Copyright (C) 1999-2000, 2003, 2006 Tony Finch; Copyright (C) 1991
Massachusetts Institute of Technology

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

=cut
