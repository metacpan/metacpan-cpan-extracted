package Net::Akismet::Protocol;



use Moose;
use integer;
use LWP::UserAgent;
use HTTP::Request::Common;

our $VERSION	= '0.02';

has 'url'         => ( isa => 'Str',is=>'rw' );
has 'key'         => ( isa => 'Str',is=>'rw' );
has 'ua'          => ( isa => 'LWP::UserAgent', default=>sub { LWP::UserAgent->new()},is=>'rw');
has 'api_version' => ( isa => "Str", default=>"1.1",is=>'rw' );
has 'host'        => ( isa => "Str", default=>"api.antispam.typepad.com",is=>'rw' );
has 'ua_string'   => ( isa => 'Str', default=> "Perl-Net-Akismet-Protocol/$VERSION",is=>'rw');
has 'response'    => ( isa => 'HTTP::Response',is=>'rw');

sub BUILD {
    my ($self,$params)=@_;
	$self->ua->agent($self->ua_string);
	return $self if $self->_verify_key();
    die "Could not verify ".$self->key;
}

sub _verify_key {
	my $self=shift;

	my $response = $self->ua->post(
		   'http://'.$self->host.'/'.$self->api_version.'/verify-key', 
			[
				key		=> $self->key,
				blog 	=> $self->url,
			]
	);

	($response && $response->is_success() && 'valid' eq $response->content()) or return undef;
		
	return 1;
}

sub check {

	my $self = shift;

	$self->_submit('comment-check', {@_}) or return undef;

	$self->response->content eq'true' ||  $self->response->content eq 'false' || die $self->response->content;

	return $self->response->content eq 'true' ? 1 : 0;
}


sub spam {

	my $self = shift;

	return $self->_submit('submit-spam', {@_});
}

sub ham {

	my $self = shift;

	return $self->_submit('submit-ham', {@_});
}

sub _submit {

	my $self = shift;

	my $action = shift || 'comment-check';

	my $comment = shift;

	$comment->{user_ip} && $comment->{user_agent} || die "User IP and User Agent required";

	my $response = $self->{ua}->post(
    	   'http://'.$self->key.'.'.$self->host.'/'.$self->api_version.'/'.$action, 
		
            [
                blog 					=> $self->url,
				user_ip					=> $comment->{user_ip},
				user_agent				=> $comment->{user_agent},
				referrer				=> $comment->{referrer},
				permalink				=> $comment->{permalink},
				comment_type			=> $comment->{comment_type},
				comment_author			=> $comment->{comment_author},
				comment_author_email	=> $comment->{comment_author_email},
				comment_author_url 		=> $comment->{comment_author_url},
				comment_content			=> $comment->{comment_content},
            ]
    );
	
	$self->response( $response);

	return 1;
}

1;

__END__

=head1 NAME

Net::Akismet::Protocol - Perl interface to Akismet Protocol - comment and trackback spam fighter

=cut

=head1 SYNOPSIS

	my $akismet = Net::Akismet::Protocol->new(
			key => 'secret-baba-API-key',
			url => 'http://example.blog.net/',
		);

	my $verdict = $akismet->check(
			user_ip 		=> '10.10.10.11',
			user_agent 		=> 'Mozilla/5.0',
			comment_content		=> 'Run, Lola, Run, the spam will catch you!',
			comment_author		=> 'dosser',
			coment_author_email	=> 'dosser@subway.de',
			referrer		=> 'http://lola.home/',
		) or die('Is the server here?');

	if ( $verdict == 1) {

		print "I found spam. I am a spam-finder!\n";
	}
=head1 DESCRIPTION

This module implements the Akismet anti-spam API. It's based on L<Net::Akismet>,
but has been rewritten using Moose, and it you allows to use different servers
as long as they implement the same REST spec as Akismet. By default, the module
will use Typepad Antispam.

=head1 METHODS


=head2 B<new()>

	Net::Akismet->new(PARAM => ...);

Acceptable parameters:

=over 4

=item  key

The API key being verified for use with the API.

=item  url

The front page or home URL of the instance making the request.  For a blog or wiki this would be the front page.

=item ua

The LWP::UserAgent to use
´
=item  ua_string

This will be set as your user agent string at build time if supplied.

=item api_version

Akismet API version in use. Defaults to '1.1'

=item host

API host to connect to. defaults to 'api.antispam.typepad.com'

=back

If verification of the key was unsuccessful C<new()> returns C<undef>.


=head2 B<check()>

	$akismet->check(user_ip => ..., comment_content => ..., ...)

To be or not to be... C<check> is meant to tell you.  Give it enough details about the comment and expect C<'true'>, C<'false'> or C<undef> as a result.  C<'true'> means B<spam>, C<'false'> means B<not spam>, C<undef> is returned on errror in submission of the comment. 

Acceptable comment characteristics:

=over 4

=item  user_ip

B<Required.>  Represents the IP address of the comment submitter.

=item  user_agent

B<Required.>  User agent string from the comment submitter's request.

=item  comment_content

Comment text.

=item  referer

HTTP C<Referer> header.

=item  permalink

Permanent link to the subject of the comment.

=item  comment_type

May be blank, 'comment', 'trackback', 'pingback', or a made up value like 'registration'.

=item  comment_author

Name of submitter.

=item  comment_author_mail

Submitter e-mail.

=item  comment_author_url

Submitter web page.

=back


=head2 B<spam()>

Reports a certain comment as spam.  Accepts the same arguments as C<check()>.

In case of failed submission returns C<undef>, otherwise - a perl-known truth.

=head2 B<ham()>

This call is intended for the marking of false positives, things that were incorrectly marked as spam.  It takes identical arguments as C<check()> and C<spam()>.

In case of failed submission returns C<undef>, otherwise - a perl-known truth.

=head1 Internal Moose methods

=head2 meta

=head2 BUILD

=head1 NOTES

Although almost all comment characteristics are optional, performance can drop
dramatically if you exclude certain elements.  So please, supply as much 
comment detail as possible.

=head1 SEE ALSO

=over 4

=item * L<Net::Akismet>

=item * http://akismet.com/

=item * http://akismet.com/development/api/

=back

=head1 AUTHOR

Marcus Ramberg E<lt>mramberg@cpan.orgE<gt>

Based on L<Net::Akismet> by Nikolay Bachiyski E<lt>nbachiyski@developer.bgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
