package Net::EPP::Frame;
use Carp;
use Net::EPP::Frame::Command;
use Net::EPP::Frame::Greeting;
use Net::EPP::Frame::Hello;
use Net::EPP::Frame::ObjectSpec;
use Net::EPP::Frame::Response;
use POSIX qw(strftime);
use XML::LibXML;
use base qw(XML::LibXML::Document);
use vars qw($EPP_URN $SCHEMA_URI);
use strict;

our $EPP_URN	= 'urn:ietf:params:xml:ns:epp-1.0';
our $SCHEMA_URI	= 'http://www.w3.org/2001/XMLSchema-instance';

=pod

=head1 NAME

Net::EPP::Frame - An EPP XML frame system built on top of L<XML::LibXML>.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use Net::EPP::Client;
	use Net::EPP::Frame;
	use Net::EPP::ObjectSpec;
	use Digest::MD5 qw(md5_hex);
	use Time::HiRes qw(time);
	use strict;

	#
	# establish a connection to an EPP server:
	#
	my $epp = Net::EPP::Client->new(
		host	=> 'epp.registry.tld',
		port	=> 700,
		ssl	=> 1,
		dom	=> 1,
	);

	my $greeting = $epp->connect;

	#
	# log in:
	#
	my $login = Net::EPP::Frame::Command::Login->new;

	$login->clID->appendText($userid);
	$login->pw->appendText($passwd);

	#
	# set the client transaction ID:
	#
	$login->clTRID->appendText(md5_hex(Time::HiRes::time().$$));

	#
	# check the response from the log in:
	#
	my $answer = $epp->request($login);

	my $result = ($answer->getElementsByTagName('result'))[0];
	if ($result->getAttribute('code') != 1000) {
		die("Login failed!");
	}

	#
	# OK, let's do a domain name check:
	#
	my $check = Net::EPP::Frame::Command::Check->new;

	#
	# get the spec from L<Net::EPP::Frame::ObjectSpec>:
	#
	my @spec = Net::EPP::Frame::ObjectSpec->spec('domain');

	#
	# create a domain object using the spec:
	#
	my $domain = $check->addObject(@spec);

	#
	# set the domain name we want to check:
	#
	my $name = $check->createElement('domain:name');
	$name->appendText('example.tld');

	#
	# set the client transaction ID:
	#
	$check->clTRID->appendText(md5_hex(time().$$));

	#
	# assemble the frame:
	#
	$domain->addChild($name);

	#
	# send the request:
	#
	my $answer = $epp->request($check);

	# and so on...

=head1 DESCRIPTION

The Extensible Provisioning Protocol (EPP) uses XML documents called "frames"
send data to and from clients and servers.

This module implements a subclass of the L<XML::LibXML::Document> module that
simplifies the process of creation of these frames. It is designed to be used
alongside the L<Net::EPP::Client> module, but could also be used on the server
side.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>


=head1 USAGE

As a rule, you will not need to create C<Net::EPP::Frame> objects directly.
Instead, you should use one of the subclasses included with the distribution.
The subclasses all inherit from C<Net::EPP::Frame>.

C<Net::EPP::Frame> is itself a subclass of L<XML::LibXML::Document> so all the
methods available from that class are also available to instances of
C<Net::EPP::Frame>.

The available subclasses of C<Net::EPP::Frame> exist to add any additional
elements required by the EPP specification. For example, the E<lt>loginE<gt>
frame must contain the E<lt>clIDE<gt> and E<lt>pwE<gt> frames, so when you
create a new L<Net::EPP::Frame::Command::Login> object, you get these already
defined.

These classes also have convenience methods, so for the above example, you can
call the C<$login-E<gt>clID> and C<$login-E<gt>pw> methods to get the
L<XML::LibXML::Node> objects correesponding to those elements.

=head2 RATIONALE

You could just as easily construct your EPP frames from templates or just lots
of C<printf()> calls. But using a programmatic approach such as this strongly
couples the validity of your XML to the validity of your program. If the
process by which your XML is built is broken, I<your program won't run>. This
has to be a win.

=cut

sub new {
	my ($package, $type) = @_;

	if (!$type) {
		my @parts = split(/::/, $package);
		$type = lc(pop(@parts));
	}

	if ($type !~ /^(hello|greeting|command|response)$/) {
		croak("'type' parameter to Net::EPP::Frame::new() must be one of: hello, greeting, command, response ('$type' given).");
		return undef;
	}

	my $self = $package->SUPER::new('1.0', 'UTF-8');
	bless($self, $package);

	my $epp = $self->createElementNS($EPP_URN, 'epp');
	$self->addChild($epp);

	my $el = $self->createElement($type);
	$epp->addChild($el);

	$self->_addExtraElements;

	return $self;
}

sub _addExtraElements {
}

=pod

=head1 ADDITIONAL METHODS

	my $str = $frame->formatTimeStamp($timestamp);

This method returns a scalar in the required format (defined in RFC 3339). This
is a convenience method.

=cut

sub formatTimeStamp {
	my ($self, $stamp) = @_;
	return strftime('%Y-%m-%dT%H:%M:%S.0Z', gmtime($stamp));
}

=pod

	my $node = $frame->getNode($id);
	my $node = $frame->getNode($ns, $id);

This is another convenience method. It uses C<$id> with the
I<getElementsByTagName()> method to get a list of nodes with that element name,
and simply returns the first L<XML::LibXML::Element> from the list.

If C<$ns> is provided, then I<getElementsByTagNameNS()> is used.

=cut

sub getNode {
	my ($self, @args) = @_;
	if (scalar(@args) == 2) {
		return ($self->getElementsByTagNameNS(@args))[0];

	} elsif (scalar(@args) == 1) {
		return ($self->getElementsByTagName($args[0]))[0];

	} else {
		croak('Invalid number of arguments to getNode()');

	}
}

=pod

	my $binary = $frame->header;

Returns a scalar containing the frame length packed into binary. This is
only useful for low-level protocol stuff.

=cut

sub header {
	my $self = shift;
	return pack('N', length($self->toString) + 4);
}

=pod

	my $data = $frame->frame;

Returns a scalar containing the frame header (see the I<header()> method
above) concatenated with the XML frame itself. This is only useful for
low-level protocol stuff.

=cut

sub frame {
	my $self = shift;
	return $self->header.$self->toString;
}

=pod

=head1 AVAILABLE SUBCLASSES

=over

=item * L<Net::EPP::Frame>, the base class

=item * L<Net::EPP::Frame::Command>, for EPP client command frames

=item * L<Net::EPP::Frame::Command::Check>, for EPP E<lt>checkE<gt> client commands

=item * L<Net::EPP::Frame::Command::Create>, for EPP E<lt>createE<gt> client commands

=item * L<Net::EPP::Frame::Command::Delete>, for EPP E<lt>deleteE<gt> client commands

=item * L<Net::EPP::Frame::Command::Info>, for EPP E<lt>infoE<gt> client commands

=item * L<Net::EPP::Frame::Command::Login>, for EPP E<lt>loginE<gt> client commands

=item * L<Net::EPP::Frame::Command::Logout>, for EPP E<lt>logoutE<gt> client commands

=item * L<Net::EPP::Frame::Command::Poll>, for EPP E<lt>pollE<gt> client commands

=item * L<Net::EPP::Frame::Command::Renew>, for EPP E<lt>renewE<gt> client commands

=item * L<Net::EPP::Frame::Command::Transfer>, for EPP E<lt>transferE<gt> client commands

=item * L<Net::EPP::Frame::Command::Update>, for E<lt>updateE<gt> client commands

=item * L<Net::EPP::Frame::Greeting>, for EPP server greetings

=item * L<Net::EPP::Frame::Hello>, for EPP client greetings

=item * L<Net::EPP::Frame::Response>, for EPP server response frames

=back

Each subclass has its own subclasses for various objects, for example L<Net::EPP::Frame::Command::Check::Domain> creates a C<E<lt>checkE<gt>> frame for domain names.

Coverage for all combinations of command and object type is not complete, but work is ongoing.

=cut

1;
