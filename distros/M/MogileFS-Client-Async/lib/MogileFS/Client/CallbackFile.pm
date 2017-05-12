package MogileFS::Client::CallbackFile;
use strict;
use warnings;
use URI;
use Carp;
use IO::Socket::INET;
use File::Slurp qw/ slurp /;
use Try::Tiny;
use Socket qw/ SO_SNDBUF SOL_SOCKET IPPROTO_TCP /;
use Time::HiRes qw/ gettimeofday tv_interval /;
use Linux::PipeMagic qw/ syssendfile /;
use IO::AIO qw/ fadvise /;
use LWP::Simple qw/ head /;

use base qw/ MogileFS::Client::Async /;

use constant TCP_CORK => ($^O eq "linux" ? 3 : 0); # XXX

use namespace::clean;

=head1 NAME

MogileFS::Client::CallbackFile

=head1 SYNOPSIS

    my $mogfs = MogileFS::Client::Callback->new( ... )

    open(my $read_fh, "<", "...") or die ...
    my $eventual_length = -s $read_fh;
    my $f = $mogfs->store_file_from_fh($key, $class, $read_fh, $eventual_length, \%opts);

    $f->($eventual_length, 0); # upload entire file

    $f->($eventual_length, 1); # indicate EOF

=head1 DESCRIPTION

This package inherits from L<MogileFS::Client::Async> and provides an additional
blocking API in which the data you wish to upload is read from a file when
commanded by a callback function.  This allows other processing to take place on
data as you read it from disc or elsewhere.

The trackers, and storage backends, are tried repeatedly until the file is
successfully stored, or an error is thrown.

The C<$key> parameter may be a closure.  In this case, it is called every time
before C<create_open> is called, allowing a different key to be used if an
upload fails, allowing for additional paranoia.

=head1 SEE ALSO

=over

=item L<MogileFS::Client::Async>

=back

=cut

sub store_file_from_fh {
    my $self = shift;
    return undef if $self->{readonly};

    my ($_key, $class, $read_fh, $eventual_length, $opts) = @_;
    $opts ||= {};

    # Hint to Linux that doubling readahead will probably pay off.
    fadvise($read_fh, 0, 0, IO::AIO::FADV_SEQUENTIAL());

    # Extra args to be passed along with the create_open and create_close commands.
    # Any internally generated args of the same name will overwrite supplied ones in
    # these hashes.
    my $create_open_args =  $opts->{create_open_args} || {};
    my $create_close_args = $opts->{create_close_args} || {};

    my @dests;  # ( [devid,path,fid], [devid,path,fid], ... )

    my $key;

    my $get_new_dest = sub {
        if (@dests) {
            return pop @dests;
        }

        foreach (1..5) {
            $key = ref($_key) eq 'CODE' ? $_key->() : $_key;

            $self->run_hook('store_file_start', $self, $key, $class, $opts);
            $self->run_hook('new_file_start', $self, $key, $class, $opts);

            # Calls to the backend may be explodey.
            my $res;
            try {
                $res = $self->{backend}->do_request(
                    create_open => {
                        %$create_open_args,
                        domain => $self->{domain},
                        class  => $class,
                        key    => $key,
                        fid    => $opts->{fid} || 0, # fid should be specified, or pass 0 meaning to auto-generate one
                        multi_dest => 1,
                        size   => $eventual_length, # not supported by current version
                    }
                );
            }
            catch {
                warn "Mogile backend failed: $_";
                $self->{backend}->force_disconnect() if $self->{backend}->can('force_disconnect');
            };

            unless ($res) {
                # Attempting to connect to the Mogile backend completely failed
                # let's sleep for a second to see if the problem clears.  We
                # don't sleep for other errors as we'll arrive back here if the
                # network fails eventually.
                sleep 1;
                next;
            }

            for my $i (1..$res->{dev_count}) {
                push @dests, {
                    devid => $res->{"devid_$i"},
                    path  => $res->{"path_$i"},
                    fid   => $res->{fid},
                };
            }
            if (@dests) {
                return pop @dests;
            }
        }
        die "Fail to get a destination to write to.";
    };

    # When we have a hiccough in your connection, we mark $socket as undef to
    # indicate that we should reconnect.
    my $socket;


    # We keep track of where we last wrote to.
    my $last_written_point;

    # The pointing to the arrayref we're currently writing to.
    my $current_dest;
    my $create_close_timed_out;

    return sub {
        my ($available_to_read, $eof, $checksum) = @_;

        my $last_error;

        my $fail_write_attempt = sub {
            my ($msg) = @_;
            $last_error = $msg || "unknown error";

            if ($opts->{on_failure}) {
                $opts->{on_failure}->({
                    url   => $current_dest ? $current_dest->{path} : undef,
                    bytes_sent => $last_written_point,
                    total_bytes => $eventual_length,
                    client => 'callbackfile',
                    error => $msg,
                });
            }

            warn $msg;
            $socket = undef;
            $last_written_point = 0;
        };


        foreach (1..5) {
            $last_error = undef;

            # Create a connection to the storage backend
            unless ($socket) {
                sysseek($read_fh, 0, 0) or die "seek failed: $!";
                try {
                    $last_written_point = 0;
                    $current_dest = $get_new_dest->();

                    $opts->{on_new_attempt}->($current_dest) if $opts->{on_new_attempt};

                    my $uri = URI->new($current_dest->{path});
                    $socket = IO::Socket::INET->new(
                        Timeout => 10,
                        Proto => "tcp",
                        PeerPort => $uri->port,
                        PeerHost => $uri->host,
                    ) or die "connect to ".$current_dest->{path}." failed: $!";

                    $opts->{on_connect}->() if $opts->{on_connect};

                    my $buf = 'PUT ' . $uri->path . " HTTP/1.0\r\nConnection: close\r\nContent-Length: $eventual_length\r\n\r\n";
                    setsockopt($socket, SOL_SOCKET, SO_SNDBUF, 65536) or warn "could not enlarge socket buffer: $!" if (unpack("I", getsockopt($socket, SOL_SOCKET, SO_SNDBUF)) < 65536);
                    setsockopt($socket, IPPROTO_TCP, TCP_CORK, 1) or warn "could not set TCP_CORK" if TCP_CORK;
                    syswrite($socket, $buf)==length($buf) or die "Could not write all: $!";
                }
                catch {
                    $fail_write_attempt->($_);
                };
            }

            # Write as much data as we have
            if ($socket) {
                my $bytes_to_write = $available_to_read - $last_written_point;
                my $block_size = $bytes_to_write;

                SENDFILE: while ($bytes_to_write > 0) {
                    my $c = syssendfile($socket, $read_fh, $block_size);
                    if ($c > 0) {
                        $last_written_point += $c;
                        $bytes_to_write     -= $c;
                    }
                    elsif ($c == -1 && $block_size > 1024*1024) {
                        # 32 bit kernels won't even allow you to send more than 2Gb, it seems.
                        # Retry with a smaller block size.
                        $block_size = 1024*1024;
                    }
                    else {
                        $fail_write_attempt->($_);
                        warn "syssendfile failed, only $c out of $bytes_to_write written: $!";
                        last SENDFILE;
                    }
                }

                if ($bytes_to_write < 0) {
                    die "unpossible!";
                }
            }

            if ($socket && $eof) {
                setsockopt($socket, IPPROTO_TCP, TCP_CORK, 0) or warn "could not unset TCP_CORK: $!" if TCP_CORK;
                shutdown($socket, 1) or warn "could not shutdown socket: $!";
                die "File is longer than initially declared, is it still being written to? We are at $last_written_point, $eventual_length initially declared" if ($last_written_point > $eventual_length);
                die "Cannot be at eof, only $last_written_point out of $eventual_length written!" unless ($last_written_point == $eventual_length);

                $self->run_hook('new_file_end', $self, $key, $class, $opts);

                my $buf;
                try {
                    $buf = slurp($socket);
                }
                catch {
                    warn $_;
                };

                if (!defined($buf)) {
                    $fail_write_attempt->("slurp failed");
                    next;
                }

                unless(close($socket)) {
                    $fail_write_attempt->($!);
                    warn "could not close socket: $!";
                    next;
                }

                my ($top, @headers) = split /\r?\n/, $buf;
                if ($top =~ m{HTTP/1.[01]\s+2\d\d}) {
                    # Woo, 200!

                    $opts->{on_http_done}->() if $opts->{http_done};

                    my @cs;

                    if (!$checksum) {
                        try {
                            # XXX - What's the timeout here.
                            my $probe_length = (head($current_dest->{path}))[1];
                            die "probe failed: $probe_length vs $eventual_length" if $probe_length != $eventual_length;
                        }
                        catch {
                            $fail_write_attempt->("HEAD check on newly written file failed: $_");
                        };
                        # No checksum to supply, but we have at least checked the length.
                    }
                    elsif ($checksum && $create_close_timed_out) {
                        try {
                            my $md5 = Digest::MD5->new();
                            my $req = HTTP::Request->new(GET => $current_dest->{path});
                            LWP::UserAgent->new->request($req, sub { $md5->add($_[0]) });

                            my $hex_checked = $md5->hexdigest();
                            die "Got $hex_checked, expected $checksum" if "MD5:$hex_checked" ne $checksum;
                        }
                        catch {
                            $fail_write_attempt->("Cross network checksum failed: $_");
                        };
                        @cs = ( checksum => $checksum, checksumverify => 0 );
                    }
                    else {
                        @cs = ( checksum => $checksum, checksumverify => 1 );
                    }

                    if (defined $last_error) {
                        next;
                    }

                    my $rv;
                    my $ts_sent_create_close = [gettimeofday];
                    try {
                        $rv = $self->{backend}->do_request
                            ("create_close", {
                                fid    => $current_dest->{fid},
                                devid  => $current_dest->{devid},
                                domain => $self->{domain},
                                size   => $eventual_length,
                                key    => $key,
                                path   => $current_dest->{path},
                                @cs,
                            });
                    }
                    catch {
                        warn "create_close exploded: $_";
                        $self->{backend}->force_disconnect() if $self->{backend}->can('force_disconnect');
                    };

                    # TODO we used to have a file check to query the size of the
                    # file which we just uploaded to MogileFS.

                    if ($rv) {
                        $self->run_hook('store_file_end', $self, $key, $class, $opts);
                        return $eventual_length;
                    }
                    elsif (!$create_close_timed_out && $checksum && tv_interval($ts_sent_create_close) >= $self->{backend}->{timeout}) {
                        @dests = ();
                        $create_close_timed_out = 1;
                        $fail_write_attempt->("create_close failed, possibly timed out checksumming");
                    }
                    else {
                        # create_close may explode due to a back checksum,
                        # or a network error sending the acknowledgement of
                        # a successfuly upload.  To handle this. if
                        # create_close fails we always retry with a new
                        # create_open to get a new FID.
                        @dests = ();
                        $fail_write_attempt->("create_close failed");
                    }
                }
                else {
                    $fail_write_attempt->("Got non-200 from remote server $top");
                    next;
                }
            }
            elsif ($last_written_point == $available_to_read) {
                return;
            }
        }

        die "Mogile write failed: $last_error";
    };
}

sub store_file {
    my ($self, $key, $class, $fn, $opts) = @_;

    if (ref($fn)) {
        warn "not scalar!";
        return $self->SUPER::store_file($key, $class, $fn, $opts);
    }

    open(my $fh, "<", $fn) or die "could not open '$fn': $!";

    my $file_length = -s $fh;

    my $cb = $self->store_file_from_fh(
        $key, $class, $fh, $file_length, $opts
    );

    open(my $checksum, "-|", "md5sum", "-b", "--", $fn) or die "could not fork off md5sum: $!";
    $cb->($file_length, 0);
    my $line = <$checksum>;
    close($checksum) or die "could not finish checksum: $!";

    $line =~ /^([0-9a-f]{32})/ or die "could not find checksum";

    $cb->($file_length, 1, "MD5:$1");

    return $file_length;
}

1;

