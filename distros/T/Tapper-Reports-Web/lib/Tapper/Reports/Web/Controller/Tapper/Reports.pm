package Tapper::Reports::Web::Controller::Tapper::Reports;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Reports::VERSION = '5.0.13';
use parent 'Tapper::Reports::Web::Controller::Base';

use strict;
use warnings;

use DateTime::Format::Natural;
use Data::Dumper;

use Tapper::Reports::Web::Util::Filter::Report;
use Tapper::Reports::Web::Util::Report;
use common::sense;


sub index :Path :Args() {

        my ( $self, $c, @args ) = @_;

        exit 0 if $args[0] eq 'exit';

        my $filter = Tapper::Reports::Web::Util::Filter::Report->new(context => $c);
        my $filter_condition = $filter->parse_filters(\@args);

        if ($filter_condition->{error}) {
                $c->flash->{error_msg} = join("; ", @{$filter_condition->{error}});
                $c->res->redirect("/tapper/reports");

        }

        $c->stash->{requested_day} =
          $filter->requested_day || DateTime::Format::Natural->new->parse_datetime("today at midnight");

        $filter->{early}->{-or} = [{rga_primary => 1}, {rgt_primary => 1}];

        $c->forward('/tapper/reports/prepare_this_weeks_reportlists', [ $filter_condition ]);
        $c->forward('/tapper/reports/prepare_navi');

}

sub prepare_this_weeks_reportlists : Private {

        my ( $or_self, $or_c, $hr_filter_condition ) = @_;

        my $b_view_pager  = 0;
        my $hr_params     = $or_c->req->params;
        my $hr_query_vals = {
            report_id           => $hr_filter_condition->{report_id},
            suite_id            => $hr_filter_condition->{suite_id},
            machine_name        => $hr_filter_condition->{host},
            success_ratio       => $hr_filter_condition->{success_ratio},
            successgrade        => $hr_filter_condition->{successgrade},
            owner               => $hr_filter_condition->{owner},
        };

        require DateTime;
        if ( $hr_params->{report_date} ) {
            $hr_filter_condition->{report_date} = DateTime::Format::Strptime->new(
                pattern => '%F',
            )->parse_datetime( $hr_params->{report_date} );
        }
        elsif (! $hr_filter_condition->{report_id} ) {
                $hr_filter_condition->{report_date} = DateTime->now();
        }
        if ( $hr_params->{pager_sign} && $hr_params->{pager_value} ) {
            if ( $hr_params->{pager_sign} eq 'negative' ) {
                $hr_filter_condition->{report_date}->subtract(
                    $hr_params->{pager_value} => 1
                );
            }
            elsif ( $hr_params->{pager_sign} eq 'positive' ) {
                $hr_filter_condition->{report_date}->add(
                    $hr_params->{pager_value} => 1
                );
            }
        }

        if ( $hr_filter_condition->{report_date} ) {

            $or_c->stash->{pager_interval}  = $hr_params->{pager_interval} || 1;
            $or_c->stash->{report_date}     = $hr_filter_condition->{report_date};

            # set report date
            my $d_report_date_from = $hr_filter_condition->{report_date}->clone->subtract( days => $or_c->stash->{pager_interval} - 1 )->strftime('%d %b %Y');
            my $d_report_date_to   = $hr_filter_condition->{report_date}->strftime('%d %b %Y');

            if ( $d_report_date_from ne $d_report_date_to ) {
                $or_c->stash->{head_overview}   = "Reports ($d_report_date_to - $d_report_date_from)";
            }
            else {
                $or_c->stash->{head_overview}   = "Reports ($d_report_date_from)";
            }

            $hr_query_vals->{report_date_from} = $hr_filter_condition->{report_date}->clone->subtract( days => $or_c->stash->{pager_interval} - 1 )->strftime('%F');
            $hr_query_vals->{report_date_to}   = $hr_filter_condition->{report_date}->strftime('%F');

            $or_c->stash->{view_pager} = 1;

        }
        else {
            $or_c->stash->{head_overview}   = 'Testruns';
        }

        $or_c->stash->{reports} = $or_c->model('TestrunDB')->fetch_raw_sql({
                query_name  => 'reports::web_list',
                fetch_type  => '@%',
                query_vals  => $hr_query_vals,
        });

        return 1;

}


sub prepare_navi : Private {

        my ( $self, $c ) = @_;
        $c->stash->{navi} = [];

        my %args = @{$c->req->arguments};

        $c->stash->{navi} = [
                {
                        title  => "reports by suite",
                        href   => "/tapper/overview/suite",
                },
                {
                        title  => "reports by host",
                        href   => "/tapper/overview/host",
                },
                {
                        title  => "This list as RSS",
                        href   => "/tapper/rss/".$self->prepare_filter_path($c),
                        image  => "/tapper/static/images/rss.png",
                },
                {
                        title  => "reports by people",
                        href   => "/tapper/reports/people/",
                        active => 0,
                },
        ];

        my @a_subnavi;
        my @a_args = @{$c->req->arguments};

        OUTER: for ( my $i = 0; $i < @a_args; $i+=2 ) {
                my $s_reduced_filter_path = q##;
                for ( my $j = 0; $j < @a_args; $j+=2 ) {
                        next if $i == $j;
                        $s_reduced_filter_path .= "/$a_args[$j]/" . $a_args[$j+1];
                }
                push @a_subnavi, {
                        title   => "$a_args[$i]: ".$a_args[$i+1],
                        href    => '/tapper/reports'
                                 . $s_reduced_filter_path
                                 . '?report_date='
                                 . $c->stash->{report_date}->strftime('%F')
                                 . '&amp;pager_interval='
                                 . $c->stash->{pager_interval},
                        image   => '/tapper/static/images/minus.png',
                };
        } # OUTER

        push @{$c->stash->{navi}},
            { title   => 'Active Filters', subnavi => \@a_subnavi, },
            { title   => 'New Filters', id => 'idx_new_filter' },
            { title   => 'Help', id => 'idx_help', subnavi => [{ title => 'Press Shift for multiple Filters' }] },
        ;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Reports

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
