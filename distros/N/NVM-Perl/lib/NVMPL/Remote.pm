package NVMPL::Remote;
use strict;
use warnings;
use feature 'say';
use HTTP::Tiny;
use JSON::PP qw(decode_json);
use File::Spec;
use NVMPL::Config;
use NVMPL::Utils qw(log_info log_warn log_error);


# ---------------------------------------------------------
# Fetch and cache remote Node.js version list
# ---------------------------------------------------------

sub fetch_remote_list {
    my $cfg = NVMPL::Config->load();
    my $mirror = $cfg->{mirror_url};
    my $install_dir = $cfg->{install_dir};
    my $cachefile = File::Spec->catfile($install_dir, 'node_index_cache.json');
    my $ttl = $cfg->{cache_ttl};

    my $json_data;
    my $use_cache = 0;

    if (-f $cachefile) {
        my $age = time - (stat($cachefile))[9];
        if ($age < $ttl) {
            $use_cache = 1;
            log_info("Using cached node index ($cachefile)");
            open my $fh, '<', $cachefile or die "Cannot read cache: $!";
            local $/;
            $json_data = <$fh>;
            close $fh;
        }
    }

    unless ($use_cache) {
        my $url = "$mirror/index.json";
        log_info("Fetching remote version list from $url");

        my $ua = HTTP::Tiny->new(timeout => 10);
        my $resp = $ua->get($url);
        unless ($resp->{success}) {
            log_error("Failed to fetch index.json: $resp->{status} $resp->{reason}");
            die "Network error while fetching index.json\n";
        }
        $json_data = $resp->{content};

        open my $fh, '>', $cachefile or log_warn("Could not write cache: $!");
        print $fh $json_data;
        close $fh;
    }

    my $releases = decode_json($json_data);
    return $releases;
}

# ---------------------------------------------------------
# List remote Node versions (optionally filtered)
# ---------------------------------------------------------

sub list_remote_versions {
    my (%opts) = @_;
    my $releases = fetch_remote_list();

    my @filtered;
    if ($opts{lts}) {
        @filtered = grep { $_->{lts} } @$releases;
    } else {
        @filtered = @$releases;
    }

    my $limit = $opts{limit} // 20;
    splice(@filtered, $limit) if @filtered > $limit;

    say "[nvm-pl] Available Node.js versions:";
    foreach my $r (@filtered) {
        my $v = $r->{version};
        my $lts = $r->{lts} ? "(LTS: $r->{lts})" : "";
        say " $v $lts";
    }
}

1;