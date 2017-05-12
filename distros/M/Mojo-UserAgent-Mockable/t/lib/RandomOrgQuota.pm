package RandomOrgQuota;
use base qw/Exporter/;
use Mojo::UserAgent;

our @EXPORT_OK = qw/check_quota get_quota/;

sub check_quota {
    my $minimum = shift;
    $minimum ||= 0;
    my $quota;
    eval {
        $quota = get_quota();
        1;
    } or die qq{Failed to get quota: $@\n};
    return $quota >= $minimum;
}

sub get_quota {
    my $ua = Mojo::UserAgent->new;
    my $url = 'https://www.random.org/quota/?format=plain';
    my $tx = $ua->get($url);
    if ( my $res = $tx->success ) {
        if ( $res->code eq 200 ) {
            my $quota = int $res->body;
            return $quota;
        }
        else { die qq{$res->{code} $res->{message}\n}; }
    }
    else {
        my $err = $tx->error;
        die "$err->{code} response: $err->{message}\n" if $err->{code};
        die "Connection error: $err->{message}\n";
    }
}

1;
