package Net::Duowan::DNS::Common;

use 5.006;
use warnings;
use strict;
use Carp qw/croak/;
use JSON;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

use vars qw/$VERSION/;
$VERSION = '1.2.0';

sub new {
    my $class = shift;
    bless {},$class;
}

sub reqTemplate {
    my $self = shift;
    my %args = @_;

    my $url = 'https://cloudns.duowan.com/v1.2/api/';
    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    $ua->ssl_opts(verify_hostname => 0);

    my $req = POST $url, [ %args ];
    my $res = $ua->request($req);

    if ($res->is_success ) {
        return from_json( $res->decoded_content );
    } else {
        croak $res->status_line;
    }
}

1;
