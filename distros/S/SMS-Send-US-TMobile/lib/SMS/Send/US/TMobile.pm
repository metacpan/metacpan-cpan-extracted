package SMS::Send::US::TMobile;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

# use LWP::UserAgent;
use URI::Escape;
use Net::SSLeay;
use base 'SMS::Send::Driver';

sub new {
   return bless {}, shift;	
}

sub send_sms {
	my ($self, %args) = @_;
    my $url = 'https://web.mms.msg.t-mobile.com/smsportal/index.html'; # ?act=smsc&locale=en';
 
	my %params = (
	    'act'            => 'smsc',
	    'locale'         => 'en',
    #	'trackResponses' => 'No',
    #	'Send.x'         => 'Yes',
	#	'DOMAIN_NAME'    => '@tmomail.com',
	    'receiver'       => $args{'to'}    || '', # To: maxlength 10 digits
	    'sender'         => $args{'_from'} || '', # From: prepended to 'text', seperated by '/'
	    'text'           => $args{'text'}  || '', # message 'text'
	    'msgTermsUse'    => 1,
	    'Send'           => 1,
	);

	# cleanup
	$params{'receiver'} =~ s{\D}{}g; # remove non-digits
	
	# validate
	croak q{'_from' must be specified} if !$params{'sender'};
	croak q{'to' must contain ten digits} if length $params{'receiver'} != 10;
	croak q{'_from' and 'text' combined must not be more than 159 characters} 
	    if length( $params{'sender'} ) +  length( $params{'text'} ) > 159;
	
	# send away
    my $uri = join( '&', map { $_ . '=' . uri_escape( $params{ $_ } ) } keys %params );
 
#	my $ua = LWP::UserAgent->new;
#   my $req = HTTP::Request->new( 'POST' => $url );
#   $req->content_type('application/x-www-form-urlencoded');
#   $req->content( $uri );
#   my $res = $ua->request($req);

    # must match $url above:
    my ($content, $response, %reply_headers) = Net::SSLeay::post_https(
        'web.mms.msg.t-mobile.com',
        443,
        '/smsportal/index.html',
        '',
        Net::SSLeay::make_form(%params), 
    );

    if ( $content ) { # if( $res->is_success ) {
        return 1 if $content =~ m{Your message has been delivered}; # if $res->as_string =~ m{Your message has been delivered};
		# eval { die $res->as_string };
		$@ = {
			'args'       => \%args,
			# essencially useless info at this point: 'caller'     => [ caller() ],
			'url'        => $url,
			'content'    => $uri,
			'is_success' => 1,
			'as_string'  => $response, # $res->as_string,
		};
		return 0; # bah! this is not cool but required or you get 'Driver did not return a result'
	}
	else {
		# eval { die $res->as_string };
		$@ = {
			'args'       => \%args,
			# essencially useless info at this point: 'caller'     => [ caller() ],
			'url'        => $url,
			'content'    => $uri,
			'is_success' => 0,
			'as_string'  => $response, # $res->as_string,
		};
		return 0; # bah! this is not cool but required or you get 'Driver did not return a result'
	}
}

1; 

__END__

=head1 NAME

SMS::Send::US::TMobile - SMS::Send driver for the web.mms.msg.t-mobile.com website

=head1 VERSION

This document describes SMS::Send::US::TMobile version 0.0.3

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('US::TMobile');

    $sender->send_sms(
	    '_from' => 'T. Tutone', # prepended to 'text' seperated by '/', I dunno; that what their site does :)
	    'to'    => '7658675309', # ten digit, t-mobile number
	    'text'  => "Jenny I got your number\nI need to make you mine\nJenny don't change your number", # 159 - '_from' chacters
    ) or _handle_sms_error( $@ );  
  
=head1 DESCRIPTION

Sends an SMS::Send message to TMobile US customers when used as the L<SMS::Send> driver.

Uses 'to' and 'text' as per L<SMS::Send> and additionally uses '_from' to prepend who its from to 'text'.


=head1 INTERFACE 

=head2 new

No extra agrgs, just
  SMS::Send->new('US::TMobile');

=head2 send_sms

If send_sms() returns true then tmobile said it was sent.

If send_sms() returns false then $@ is set to a hashref of the following info:

	{
		'args'       => {}, # arguments to send_sms()
		'caller'     => [], # caller() info
		'url'        => '', # tmobile URL involved
		'content'    => '', # content POSTed to the url above
		'is_success' => '', # was HTTP POST successful or not (1 or 0)
		'as_string'  => '', # HTTP POST response as a string
	}

=head1 DIAGNOSTICS

=over

=item C<< 'to' must contain ten digits >>

The value passed to 'to' does not have ten digits.

=item C<< '_from' and 'text' combined must not be more than 159 characters >>

The length of characters in '_from' and 'text' put together are too long.

The limit is 160 but the two fields are seperated by a '/' which takes up one character so you have 159 to work with.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
SMS::Send::US::TMobile requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<LWP::UserAgent>, L<URI::Escape>, L<SMS::Send::Driver>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sms-send-us-tmobile@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
