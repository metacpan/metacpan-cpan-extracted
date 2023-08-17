package Net::SSH::Perl::Util::Hosts;
use strict;
use warnings;

use Net::SSH::Perl::Constants qw( :hosts );
use Crypt::Misc qw( encode_b64 decode_b64 );
use Crypt::Mac::HMAC qw( hmac );
use Socket;

use Carp qw( croak );

use constant SALT_LEN => 20;

sub _check_host_in_hostfile {
    my($host, $port, $hostfile, $key) = @_;
    my $key_class = ref($key);

    if (defined $port && $port != 22) {
        $host = "[$host]:$port";
    }

    # ssh returns HOST_NEW if the host file can't be opened
    open my $fh, '<', $hostfile or return HOST_NEW;
    local($_, $/);
    $/ = "\n";
    my $status = HOST_NEW;
    HOST: while (<$fh>) {
        chomp;
        my ($hosts, $keyblob) = split /\s+/, $_, 2;
        next unless $keyblob;
        my $fkey;
        ## Trap errors for any potentially unsupported key types
        eval {
            $fkey = $key_class->extract_public($keyblob);
        };
        next if $@;

        my $checkhost = $host;

        ## Check for hashed entries
        if (index($hosts, '|') == 0) {
            if ($hosts !~ /^\|1\|(.+?)\|/) {
                warn qq{Cannot parse line $. of $hostfile\n};
                next;
            }
            my $salt = $1;

            my $rawsalt = decode_b64($salt);
            my $hash = encode_b64(hmac('SHA1',$rawsalt,$host));
            $checkhost = "|1|$salt|$hash";
        }

        for my $h (split /,/, $hosts) {
            if ($h eq $checkhost && $key->ssh_name eq $fkey->ssh_name) {
                $status = $key->equal($fkey) ? HOST_OK : HOST_CHANGED;
                last HOST
            }
        }
    }
    close $fh;
    $status;
}

sub _all_keys_for_host {
    my($host, $port, $hostfile) = @_;
    my $ip;
    if ($host =~ /[a-zA-Z]+/) {
        $ip = inet_ntoa(inet_aton($host));
    }
    if (defined $port && $port != 22) {
        $host = "[$host]:$port";
        $ip = "[$ip]:$port";
    }

    open my $fh, '<', $hostfile or return 0;
    local($_, $/);
    $/ = "\n";
    my @keys;
    while (<$fh>) {
        chomp;
        my ($hosts, $keyblob) = split /\s+/, $_, 2;
        my @hosts_to_check = ($host);
        push @hosts_to_check, $ip if $ip;

        foreach my $checkhost (@hosts_to_check) {
            ## Check for hashed entries
            if (index($hosts, '|') == 0) {
                if ($hosts !~ /^\|1\|(.+?)\|/) {
                    warn qq{Cannot parse line $. of $hostfile\n};
                    next
                }
                my $salt = $1;

                my $rawsalt = decode_b64($salt);
                my $hash = encode_b64(hmac('SHA1',$rawsalt,$host));
                $checkhost = "|1|$salt|$hash";
            }
            for my $h (split /,/, $hosts) {
                if ($h eq $checkhost) {
                    my $fkey;
                    eval { $fkey = Net::SSH::Perl::Key->extract_public($keyblob) };
                    push @keys, $fkey if $fkey;
                }
            }
        }
    }
    close $fh;
    return wantarray ? @keys : \@keys
}

sub _add_host_to_hostfile {
    my($host, $port, $hostfile, $key, $hash_flag) = @_;
    unless (-e $hostfile) {
        require File::Basename;
        my $dir = File::Basename::dirname($hostfile);
        unless (-d $dir) {
            require File::Path;
            File::Path::mkpath([ $dir ])
                or die "Can't create directory $dir: $!";
        }
    }

    my $ip;
    if ($host =~ /[a-zA-Z]+/) {
        $ip = inet_ntoa(inet_aton($host));
        $ip = "[$ip]:$port" if $ip && defined $port && $port != 22;
    }
    $host = "[$host]:$port" if defined $port && $port != 22;

    my $data;
    open my $fh, '>>', $hostfile or croak "Can't write to $hostfile: $!";
    if ($hash_flag) {
        use Crypt::PRNG qw( random_bytes );
        my @entries = ($host);
        push @entries, $ip if $ip;
        foreach my $entry (@entries) {
            my $rawsalt = random_bytes(SALT_LEN);
            my $salt = encode_b64($rawsalt);
            my $hash = encode_b64(hmac('SHA1', $rawsalt, $entry));
            $data .= join(' ', "|1|$salt|$hash", $key->dump_public, "\n");
        }
    }
    else {
        $host = "$host,$ip" if $ip;
        $data = join(' ', $host, $key->dump_public, "\n");
    }
    print $fh $data;
    close $fh or croak "Can't close $hostfile: $!";
}

sub _remove_host_from_hostfile {
    my($host, $port, $hostfile, $key) = @_;
    return unless -e $hostfile;

    my $ip;
    if ($host =~ /[a-zA-Z]+/) {
        $ip = inet_ntoa(inet_aton($host));
        $ip = "[$ip]:$port" if $ip && defined $port && $port != 22;
    }
    $host = "[$host]:$port" if defined $port && $port != 22;

    open my $fh, '<', $hostfile or croak "Can't open $hostfile: $!";
    open my $fhw, '>', "$hostfile.new" or croak "Can't open $hostfile.new for writing: $!";

    LINE: while (<$fh>) {
        chomp;
        my ($hosts, $keyblob) = split /\s+/, $_, 2;
        my $fkey;
        ## Trap errors for any potentially unsupported key types
        eval {
            $fkey = Net::SSH::Perl::Key->extract_public($keyblob);
        };
        # keep it if we don't know what it is
        if ($@) {
            print $fhw $_,"\n";
            next LINE;
        }

        my @hosts_to_check = ($host);
        push @hosts_to_check, $ip if $ip;

        foreach my $checkhost (@hosts_to_check) {
            ## Check for hashed entries
            if (index($hosts, '|') == 0) {
                if ($hosts !~ /^\|1\|(.+?)\|/) {
                    warn qq{Cannot parse line $. of $hostfile\n};
                    next;
                }
                my $salt = $1;

                my $rawsalt = decode_b64($salt);
                my $hash = encode_b64(hmac('SHA1',$rawsalt,$checkhost));
                $checkhost = "|1|$salt|$hash";
            }

            for my $h (split /,/, $hosts) {
                if ($h eq $checkhost && $key->equal($fkey)) {
                    next LINE;
                }
            }
        }
        print $fhw $_,"\n";
    }
    close $fhw or croak "Can't close $hostfile.new: $!";
    close $fh or croak "Can't close $hostfile: $!";
    rename "$hostfile.new", $hostfile;
}

1;
