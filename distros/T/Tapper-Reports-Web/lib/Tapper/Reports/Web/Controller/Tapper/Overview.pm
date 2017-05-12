package Tapper::Reports::Web::Controller::Tapper::Overview;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Overview::VERSION = '5.0.13';
use parent 'Tapper::Reports::Web::Controller::Base';
use DateTime;
use Tapper::Reports::Web::Util::Filter::Overview;

use common::sense;
## no critic (RequireUseStrict)

sub auto :Private
{
        my ( $self, $c ) = @_;
        $c->forward('/tapper/overview/prepare_navi');
}


# Filter suite list so that only recently used suites are given.
#
# @param suite result set - unfiltered suites
# @param int/string       - duration
#
# @return suite result set - filtered suites
#
sub recently_used_suites
{
        my ($self, $c, $suite_rs, $duration) = @_;
        my $timeframe;
        if ($duration) {
                return $suite_rs if lc($duration) eq 'all';
                $timeframe = DateTime->now->subtract(weeks => $duration);
        } else {
                $timeframe = DateTime->now->subtract(weeks => 12);
        }
        my $dtf = $c->model("TestrunDB")->storage->datetime_parser;
        $suite_rs  = $suite_rs->search({'reports.created_at' => {'>=' => $dtf->format_datetime($timeframe) }});
        return $suite_rs;
}


sub index :Path  :Args()
{
        my ( $self, $c, $type, @args  ) = @_;

        my $filter = Tapper::Reports::Web::Util::Filter::Overview->new(context => $c);
        my $filter_condition;
        if (not (@args == 1 and lc($args[0]) eq 'all')) {
                $filter_condition = $filter->parse_filters(\@args);
        }

        if ($filter_condition->{error}) {
                $c->stash->{error_msg} = join("; ", @{$filter_condition->{error}});
                $c->res->redirect("/tapper/overview/");
        }
        $filter_condition->{early} =  {} unless
          defined($filter_condition->{early}) and
            ref($filter_condition->{early}) eq 'HASH' ;

        given ($type) {
                when('suite') {$self->suite($c, $filter_condition)};
                when('host')  {$self->host($c, $filter_condition)};
        }
}

sub suite
{
        my ( $self, $c, $filter_condition ) = @_;

        my %search_options    = ( prefetch => ['reports'] );

        my $suite_rs = $c->model('TestrunDB')->resultset('Suite')->search($filter_condition->{early}, { %search_options } );
        foreach my $filter (@{$filter_condition->{late}}) {
                $suite_rs = $suite_rs->search($filter);
        }
        $c->stash->{overviews} = {};
        while ( my $suite = $suite_rs->next ) {
                $c->stash->{overviews}{$suite->name} = '/tapper/reports/suite/'.($suite->name =~ /[^\w\d_.-]/ ? $suite->id : $suite->name);
        }
        $c->stash->{title} = "Tapper report suites";
}

sub host
{
        my ( $self, $c, $filter_condition ) = @_;

        my $reports = $c->model('TestrunDB')->resultset('Report')->search($filter_condition->{early},
                                                                          { columns => [ qw/machine_name/ ],
                                                                            distinct => 1,
                                                                          });
        while ( my $report = $reports->next ) {
                $c->stash->{overviews}{$report->machine_name} = '/tapper/reports/host/'.$report->machine_name;
        }
        $c->stash->{title} = "Tapper report hosts";
}



sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        $c->stash->{navi}= [{
                             title => 'Overview of',
                             subnavi => [
                                         {
                                          title => 'Suites',
                                          href  => "/tapper/overview/suite/weeks/2",
                                         },
                                         {
                                          title => 'Hosts',
                                          href  => "/tapper/overview/host/weeks/2",
                                         },
                                        ],

                            },
                            {
                             title => 'Suites used in the last..',
                             subnavi => [
                                         {
                                          title => '1 week',
                                          href  => "/tapper/overview/suite/weeks/1",
                                         },
                                         {
                                          title => '2 weeks',
                                          href  => "/tapper/overview/suite/weeks/2",
                                         },
                                         {
                                          title => '6 weeks',
                                          href  => "/tapper/overview/suite/weeks/6",
                                         },
                                         {
                                          title => '12 weeks',
                                          href  => "/tapper/overview/suite/weeks/12",
                                         },
                                        ],
                            },
                            {
                             title => 'Hosts used in the last..',
                             subnavi => [
                                         {
                                          title => '1 week',
                                          href  => "/tapper/overview/host/weeks/1",
                                         },
                                         {
                                          title => '2 weeks',
                                          href  => "/tapper/overview/host/weeks/2",
                                         },
                                         {
                                          title => '6 weeks',
                                          href  => "/tapper/overview/host/weeks/6",
                                         },
                                         {
                                          title => '12 weeks',
                                          href  => "/tapper/overview/host/weeks/12",
                                         },
                                        ],

                            },
                            {
                             title => 'All suites',
                             href  => '/tapper/overview/suite/all',
                            }
                           ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Overview

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
