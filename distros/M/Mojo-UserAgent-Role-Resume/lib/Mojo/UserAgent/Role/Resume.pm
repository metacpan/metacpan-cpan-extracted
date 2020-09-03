package Mojo::UserAgent::Role::Resume;
use 5.016;
use strict;
use warnings;

use Mojo::Base -role;

use Scalar::Util 'refaddr';

our $VERSION = "v0.1.0";

has max_attempts => 1;

my $TX_ROLE = "Mojo::Transaction::HTTP::Role::Resume";

# only add the role to HTTP requests, and not to websockets
around build_tx => sub {
    my ($orig, $self, @args) = @_;

    my $tx = $self->$orig(@args)->with_roles($TX_ROLE);
    return $tx->_RESUME_original_arguments(\@args);
};

around start => sub {
    my ($orig, $self, @args) = @_;

    my ($orig_tx, @orig_cb) = @args;
    my $orig_cb = $orig_cb[0];
    my $blocking = !defined $orig_cb;

    # don't wrap this 'start' invocation, if websocket, redirect, or retry
    return $self->$orig(@args)
        if !eval{$orig_tx->does($TX_ROLE)} or $orig_tx->previous or $orig_tx->RESUME_previous_attempt;

    my $tx = $orig_tx; # $tx will always equal the first tx (ie before any redirections) of every attempt
    my @original_build_args = @{ $tx->_RESUME_original_arguments() };
    my $server_is_crappy_for_ranges = 0; # has server been proven to be unreliable for ranged requests?
    my $latest_good_200_tx; # the last tx with code 200 & full headers (holds the asset that 206 tx's should append to)
    my $remaining_attempts = $self->max_attempts;

    # prevent ref cycles (which could lead to memory leaks)
    my $_clean = sub {
        undef $_ foreach ($tx, $latest_good_200_tx);
        undef @original_build_args;
    };

    # set special my_progress event handler to $tx, and also to the retries:
    my $progress_handler = sub {
        my ($msg) = @_;

        # my_progress handlers are by default only executed on 200|206 responses
        return unless $msg->code and $msg->code =~ /^20(0|6)$/;
        return unless $msg->headers->is_finished;

        # only run once
        $msg->unsubscribe(progress => __SUB__);

        my $total_size = _total_size($msg);

        !$server_is_crappy_for_ranges or return; # only interested if server was not labelled crappy

        my $headers = $msg->headers;
        my $old_headers = eval {$latest_good_200_tx->res->headers};
        my ($h_start_byte) = ($headers->content_range // '') =~ /^bytes (\d+)\-/;

        $server_is_crappy_for_ranges ||= do {
            # 1. missing all important headers
            (!$headers->etag and !$headers->last_modified and !defined $total_size) or

                # 2. wrong HTTP status code:
                ($tx->req->headers->range xor $msg->code == 206) or

                # 3. missing, malformed, or extra Content-Range header:
                ($msg->code == 200 and $headers->content_range) or
                ($msg->code == 206 and ($headers->content_range // '') !~ /^bytes \d+\-\d+\/(\*|\d+)$/) or

                # 4. an important header is different than that of the older tx that we are resuming on:
                (defined $old_headers and (
                    !eqq($headers->etag, $old_headers->etag) or
                        !eqq($headers->last_modified, $old_headers->last_modified) or
                        !eqq($total_size, _total_size($latest_good_200_tx->res))
                )) or

                # 5. the numbers in the headers don't add-up correctly
                ($msg->code == 206 and (
                    !defined $h_start_byte or
                        !eqq($h_start_byte, scalar(eval {$latest_good_200_tx->res->content->asset->size})) or
                        (defined $total_size and defined $headers->content_length
                            and $h_start_byte + $headers->content_length != $total_size)
                ));
        };

        if ($msg->code == 206) {
            if ($server_is_crappy_for_ranges) {
                # abort and retry
                $remaining_attempts++; # just this one attempt should be "for free", since it was inexpensive
                $msg->error({ message => "web server can't handle ranged requests, aborting" }); # abort
                return;
            } else {
                # switch asset
                my $big_asset = $latest_good_200_tx->res->content->asset->add_chunk($msg->content->asset->slurp);
                $msg->content->asset($big_asset);
            }
        } elsif ($msg->code == 200) {
            if (!$server_is_crappy_for_ranges) {
                # mark as latest good tx:
                $latest_good_200_tx = $tx;
            }
        }
    };
    unshift @{ $tx->res->subscribers('progress') }, $progress_handler;

    my $build_retry_tx = sub {
        my ($old_tx) = @_;

        # don't continue if $old_tx isn't a failure
        return undef unless $old_tx->error and !$old_tx->res->is_client_error;

        # TODO: Check whether we should also check for "content received < total_size_based_on_headers"

        my $retry_tx = $self->build_tx(@original_build_args);
        unshift @{ $retry_tx->res->subscribers('progress') }, $progress_handler;

        if ($latest_good_200_tx and !$server_is_crappy_for_ranges) {
            # set Range: header
            $retry_tx->req->headers->range('bytes='.$latest_good_200_tx->res->content->asset->size.'-');
        }

        # store old_tx in a field of new_tx, similar to $tx->previous for redirects
        $retry_tx->RESUME_previous_attempt($old_tx); # store old tx in $retry_tx

        return $retry_tx;
    };

    # don't start any transactions if $remaining_attempts is not high enough
    $remaining_attempts >= 1 or return $tx;

    if ($blocking) {
        my $tx_after_redirects;
        while (1) {
            $tx_after_redirects = $self->$orig($tx, @orig_cb);
            --$remaining_attempts >= 1 and $tx = $build_retry_tx->($tx_after_redirects) or last;
        }
        $_clean->();
        return $tx_after_redirects;
    } else {
        return $self->$orig($tx, sub {
            my ($ua, $tx_after_redirects) = @_;
            --$remaining_attempts >= 1 and $tx = $build_retry_tx->($tx_after_redirects)
                or $_clean->(), $orig_cb->($ua, $tx_after_redirects), return;
            $ua->$orig($tx, __SUB__);
        });
    }
};

sub eqq {
    my ($x, $y) = @_;

    defined $x or return !defined $y;
    defined $y or return !!0;
    ref $x eq ref $y or return !!0;
    return length(ref $x) ? refaddr $x == refaddr $y : $x eq $y;
}

sub _total_size {
    my ($msg) = @_;

    return undef unless $msg->headers->is_finished;

    if ($msg->code == 206) {
        ($msg->headers->content_range // '') =~ /^bytes \d+\-(\d+)\/(?:\*|(\d+))\z/;
        return $2 // (defined $1 ? $1 + 1 : undef);
    } else {
        return $msg->headers->content_length;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::UserAgent::Role::Resume - Role for Mojo::UserAgent that provides resuming capability during downloads

=head1 SYNOPSIS

    use Mojo::UserAgent;

    my $class = Mojo::UserAgent->with_roles('+Resume');

    my $ua = $class->new(max_attempts => 5);

    # works with blocking requests:
    my $tx = $ua->get('http://ipv4.download.thinkbroadband.com/100MB.zip');

    # ...as well as with non-blocking ones (including promises, etc):
    $ua->get('http://ipv4.download.thinkbroadband.com/100MB.zip', sub ($ua, $tx) {
        $tx->res->content->asset->move_to('downloaded_file.zip');
        print $tx->res->headers->to_string;
    });

    # The last snippet will save the entire file to downloaded_file.zip regardless of temporary disconnects, and
    # will print something like this:
    Connection: keep-alive
    Content-Length: 103124119
    Server: nginx
    ETag: "48401320-6400000"
    Last-Modified: Fri, 30 May 2008 14:45:52 GMT
    Date: Thu, 27 Aug 2020 16:25:18 GMT
    Content-Range: bytes 1733481-104857599/104857600
    Content-Type: application/zip
    Access-Control-Allow-Origin: *

=head1 DESCRIPTION

Mojo::UserAgent::Role::Resume is a role for Mojo::UserAgent that allows the user-agent to
retry a URL upon failure.

Retries are made after a connection error or after a server error (HTTP status 5xx) occurs.

It will intelligently determine whether the server it's downloading from properly supports ranged requests,
and if it doesn't, then upon failure it will stop asking for a resume and request the complete file again
from scratch.

It will request the original user-provided request in its next attempts, not the one that may have resulted from
redirections of the first attempt.

The C<$tx> object returned is the last HTTP transaction that took place.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::Resume> adds the following attribute to the L<Mojo::UserAgent> object:

=head2 max_attempts

    my $ua = $class->new;
    $ua->max_attempts(5);

The number of attempts it will try (at most). Defaults to 1.

What matters for each download is the value this attribute held at the time the first attempt of that download was
started.

=head1 TODO

=over 1

=item * Write tests

=item * Check whether the module should also check whether "content received < total_size_based_on_headers" when
determining whether to retry

=item * Add events

=back

Other than the above, this module works.

=head1 SPONSORS

This module was sponsored.

=head1 LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KARJALA Corp E<lt>karjala@cpan.orgE<gt>

=cut

