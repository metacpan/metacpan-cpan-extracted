package TRD::WebRelayMail;

use warnings;
use strict;
use Carp;
use CGI;
use LWP;
#use TRD::DebugLog;

#$TRD::DebugLog::enabled = 1;
#$TRD::DebugLog::file = '/tmp/ichi.log';

use version;
our $VERSION = qv('0.0.5');

=head1 FUNCTIONS

=head2 new

	TRD::WebRelayMailオブジェクトを作成するコンストラクタです。
	my $relaymail = new TRD::WebRelayMail;

=cut
#======================================================================
sub new {
	my $pkg = shift;
	bless {
		params => {
			proxy => undef,
		},
		sendUrl => undef,
	}, $pkg;
};

=head2 setSendUrl( $url )

	リレー先URLを設定します。
	$relaymail->setSendUrl( 'http://foobar/relay/rmail.cgi' );
	リレー先のcgiには、TRD::WebRelayMail->Recv()を使用します。

=cut
#======================================================================
sub setSendUrl
{
	my $self = shift;
	my $sendurl = shift;

	$self->{params}->{sendUrl} = $sendurl;
}

=head2 setProxy( $proxy )

	リレー先URLへ接続する際のProxyを設定します。
	$relaymail->setProxy( 'http://proxy.foobar:8080/' );
	TRD::WebRelayMain->Send()を使用する際にProxyを使用します。

=cut
#======================================================================
sub setProxy
{
	my $self = shift;
	my $proxy = shift;

	$self->{params}->{proxy} = $proxy;
}

=head2 Send( $message )

	リレーメールを送信します。
	my $res = $relaymail->Send( $mime->stringify );

	$messageは、MIME::Entityで作成された物を使用します。
	返り値は、=1 送信完了。!=1 エラー。

=cut
#======================================================================
sub Send
{
	my $self = shift;
	my $mail_message = shift;

	my $res = 0;

	my $logname = $ENV{'LOGNAME'};
	my $hostname = `hostname`;
	chop( $hostname );
	my $sender = $logname. '@'. $hostname;

	my $url = $self->{params}->{sendUrl};
	my $query_string = 'sender='. &url_encode( $sender ). '&message='. &url_encode( $mail_message );

#dlog( 'url='. $url );
#dlog( 'query_string='. $query_string );

	my $browser = LWP::UserAgent->new(
		agent => 'TRD::WebRelayMail('. $VERSION. ')',
	);

	if( exists( $self->{params}->{proxy} ) ){
		$browser->proxy( 'http', $self->{params}->{proxy} );
	}

	my $req = HTTP::Request->new( POST => $url );
	$req->content( $query_string );

	my $response = $browser->request( $req );

#dlog( 'response='. $response->content );
	if( $response->content eq 'ok' ){
		$res = 1;
	}
	return $res;
}

=head2 Recv( $cgi )

	リレーメールを受信します。
	$cgiはCGIを設定します。
	TRD::WebRelayMail->setSendUrlで設定した受信cgiで使用します。

=cut
#======================================================================
sub Recv
{
	my $self = shift;
	my $cgi = shift;
	my $data;
	my $res = 0;

	my $sender = $cgi->param( 'sender' );
	my $message = $cgi->param( 'message' );

	$data->{'sender'} = $sender;
	$data->{'message'} = $message;

	if(( $sender ne '' )&&( $message ne '' )){
		$res = 1;
	}
	$data->{'res'} = $res;

	return $data;
}

=head2 url_encode( $str )

	文字列をURLエンコードします。
	$str = $relaymail->url_encode( $str );

=cut
#======================================================================
sub url_encode
{
	my $str = shift;

	$str =~s/([^\w ])/'%'.unpack('H2', $1)/eg;
	$str =~tr/ /+/;

	return $str;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

TRD::WebRelayMail - メールを送れないホストからのWebメールリレーモジュール

=head1 VERSION

This document describes TRD::WebRelayMail version 0.0.4


=head1 SYNOPSIS

	# 送信用
	use strict;
	use Jcode;
	use MIME::Entity;
	use TRD::WebRelayMail;

	my $relaymail = new TRD::WebRelayMail;
	$relaymail->setSendUrl( 'http://foobar/relay/rmail.cgi' );
	my $mail_to = 'receiver@barbas.com';
	my $mail_from = 'sender@barbas.com';
	my $mail_subject = 'TEST MAIL';
	my $mail_body = 'THIS IS TEST';

	$mail_subject = jcode( $mail_subject )->mime_encode;
	Jcode::convert( \$mail_body, 'jis' );

	my $mime = MIME::Entity->build(
		From => $mail_from,
		To => $mail_to,
		Subject => $mail_subject,
		Type => 'text/plain; charset="iso-2022-jp"',
		Data => $mail_body,
	);

	my $res = $relaymail->Send( $mime->stringify );
	if( !$res ){
		print "NG\n";
	} else {
		print "OK\n";
	}

	#[EOT]

	# 受信用
	use strict;
	use CGI;
	use TRD::WebRelayMail;

	my $cgi = new CGI;
	my $relaymail = new TRD::WebRelayMail();

	my $data = $relaymail->Recv( $cgi );

	if( !$data->{'res'} ){
		print "Content-type: text/html\n\n";
		print "ng";
	} else {
		print "Content-type: text/html\n\n";
		print "ok";

		open( my $m, "| /usr/sbin/sendmail -t" );
		print $m $data->{'message'};
		close( $m );
	}

	# [EOT]

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
TRD::WebRelayMail requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-trd-webrelaymail@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Takuya Ichikawa  C<< <ichi@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Takuya Ichikawa C<< <ichi@cpan.org> >>. All rights reserved.

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
