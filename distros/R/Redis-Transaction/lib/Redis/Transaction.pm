package Redis::Transaction;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.02";

use Carp;

use Exporter 'import';
our @EXPORT_OK = qw/multi_exec watch_multi_exec/;

sub multi_exec {
    my ($redis, $retry_count, $code) = @_;
    return watch_multi_exec($redis, [], $retry_count, sub {}, $code);
}

sub watch_multi_exec {
    my ($redis, $watch_keys, $retry_count, $before, $code) = @_;
    my $err;
    my @ret_before;
    for (1..$retry_count) {
        eval {
            $redis->watch(@$watch_keys) if @$watch_keys;
            @ret_before = $before->($redis) if $before;
        };
        if ($err = $@) {
            # clear IN-WATCHING flag, enable reconnect.
            eval {
                $redis->unwatch;
            };
            $redis->connect if $@;

            # we can retry $code because the redis has not executed $code yet.
            next;
        }

        eval {
            $redis->multi(sub {});
            $code->($redis, @ret_before);
            $redis->wait_all_responses; # force enqueue all commands
        };
        if ($err = $@) {
            # clear IN-TRANSACTION flag, enable reconnect.
            eval {
                $redis->discard;
            };
            $redis->connect if $@;

            # we can retry $code because the redis has not executed $code yet.
            next;
        }

        my $ret = eval {
            $redis->exec;
        };
        if ($err = $@) {
            if ($err =~ /\[exec\] ERR EXEC without MULTI/i) {
                # perl-redis triggers reconnect
                next;
            }

            # clear IN-TRANSACTION flag, enable reconnect.
            $redis->connect;

            # other network error.
            # watch_multi_exec cannot decide if we should reconnect
            croak $err;
        }

        # retry if someone else changed watching keys.
        next unless defined $ret;

        return (wantarray && ref $ret eq 'ARRAY') ? @$ret : $ret;
    }

    croak ($err || 'failed to retry');
}

1;
__END__

=encoding utf-8

=head1 NAME

Redis::Transaction - utilities for handling transactions of Redis

=head1 SYNOPSIS

    use Redis;
    use Redis::Transaction qw/multi_exec watch_multi_exec/;
    
    # atomically increment foo and bar. It will execute following commands typically.
    # > MULTI
    # > INCR foo
    # > INCR bar
    # > EXEC
    multi_exec Redis->new, 10, sub {
        my $redis = shift;
        $redis->incr('foo');
        $redis->incr('bar');
    };
    
    # atomically increment the value of a key by 1 (let's suppose Redis doesn't have INCR).
    # It will execute following commands typically.
    # > WATCH mykey
    # > GET mykey
    # > MULTI
    # > SET mykey, 1
    # > EXEC
    watch_multi_exec Redis->new, ['mykey'], 10, sub {
        my $redis = shift;
        return $redis->get('mykey');
    }, sub {
        my ($redis, $value) = @_;
        $redis->set('mykey', $value + 1);
    };

=head1 DESCRIPTION

Redis::Transaction is utilities for handling transactions of Redis.

=head1 FUNCTIONS

=head2 C<< multi_exec($redis:Redis, $retry_count:Int, $code:Code) >>

Queue commands and execute them atomically.

=head2 C<< watch_multi_exec($redis:Redis, $watch_keys:ArrayRef, $retry_count:Int, $watch_code:Code, $exec_code:Code) >>

Queue commands and execute them atomically.
C<watch_multi_exec> will retry C<$watch_code> and C<$exec_code> if C<$watch_keys> are changed by another client.

=head1 SEE ALSO

=over 4

=item *

L<Redis.pm|https://metacpan.org/pod/Redis>

=item *

L<Redis::Fast|https://metacpan.org/pod/Redis::Fast>

=item *

L<Description of Transactions|http://redis.io/topics/transactions>

=back

=head1 LICENSE

Copyright (C) Ichinose Shogo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.comE<gt>

=cut

