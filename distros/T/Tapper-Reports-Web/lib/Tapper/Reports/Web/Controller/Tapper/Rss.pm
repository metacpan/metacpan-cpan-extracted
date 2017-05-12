package Tapper::Reports::Web::Controller::Tapper::Rss;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Rss::VERSION = '5.0.13';
use XML::Feed;
use DateTime;
use Tapper::Reports::Web::Util::Filter::Report;

use parent 'Catalyst::Controller';

use common::sense;
## no critic (RequireUseStrict)


sub index :Path :Args()
{
        my ($self,$c, @args) = @_;

        my $filter = Tapper::Reports::Web::Util::Filter::Report->new(context => $c);
        my $dtf = $c->model("TestrunDB")->storage->datetime_parser;

        my $feed = XML::Feed->new('RSS');
        $feed->title( 'Tapper RSS Feed' );
        $feed->link( $c->req->base ); # link to the site.
        $feed->description('Tapper Reports ');

        my $feed_entry;
        my $title;

        my $filter_condition;

        $filter_condition = $filter->parse_filters(\@args);
        if ( defined $filter_condition->{error} ) {
                $feed_entry  = XML::Feed::Entry->new('RSS');
                $feed_entry->title( $filter_condition->{error} );
                $feed_entry->issued( DateTime->now );
                $feed->add_entry($feed_entry);
        }

        # default 2 days
        if (not $filter_condition->{early}{created_at}) {
                my $now = DateTime->now();
                $now->subtract(days => 2);
                $filter_condition->{early}{created_at} = {'>' => $dtf->format_datetime($now) };
        }


        my $reports = $c->model('TestrunDB')->resultset('Report')->search
          (
           $filter_condition->{early},
           {
            columns   => [ qw( id
                               suite_id
                               created_at
                               machine_name
                               success_ratio
                               successgrade
                               total
                            )],
           }
           );
        foreach my $filter (@{$filter_condition->{late}}) {
                $reports = $reports->search($filter);
        }


        # Process the entries
        while (my $report = $reports->next) {
                $feed_entry  = XML::Feed::Entry->new('RSS');
                $title       = $report->successgrade;
                $title      .= " ".($report->success_ratio // 0)."%";
                $title      .= " ".($report->suite ? $report->suite->name : 'unknown suite');
                $title      .= " @ ";
                $title      .= $report->machine_name || 'unknown machine';
                $feed_entry->title( $title );
                $feed_entry->link( $c->req->base->as_string.'tapper/reports/id/'.$report->id );
                $feed_entry->issued( $report->created_at );
                $feed->add_entry($feed_entry);
        }

        $c->res->body( $feed->as_xml );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Rss

=head1 DESCRIPTION

Catalyst Controller.

=head2 index

Controller for RSS feeds of results reported to Tapper Reports
Framework. The function expectes an unrestricted number of arguments
that are interpreted as filters. Thus, the arguments need to be in pairs
of $filter_type/$filter_value. Since index is a catalyst function the
typical catalyst arguments $self and $c do not occur in the API doc.

@param array - filter arguments

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Hardware - Catalyst Controller

=head1 METHODS

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
