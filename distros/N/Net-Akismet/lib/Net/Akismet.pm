package Net::Akismet;

=head1 NAME

Net::Akismet - Perl interface to Akismet - comment and trackback spam fighter

=cut

use 5.006;
use warnings;
use strict;
use integer;

use LWP::UserAgent;
use HTTP::Request::Common;

our $VERSION	= '0.05';

my $UA_SUFFIX	= "Perl-Net-Akismet/$VERSION";

=head1 SYNOPSIS

	my $akismet = Net::Akismet->new(
			KEY => 'secret-baba-API-key',
			URL => 'http://example.blog.net/',
		) or die('Key verification failure!');

	my $verdict = $akismet->check(
			USER_IP 			=> '10.10.10.11',
			COMMENT_USER_AGENT 	=> 'Mozilla/5.0',
			COMMENT_CONTENT		=> 'Run, Lola, Run, the spam will catch you!',
			COMMENT_AUTHOR		=> 'dosser',
			COMMENT_AUTHOR_EMAIL	=> 'dosser@subway.de',
			REFERRER		=> 'http://lola.home/',
		) or die('Is the server here?');

	if ('true' eq $verdict) {

		print "I found spam. I am a spam-founder!\n";
	}

=head1 METHODS

=over 8

=item B<new()>

	Net::Akismet->new(PARAM => ...);

Acceptable parameters:

=over 4

=item  KEY

The API key being verified for use with the API.

=item  URL

The front page or home URL of the instance making the request.  For a blog or wiki this would be the front page.

=item  USER_AGENT

If supplied the value is prepended to this module's identification string to become something like:

	your-killer-app/0.042 Perl-Net-Akismet/0.01 libwww-perl/5.8

Otherwise just Akismet Perl's user agent string will be sent.

=item	SERVICE_HOST

If supplied, the host of the service API. The default is rest.akismet.com

=item	SERVICE_VERSION

If supplied, the API version. The default is 1.1

=back

If verification of the key was unsuccessful C<new()> returns C<undef>.

=cut

sub new {

	my $that 	= shift;
	my $class 	= ref $that || $that;
	my %params	= @_;

	my $self = \%params;

	$self->{ua} = LWP::UserAgent->new() or return undef;

	my $key 	= $self->{KEY} or return undef;
	my $url		= $self->{URL} or return undef;

	# NOTE: trailing space leaves LWP::UserAgent agent string in place
	my $agent = "$UA_SUFFIX ";
	$agent = "$params{USER_AGENT} $agent" if $params{USER_AGENT};
	$self->{ua}->agent($agent);

	$self->{SERVICE_HOST} = $params{SERVICE_HOST} || 'rest.akismet.com';
	$self->{SERVICE_VERSION} = $params{SERVICE_VERSION} || '1.1';

	bless $self, $class;

	return $self->_verify_key()? $self : undef;
}

sub _verify_key {

	my $self 	= shift;

	my $response = $self->{ua}->request(
			POST "http://$self->{SERVICE_HOST}/$self->{SERVICE_VERSION}/verify-key", 
			[
				key		=> $self->{KEY},
				blog 	=> $self->{URL},
			]
	);

	($response && $response->is_success() && 'valid' eq $response->content()) or return undef;
		
	return 1;
}

=item B<check()>

	$akismet->check(USER_IP => ..., COMMENT_CONTENT => ..., ...)

To be or not to be... C<check> is meant to tell you.  Give it enough details about the comment and expect C<'true'>, C<'false'> or C<undef> as a result.  C<'true'> means B<spam>, C<'false'> means B<not spam>, C<undef> is returned on errror in submission of the comment. 

Acceptable comment characteristics:

=over 4

=item  USER_IP

B<Required.>  Represents the IP address of the comment submitter.

=item  COMMENT_USER_AGENT

B<Required.>  User agent string from the comment submitter's request.

=item  COMMENT_CONTENT

Comment text.

=item  REFERRER

HTTP C<Referer> header.

=item  PERMALINK

Permanent link to the subject of the comment.

=item  COMMENT_TYPE

May be blank, 'comment', 'trackback', 'pingback', or a made up value like 'registration'.

=item  COMMENT_AUTHOR

Name of submitter.

=item  COMMENT_AUTHOR_EMAIL

Submitter e-mail.

=item  COMMENT_AUTHOR_URL

Submitter web page.

=back


=cut

sub check {

	my $self = shift;

	$self->_submit('comment-check', {@_}) or return undef;

	('true' eq $self->{response} || 'false' eq $self->{response}) or return undef;

	return $self->{response};
}

=item B<spam()>

Reports a certain comment as spam.  Accepts the same arguments as C<check()>.

In case of failed submission returns C<undef>, otherwise - a perl-known truth.

=cut

sub spam {

	my $self = shift;

	return $self->_submit('submit-spam', {@_});
}

=item B<ham()>

This call is intended for the marking of false positives, things that were incorrectly marked as spam.  It takes identical arguments as C<check()> and C<spam()>.

In case of failed submission returns C<undef>, otherwise - a perl-known truth.

=cut

sub ham {

	my $self = shift;

	return $self->_submit('submit-ham', {@_});
}

sub _submit {

	my $self = shift;

	my $action = shift || 'comment-check';

	my $comment = shift;

	$comment->{USER_IP} && $comment->{COMMENT_USER_AGENT} || return undef;

	# accomodate common misspelling
	$comment->{REFERRER} = $comment->{REFERER} if !$comment->{REFERRER} && $comment->{REFERER};

	my $response = $self->{ua}->request(
    	POST "http://$self->{KEY}.$self->{SERVICE_HOST}/$self->{SERVICE_VERSION}/$action",
            [
                blog 					=> $self->{URL},
				user_ip					=> $comment->{USER_IP},
				user_agent				=> $comment->{COMMENT_USER_AGENT},
				referrer				=> $comment->{REFERRER},
				permalink				=> $comment->{PERMALINK},
				comment_type			=> $comment->{COMMENT_TYPE},
				comment_author			=> $comment->{COMMENT_AUTHOR},
				comment_author_email	=> $comment->{COMMENT_AUTHOR_EMAIL},
				comment_author_url 		=> $comment->{COMMENT_AUTHOR_URL},
				comment_content			=> $comment->{COMMENT_CONTENT},
            ]
    );

	($response && $response->is_success()) or return undef;
	
	$self->{response} = $response->content();

	return 1;
}

1;

=back

=head1 NOTES

Although almost all comment characteristics are optional, performance can drop dramatically if you exclude certain elements.  So please, supply as much comment detail as possible.

=head1 SEE ALSO

=over 4

=item * http://akismet.com/

=item * http://akismet.com/development/api/

=back

=head1 AUTHOR

Nikolay Bachiyski E<lt>nb@nikolay.bgE<gt>

=head2 Help, modifications and bugfixes from:

=over 4

=item * Peter Pentchev

=item * John Belmonte 

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2007, 2008 by Nikolay Bachiyski

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.7 or, at your option, any later version of Perl 5 you may have available.

$Id: Akismet.pm 38 2008-06-05 17:15:12Z humperdink $

=cut
