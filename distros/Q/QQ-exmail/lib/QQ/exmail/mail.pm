package QQ::exmail::mail;

=encoding utf8

=head1 Name
QQ::exmail::mail

=head1 DESCRIPTION
新邮件提醒
=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.06';
our @EXPORT = qw/ newcount /;

=head2 newcount
newcount(access_token, userid, hash);
获取邮件未读数
L<https://exmail.qq.com/qy_mng_logic/doc#10033>
=cut

sub newcount {
    if ( @_ && $_[0] && $_[1] && ref $_[2] eq 'HASH' ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $json = $_[2];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/mail/newcount?access_token=$access_token&userid=$userid",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
