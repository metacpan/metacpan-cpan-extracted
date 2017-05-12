package SpamMonkey::Test::check_uridnsbl;
use strict;
use SpamMonkey::Utils;
sub init {
    my ($self, $conf) = @_;
    $conf->{settings}{uridnsbl} = [ $conf->{settings}{uridnsbl} ]
        unless ref $conf->{settings}{uridnsbl};
    $conf->{settings}{uridnsbl} = {
        map { 
            my ($name, $url, $type) = split /\s+/, $_, 3;
            $name => { url => $url, type => $type }
        } @{$conf->{settings}{uridnsbl}}
    };
    $conf->{settings}{uridnsbl_skip_domain} = { 
        map { map { $_ => 1 } split /\s+/, $_  }
        @{$conf->{settings}{uridnsbl_skip_domain}}};
}

sub test {
    my ($class, $monkey, $text_r, $bl) = @_;
    $monkey->get_uris($text_r);
    my $settings = $monkey->{conf}{settings};
    return unless my $bl_stuff= $settings->{uridnsbl}->{$bl};
    #my $hits = 0;
    my @uris = $monkey->uris;
    return unless @uris;
    while ($settings->{uridnsbl_max_domains} > 0 and 
            @uris > $settings->{uridnsbl_max_domains}) {
        splice @uris, rand(@uris),1;
    }
    URL: for (@uris) {
        my $uri = URI->new($_);
        next if $uri->isa("URI::mailto");
        for (keys %{$settings->{uridnsbl_skip_domain}}) {
            next URL if $uri->host =~ /$_\$/;
        }
        my @bits = SpamMonkey::Utils->host_to_ip($uri->host);
        return 1 unless @bits; # Dead hosts are a threat in themselves
        my $ip = join ".", (reverse(@bits), $bl_stuff->{url});
        if (SpamMonkey::Utils->rbl_check($ip, $bl_stuff->{type},
                $settings->{uridnsbl_timeout})) {
            #$hits++;
            return 1;
        }
    }
    return;
    #return (1) x $hits;
}
1;
