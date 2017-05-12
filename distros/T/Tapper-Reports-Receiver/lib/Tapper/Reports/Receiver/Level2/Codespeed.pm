package Tapper::Reports::Receiver::Level2::Codespeed;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Receiver::Level2::Codespeed::VERSION = '5.0.1';
use strict;
use warnings;

use LWP::UserAgent;
use Data::DPath 'dpath';
use Scalar::Util "reftype";


sub submit
{
        my ($util, $report, $options) = @_;

        my $codespeed_url   = $options->{url};
        my $subscribe_dpath = $options->{subscribe_dpath};

        return unless $codespeed_url && $subscribe_dpath;

        my $max_retry = 5;
        my $tap_dom = $report->get_cached_tapdom;
        my @chunks = dpath($subscribe_dpath)->match($tap_dom);
        @chunks = @{$chunks[0]} while $chunks[0] && reftype $chunks[0] eq "ARRAY"; # deref all array envelops

        return unless @chunks;

        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        foreach my $chunk (@chunks) {
                my $response;
                my $retry = $max_retry;
                do {
                        $response = $ua->post($codespeed_url."/result/add/", $chunk);
                } while ( !$response->is_success and $retry-- );
                $util->log->warn("Submit to $codespeed_url FAILED.") if !$response->is_success;
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Receiver::Level2::Codespeed

=head1 SYNOPSIS

Used indirectly via L<Tapper::Reports::Receiver|Tapper::Reports::Receiver>.

 package Tapper::Reports::Receiver::Level2::Codespeed;

 sub submit
 {
        my ($util, $report, $options) = @_;
        # ... actual data forwarding here
 }

=head2 submit

Submit carved out data from a report to a Codespeed application URL.

=head1 NAME

Tapper::Reports::Receiver::Level2::Codespeed - Tapper - Level2 receiver plugin: Codespeed

=head1 ABOUT

I<Level 2 receivers> are other data receivers besides Tapper to
which data is forwarded when a report is arriving at the
Tapper::Reports::Receiver.

One example is Codespeed to track benchmark values.

By convention, for Codespeed the data is already prepared in the TAP
report like this:

 ok perlformance
   ---
   codespeed:
     -
       benchmark: Rx.regexes.fieldsplit1
       commitid: 1b1a3d2a
       environment: renormalist
       executable: perl-5.12.1-foo
       project: perl
       result_value: 2.58451795578003
     -
       benchmark: Rx.regexes.fieldsplit2
       commitid: 1b1a3d2b
       environment: renormalist
       executable: perl-5.12.1-foo
       project: perl
       result_value: 1.04680895805359
   ...
 ok some other TAP stuff

I.e., it requires a key C<codespeed:> containing an array of chunks
with keys that Codespeed is expecting.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
