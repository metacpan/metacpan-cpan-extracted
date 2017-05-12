package Net::Twitpic;

use warnings;
use strict;
use utf8;

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use Net::OAuth;
our $DYNAMIC_FILE_UPLOAD = 1;

=head1 NAME

Net::Twitpic - The great new Net::Twitpic!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Easily upload photos to Twitpic.

Perhaps a little code snippet.

    use Net::Twitpic;

    my $tp = Net::Twitpic->new(
        twitpic_api => $twitpic_api,        # get from Twitpic Developers
        consumer_key => $consumer_key,      # get from dev.twitter.com
        consumer_secret => $consumer_secret # get from dev.twitter.com
    );
    $tp->upload(
        oauth_token => $oauth_token,        # get from API transaction
        oauth_secret => $oauth_secret,      # get from API transaction
        file => $filename,                  # photo file path
        message => $message                 # message attached to Twitpic
    );
    if ($tp->is_success) {
        print $tp->info->{'url'};
    }

=head1 SUBROUTINES/METHODS

=head2 new

Construct new Net::Twitpic object.

=cut

sub new {
	my $thing = shift;
	my $class = ref $thing || $thing;
	my $ua = LWP::UserAgent->new;
	bless { @_, ua => $ua, r => '' }, $class;
}

=head2 upload

Upload the photo saved locally with message (both required). Specify OAuth token and OAuth secret you have aquired for your twitter-associated user.

=cut

sub upload {
	my $self = shift;
	my %params = @_;
	my $oauth_sign = Net::OAuth->request('Access Token')->new(
		consumer_key => $self->{'consumer_key'},
		consumer_secret => $self->{'consumer_secret'},
		token => $params{'oauth_token'},
		token_secret    => $params{'oauth_secret'},
		signature_method => 'HMAC-SHA1',
		timestamp => time(),
		nonce => time() . '2323232323232323',
		request_method => 'GET',
		request_url => 'https://api.twitter.com/1/account/verify_credentials.json'
	);
	$oauth_sign->sign;
	my %uploadparams = (
		'key' => $self->{'twitpic_api'},
		'message' => $params{'message'},
		'media' => [$params{'file'}]
	);
	my %req_headers = (
		'X-Verify-Credentials-Authorization' => $oauth_sign->to_authorization_header,
		'X-Auth-Service-Provider' => 'https://api.twitter.com/1/account/verify_credentials.json',
		'Content-Type' => 'form-data'
	);
	my $request = POST('http://api.twitpic.com/2/upload.json',\%uploadparams,%req_headers);
	$self->{r} = $self->{ua}->request($request);
}

=head2 is_success

Return true if the request has been proccessed correctly.

=cut

sub is_success {
	my $self = shift;
	return $self->{r}->is_success;
}

=head2 info

Return uploaded info as hash.

=cut

sub info {
	my $self = shift;
	return decode_json($self->{r}->decoded_content);
}

=head1 AUTHOR

Yusuke Sugiyama, C<< <ally at blinkingstar.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-twitpic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Twitpic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Twitpic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Twitpic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Twitpic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Twitpic>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Twitpic/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Yusuke Sugiyama.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Twitpic
