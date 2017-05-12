package Net::SMS::Massenversand;
use warnings;
use strict;
use base "Class::Accessor::Fast";
use URI;
use URI::QueryParam;
use LWP::UserAgent;


__PACKAGE__->mk_accessors(qw(user test password msg_count error id));

=head1 NAME

Net::SMS::Massenversand - Send SMS via Massenversand.de

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Net::SMS::Massenversand;

    my $sms = Net::SMS::Massenversand->new();
    $sms->user('someuserid');
    $sms->password('somepassword');
    $sms->send(
    	type => "sms",
		message  => "Your SMS text",
		sender   => 'Your Name',
		recipient => '00123456789'
	  );
	my $limit = $sms->limit;


=head1 METHODS


=head2 new

Create a new object.

=head2 user

Sets the user id of your Massenversand.de account

=head2 password

Sets the password of your Massenversand.de account

=cut


sub new {
	my $class = shift;
	return bless( {}, $class );
}

=head2 limit

This method returns the credit which is left at your account.

Sets L</error> in case of an error.

=cut 

sub limit {
	my $self = shift;
	$self->_clear_object;
	my $response = $self->_get_response( getLimit => 1 );
	if ( $response->is_success ) {
		my $c = $response->content;
		return $c;
	} else {
		die $response->status_line;
	}
}

=head2 send

Sends the actual message. It is called with a hash which includes the necessary
information. This method expects a latin1 encoded string as message. Available parameters are:

=over

=item id

Defaults to C<< $sms->user >>

=item pw

Defaults to C<< $sms->password >>

=item receiver

Set the phone number of the receiver (international format starting with "00")

=item sender

11 alphanumerical or 16 numerical characters allowed. Allowed characters: a-z, A-Z and 0-9

=item message

The actual message you want to send. Mind that the maximum length of a sms is 160. If you
want to send more than 160 characters specify C<msgtype>.

=item msgtype

Specify the type of your sms message. Avaiable types are

=over

=item t: text SMS

=item f: flash SMS

=item b: blink SMS

=item c: longer-than-160-character SMS 
  
=back

Defaults to C<c>.

=back

After sending a sms you can access the sms-id which has been set by Massenversand.de
by calling L<< $sms->id >> and the number of messages your message was split into
L<< $sms->msg_count >>.

There are three Massenversand.de servers specified. If one fails the next one
is used. The timeout for a request is set to 15 seconds.

Returns 1 on success or 0 and sets L</error> in case of an error.

=cut


sub send {
	my $self     = shift(@_);
	my %param    = @_;
	$self->_clear_object;
	
	$param{message} = $param{message};
	
	my $response = $self->_get_response(
		receiver  => $param{receiver},
		sender    => $param{sender},
		msg   => $param{message},
		msgtype   => 'c',
		getID     => 1,
		countMsg  => 1,
		getStatus => 1
	);
	if ( $response->is_success ) {
		my $c = $response->content;
		if ( $c =~ /OK \((\d+), (\d+) .*\)/ ) {
			$self->id($1);
			$self->msg_count($2);
			return 1;
		} else {
			$self->error($self->_parse_error($c));
			return 0;
		}
	} else {
		die( $response->status_line );
	}
}

sub _get_response {
	my $self  = shift;
	my %param = @_;
	my $response;
	for ( 1 .. 3 ) {
		my $url =
		  new URI( 'https://gate' . $_ . '.goyyamobile.com/sms/sendsms.asp' );
		$url->query_form_hash(
			id   => $self->user,
			pw   => $self->password,
			test => scalar $self->test,
			%param
		);
		my $ua = new LWP::UserAgent;
		$ua->timeout(15);
		$response = $ua->get($url);
		return $response if ( $response->is_success );
	}
	return $response;
}

sub _parse_error {
	my $self = shift;
	my $c = shift;
	$self->_clear_object;
	$self->error($c);
}

sub _clear_object {
my $self = shift;
	$self->id("");
	$self->msg_count("");
}

=head1 TODO

=over

=item Add support for all the sms types like flash sms.

=item MMS support

=back

=head1 AUTHOR

Manuel Laux, C<< <laux at netcubed.de> >>,

Moritz Onken, C<< <onken at netcubed.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sms-massenversand at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-Massenversand>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::Massenversand


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-Massenversand>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-Massenversand>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-Massenversand>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-Massenversand>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 netCubed GbR, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Net::SMS::Massenversand
