# Net::ICAP -- Internet Content Adapataion Protocol (rfc3507)
#
# (c) 2014, Arthur Corliss <corliss@digitalmages.com>
#
# $Revision: 0.04 $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Net::ICAP;

use 5.008003;

use strict;
use warnings;
use vars qw($VERSION);

($VERSION) = (q$Revision: 0.04 $ =~ /(\d+(?:\.(\d+))+)/s);

use Net::ICAP::Request;
use Net::ICAP::Response;

#####################################################################
#
# Net::ICAP code follows
#
#####################################################################

1;

__END__

=head1 NAME

Net::ICAP - Internet Content Adapataion Protocol (rfc3507)

=head1 VERSION

$Id: lib/Net/ICAP.pm, 0.04 2017/04/12 15:54:19 acorliss Exp $

=head1 SYNOPSIS

    use Net::ICAP;
    use Net::ICAP::Common qw(:all);

    my $request = Net::ICAP::Request->new(
        method  => ICAP_REQMOD,
        url     => $url,
        headers => {
            Host    => $host,
            Allow   => 204,
            },
        reqhdr  => $http_headers,
        body    => $http_body,
        );
    $request->generate($io_handle);

    my $response = new Net::ICAP::Response;
    $response->parse($io_handle);

=head1 DESCRIPTION

L<Net::ICAP> is a rough implementation of the Internet Content Adaptation
Protocol (ICAP) protocol as defined in RFC 3507.  The parser and generator are
rather crude, doing only the most basic of sanity checks on input.  It does,
however, provide some convenience functionality, such as automatic generation
of B<Encapsulated> headers based on internal state, along with the ability to
do chunked encoding for message body entities.

In its current incarnation it only implements a protocol parser and generator,
it does not include a working client at this time.  That will be including in
future versions.

All the modules use the L<Paranoid::Debug> framework to provide internal trace
messages to B<STDERR>.  The debug levels for these modules start at B<5> and
end at B<8>.

=head1 SUBROUTINES/METHODS

None.  This module will provide a working client in the future.  It currently
only provides the convenience of not having to load the L<Net::ICAP::Request>
and L<Net::ICAP::Response> modules explicitly.

=head1 DEPENDENCIES

=over

=item o L<Class::EHierarchy>

=item o L<Paranoid>

=back

=head1 BUGS AND LIMITATIONS 

Alpha software... use at your own risk.

=head1 SEE ALSO

=over

=item L<Net::ICAP::Common>

=item L<Net::ICAP::Message>

=item L<Net::ICAP::Request>

=item L<Net::ICAP::Response>

=item L<Net::ICAP::Server>

=back

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2014, Arthur Corliss (corliss@digitalmages.com)

