package Tapper::Reports::Web::Controller::Tapper::Reports::Tap;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Reports::Tap::VERSION = '5.0.14';
use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $report_id ) = @_;

        my $report = $c->model('TestrunDB')->resultset('Report')->find($report_id);

        if ($report) {
                if ($report->tap && $report->tap->tap_is_archive) {
                        $c->response->content_type ('application/x-compressed');
                        $c->response->header ("Content-Disposition" => 'inline; filename="tap-'.$report_id.'.tgz"');
                } else {
                        $c->response->content_type ('text/plain');
                        $c->response->header ("Content-Disposition" => 'inline; filename="tap-'.$report_id.'.tap"');
                }
                $c->response->body ($report->tap ? $report->tap->tap : "Error: No TAP for report $report_id.");
        } else {
                $c->response->content_type ("text/plain");
                $c->response->header ("Content-Disposition" => 'inline; filename="nonexistent.report.tap.'.$report_id.'"');
                $c->response->body ("Error: No report $report_id.");
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Reports::Tap

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
