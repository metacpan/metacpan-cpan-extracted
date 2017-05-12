package Sub::Retry;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.06';
use parent qw/Exporter/;
use Time::HiRes qw/sleep/;

our @EXPORT = qw/retry/;

sub retry {
    my ( $times, $delay, $code, $retry_if ) = @_;

    my $err;
    $retry_if ||= sub { $err = $@ };
    my $n = 0;
    while ( $times-- > 0 ) {
        $n++;
        if (wantarray) {
            my @ret = eval { $code->($n) };
            unless ($retry_if->(@ret)) {
                return @ret;
            }
        }
        elsif (not defined wantarray) {
            eval { $code->($n) };
            unless ($retry_if->()) {
                return;
            }
        }
        else {
            my $ret = eval { $code->($n) };
            unless ($retry_if->($ret)) {
                return $ret;
            }
        }
        sleep $delay if $times; # Do not sleep in last time
    }
    die $err if $err;
}

1;
__END__

=encoding utf8

=head1 NAME

Sub::Retry - retry $n times

=head1 SYNOPSIS

    use Sub::Retry;
    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    my $res = retry 3, 1, sub {
        my $n = shift;
        $ua->post('http://example.com/api/foo/bar');
    };

=head1 DESCRIPTION

Sub::Retry provides the function named 'retry'.

=head1 FUNCTIONS

=over 4

=item retry($n_times, $delay, \&code [, \&retry_if])

This function calls C<< \&code >>. If the code throws exception, this function retry C<< $n_times >> after C<< $delay >> seconds.

Return value of this function is the return value of C<< \&code >>. This function cares L<wantarray>.

You can also customize the retry condition. In that case C<< \&retry_if >> specify CodeRef. The CodeRef arguments is return value the same. (Default: retry condition is throws exception)

    use Sub::Retry;
    use Cache::Memcached::Fast;

    my $cache = Cache::Memcached::Fast->new(...);
    my $res = retry 3, 1, sub {
        $cache->get('foo');
    }, sub {
        my $res = shift;
        defined $res ? 0 : 1;
    };

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
