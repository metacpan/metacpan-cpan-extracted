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
    return $quota && $quota >= $minimum;
}

sub get_quota {
    my $ua = Mojo::UserAgent->new;
    my $url = 'https://www.random.org/quota/?format=plain';
    my $tx = $ua->get($url);

    my $quota;
    eval {
        my $res = $tx->result;
        if ( $res->code == 200 ) {
            $quota = int $res->body;
        }
        elsif ($res->code == 403) {
            $quota = 0;
        }
        else { die qq{$res->{code} $res->{message}\n}; }
        1;
    } or die "Connection error: $@\n";
    return $quota;
}

1;
