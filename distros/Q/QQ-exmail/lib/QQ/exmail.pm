package QQ::exmail;

=head1 Name
QQ::exmail

=head1 DESCRIPTION
https://exmail.qq.com/qy_mng_logic/doc#10036

=cut

use strict;
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.004';
our @EXPORT = qw/ gettoken /;

=gettoken
gettoken(corpid,corpsecrect);
=cut

sub gettoken {
    if ( @_ && $_[0] && $_[1] ) {
        my $corpid = $_[0];
        my $corpsecret = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$corpsecret");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
