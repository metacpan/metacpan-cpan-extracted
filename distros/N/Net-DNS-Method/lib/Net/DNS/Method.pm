package Net::DNS::Method;

require 5.005_62;
use Carp;
use strict;
use warnings;
no strict 'refs';

use vars qw/$AUTOLOAD/;

use File::Find;

use constant NS_FAIL	=> 0x00;
use constant NS_OK	=> 0x01;
use constant NS_STOP	=> 0x02;
use constant NS_IGNORE 	=> 0x04;
use constant NS_SPLIT 	=> 0x08;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
		 NS_OK
		 NS_FAIL
		 NS_STOP
		 NS_IGNORE
		 NS_SPLIT
);

our $VERSION = '2.00';

sub new {
    croak 
	"Net::DNS::Method is meant as a base class. Do not use it directly.\n";
}

## The AUTOLOAD below, handles the creation of methods that are to be defined
## to answer for each known RR type in Net::DNS.

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;
    *$sub = sub { NS_FAIL; };
    goto &$sub;
}

## The call to ANY will cause all the methods to be created.

my @RR = ();

sub ANY { 
    my $self = shift;
    my $q = $_[0];
    my $ans = $_[1];

    unless (@RR) {
	find( { no_chdir => 1,
		wanted => sub {
		    my $file = m/(\w+)\.pm$/ && $1;
		    return undef 
			unless $File::Find::dir =~ m!Net/DNS[^\w]!;
		    push @RR, $file if $file;
		}
	    }, grep { -d } @INC);
    }

    my $ret = NS_FAIL;

    for my $r (@RR) {
	$ret |= $self->$r(@_);
    }

    if (!($ret & NS_OK)
	and $ans->header->rcode eq 'NOERROR')
    {
	$ans->header->rcode('NXDOMAIN');
    }

    return $ret;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::DNS::Method - Base class for Net::DNS::Server methods

=head1 SYNOPSIS

  use Net::DNS::Method;
  package Net::DNS::Method::Sample;

  our @ISA = qw( ... Net::DNS::Method ... );

  sub new { ... }
  sub A { ... }

=head1 DESCRIPTION

This is a base class to help in the creation of method classes for use
within the Net::DNS::Server package. This class provides specific methods
to do nothing to particular DNS questions. In general, this class consists
of a number of methods that are called like in the following example.

=over

=item C<-E<gt>A($q, $ans)>

This would be invoked by Net::DNS::Server upon the arrival of a query
of type 'A'.

=back

The method can check the question, passed as a Net::DNS::Qustion
object in C<$q>. Usually, the method will then modify the
Net::DNS::Packet object in C<$ans> to provide an answer.

Net::DNS::Server will call sequentially all of the registered
Net::DNS::Method::* objects for a given question. After this sequence
of calls ends, the response can be sent depending on what the methods
have requsted.

The return value of the method is given as an OR of the following
values.

=over

=item C<NS_IGNORE>

Requests that the current question be ignored.

=item C<NS_STOP>

Requests that no further objects be invoked.

=item C<NS_OK>

Indicates that the current method matched the question and presumably,
altered the answer. Control is passed to the next method in
sequence. After the last method is invoked, the answer will be sent to
the client unless C<NS_IGNORE> is returned by this or a later method.

=item C<NS_FAIL>

Indicates that the current method did not match the packet.

=item C<NS_SPLIT>

Indicates that the response must be splitted in individual answers and
sent accordingly. This is used for AXFR requests.

=back

There is one such method for each type of RR supported by
L<Net::DNS>. Additionally, the C<-E<gt>ANY> method is provided, which
calls all the defined RRs in succession.

=head2 EXPORT

NS_* constants used for the return values.

=head1 HISTORY

$Id: Method.pm,v 1.2 2002/10/23 04:43:58 lem Exp $

=over

=item 1.00  Wed Oct 11 10:43:05 2000

=over

=item *

original version; created by h2xs 1.20 with options -Xfn
Net::DNS::Method -v 1.00

=back

=item 1.10  Fri Oct 12 10:49:07 2000

=over

=item *

Added -E<gt>ANY to do the expected thing (ie, evoke all
the available data). Implementors might want to override
the supplied definition to be a bit more efficient.

=back

=item 1.20  Tue Nov  1 16:35:00 2000

=over

=item *
Modified -E<gt>AXFR so that the same thing that -E<gt>AXFR
happens by default.

=back

=item 1.21  Mon Nov 27 16:34:00 2000

=over

=item *

Added C<NS_SPLIT>.

=item *

-E<gt>AXFR does not work reliably, so 1.20 was undone.

=item *

-E<gt>ANY fixes the rcode depending on success/failure of the modules.

=back

=item 2.00  Tue Oct 22 13:36:00 2002
   
=over

=item *

Started work to prepare a public distribution

=back

=back

=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), Net::DNS(3), Net::DNS::Server(3), Net::DNS::Question(3),
Net::DNS::Packet(3).

=cut

