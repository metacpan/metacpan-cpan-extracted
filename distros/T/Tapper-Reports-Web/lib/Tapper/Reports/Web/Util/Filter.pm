package Tapper::Reports::Web::Util::Filter;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Util::Filter::VERSION = '5.0.15';
use DateTime;
use Data::Dumper;
use DateTime::Format::DateParse;
use Hash::Merge::Simple 'merge';
use Tapper::Model 'model';

use Moose;



use common::sense;

has 'context'         => (is => 'rw');
has 'requested_day'   => (is => 'rw');
has 'dispatch'        => (is        => 'rw',
                          isa       => 'HashRef',
                          # builder   => 'build_dispatch',
                          # init_arg  => undef,
                         );

sub BUILD{
        my $self = shift;
        my $args = shift;

        $self->dispatch(
                        merge($self->dispatch, {days => \&days,
                                                date => \&date,
                                               })
                       );
}




sub date
{
        my ($self, $filter_condition, $date) = @_;
        return $self->days($filter_condition, $date) if $date =~m/^\d+$/; # handle old date links correctly

        if (defined($self->requested_day)) {
                push @{$filter_condition->{error}}, "'date' and 'days' filter can not be used together.";
                return $filter_condition;
        }

        $filter_condition->{days} = 1;

        my $requested_day;
        my $one_day_later;
        eval {
                $requested_day = DateTime::Format::DateParse->parse_datetime( $date, 'GMT' );
                $one_day_later = DateTime::Format::DateParse->parse_datetime( $date, 'GMT' )->add(days => 1);
        };
        if (not defined $requested_day) {
                push @{$filter_condition->{error}}, "Can not parse date '$date'";
                return $filter_condition;
        }

        my $dtf = model("TestrunDB")->storage->datetime_parser;

        $filter_condition->{date} = $requested_day->ymd('/');
        $self->requested_day($requested_day);
        push @{$filter_condition->{late}}, {created_at => {'<='  => $dtf->format_datetime($one_day_later)}};
        return $filter_condition;
}


sub days
{
        my ($self, $filter_condition, $days) = @_;

        if (defined($self->requested_day)) {
                push @{$filter_condition->{error}}, "'date' and 'days' filter can not be used together.";
                return $filter_condition;
        }
        $filter_condition->{days} = $days;
        my $parser = DateTime::Format::Natural->new(time_zone => 'GMT');
        my $requested_day  = $parser->parse_datetime("today at midnight");
        $self->requested_day($requested_day);

        my $dtf = model("TestrunDB")->storage->datetime_parser;

        my $yesterday = $parser->parse_datetime("today at midnight")->subtract(days => $days);
        $filter_condition->{early}->{created_at} = {'>' => $dtf->format_datetime($yesterday)};
        return $filter_condition;
}


sub parse_filters
{
        my ($self, $args, $allowed_filters) = @_;
        my @args = ref($args) eq 'ARRAY' ? @$args : ();
        my $filter_condition = {};
        while (@args) {
                my $key   = shift @args;
                my $value = shift @args;

                if (ref $allowed_filters eq 'ARRAY' and not grep {$_ eq $key} @$allowed_filters) {
                        $filter_condition->{error} = "Can not filter for $key";
                        return $filter_condition;
                }

                if (not $self->dispatch->{$key}) {
                        my @errors = @{$filter_condition->{error} || [] };
                        $filter_condition = {};
                        push @errors, "Can not parse filter $key/$value. No filters applied";
                        $filter_condition->{error} = \@errors;
                        return $filter_condition;
                }
                $filter_condition = $self->dispatch->{$key}->($self, $filter_condition, $value);
        }
        return $filter_condition;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Util::Filter

=head2 date

Add a date to late filters. Furthermore, it sets the days value. Date
used to filter for the number of days (now provided by function
'days'). For backwards compatibility it checks whether the input to mean
day rather than days and forwards accordingly.

@param hash ref - current version of filters
@param string   - date

@return hash ref - updated filters

=head2 parse_filters

Parse filter arguments given by controller. The function expects an
array ref containing the filter arguments. This is achieved by providing
the arguments that Catalyst provide for a sub with :Args().

The second argument is a list of word that are valid filters.

The function returns a hash ref containing the following elements (not
necessarily all every time):
* early    - hash ref  - contains the filter conditions that can be given
                         in the initial search on reports
* late     - array ref - list of hash refs that contain filter conditions
                         which shall be applied as $report->search{$key => $value}
                         after the initial search returned a $report already
* function - hash ref  - functions that are to be applied as $report->$key($value);
* error    - array ref - contains all errors that occured as strings
* days     - int       - number of days that will be shown
* date     - string    - the exact date that will be shown

@param array ref - list of filter arguments
@param array ref - list of allowed filters

@return hash ref

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
