package QQ::exmail::log;

=head1 Name
QQ::exmail::log

=head1 DESCRIPTION
https://exmail.qq.com/qy_mng_logic/doc#10036

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.004';
our @EXPORT = qw/ mail /;

=mail
mail(access_token, hash);
=cut

sub mail {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        print to_json($json,{allow_nonref=>1}),"\n";
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/log/mail?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
