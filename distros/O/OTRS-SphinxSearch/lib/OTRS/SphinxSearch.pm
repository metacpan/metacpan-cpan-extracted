# ABSTRACT: Implementation of the OTRS search engine by Sphinx search
package OTRS::SphinxSearch;

use strict;
use warnings;

use 5.006001;

use vars qw($VERSION);

our $VERSION = '0.011'; # VERSION

use Sphinx::Search 0.28;
use Time::Piece;
use Readonly;

Readonly my $ADDITIVE                 =>                  86_400;
Readonly my $SOURCE_PORT              =>                    9312;
Readonly my $CONNECT_TIME_OUT         =>                     300;
Readonly my $CONNECT_RETRIES          =>                       2;
Readonly my $SEARCH_LIMIT             =>                    1000;
Readonly my $MAX_QUERY_TIME           =>                       0;
Readonly my $MATCH_MODE               =>      SPH_MATCH_EXTENDED;
Readonly my $SORT_MODE                =>       SPH_SORT_EXTENDED;
Readonly my $RANK_MODE                => SPH_RANK_PROXIMITY_BM25;
Readonly my $DEFAULT_SORT_BY          =>           'create_time';
Readonly my $DEFAULT_ORDER_BY         =>                  'DESC';
Readonly my $DEFAULT_RESULT_FORMAT    =>                 'ARRAY';
Readonly my $SELECTED_FIELD           =>                    'id';



sub new {
    my ($class, %param) = @_;

    my $self = {};
    bless $self, $class;

    # Init connection params
    $self->{config} = $param{config} if defined $param{config};

    return unless $self->{config}->{'Index'};

    $self->{index} = $self->{config}->{'Index'};

    $self->{sphinx_object}    = Sphinx::Search->new();

    $self->{source_host}      = $self->{config}->{'SourceHost'}
        || 'localhost';
    $self->{source_port}      = $self->{config}->{'SourcePort'}
        || $SOURCE_PORT;
    $self->{connect_timeout}  = $self->{config}->{'ConnectTimeOut'}
        || $CONNECT_TIME_OUT;
    $self->{connect_retries}  = $self->{config}->{'ConnectRetries'}
        || $CONNECT_RETRIES;
    $self->{search_limit}     = $self->{config}->{'SearchLimit'}
        || $SEARCH_LIMIT;
    $self->{max_query_time}   = $self->{config}->{'MaxQueryTime'}
        || $MAX_QUERY_TIME;
    $self->{match_mode}       = int ($self->{config}->{'MatchMode'}
        || $MATCH_MODE);
    $self->{sort_mode}        = int ($self->{config}->{'SortMode'}
        || $SORT_MODE);
    $self->{rank_mode}        = int ($self->{config}->{'RankMode'}
        || $RANK_MODE);
    $self->{field_weights}    = $self->{Config}->{'FieldWeights'}
        || {};

    $self->{sort_by}          = $self->{config}->{'SortBy'}
        || $DEFAULT_SORT_BY;
    $self->{order_by}         = $self->{config}->{'OrderMode'}
        || $DEFAULT_ORDER_BY;
    $self->{selected_field}   = $self->{config}->{'SelectedField'}
        || $SELECTED_FIELD;
    $self->{result}           = $DEFAULT_RESULT_FORMAT;


    # Text search params type association with a fields of index
    $self->{text_field_map} = {
        From              => 'a_from',
        To                => 'a_to',
        Cc                => 'a_cc',
        Subject           => 'a_subject',
        Body              => 'a_body',
        TicketNumber      => 'tn',
        Title             => 'title',
        CustomerID        => 'customer_id',
        CustomerUserLogin => 'customer_user_id',
    };

    # Integer and MVA search params type association with a fields of index
    $self->{uint_field_map} = {
        TypeIDs         => 'type_id',
        StateIDs        => 'ticket_state_id',
        QueueIDs        => 'queue_id',
        CreatedQueueIDs => 'created_queue_id',
        PriorityIDs     => 'ticket_priority_id',
        OwnerIDs        => 'user_id',
        LockIDs         => 'ticket_lock_id',
        StateTypeIDs    => 'ticket_state_id',
        WatchUserIDs    => 'watch_user_id',
        ResponsibleIDs  => 'responsible_user_id',
        ServiceIDs      => 'service_id',
        SLAIDs          => 'sla_id',
        ArchiveFlag     => 'archive_flag',
    };

    # Time associations portion
    $self->{time_field_map} = {
        ArticleTimeSearchType    => 'ArticleCreate',
        TimeSearchType           => 'TicketCreate',
        ChangeTimeSearchType     => 'TicketChange',
        CloseTimeSearchType      => 'TicketClose',
        EscalationTimeSearchType => 'TicketEscalation',
    };
    $self->{time_filter_map} = {
        ArticleCreate    => 'a_create_time',
        TicketCreate     => 'create_time',
        TicketChange     => 'change_time',
        TicketClose      => 'change_time',
        TicketEscalation => 'escalation_time',
    };
    $self->{time_dimension_map} = {
        second => 1,
        minute => 60,
        hour   => 3600,
        day    => 86_400,
        week   => 604_800,
        month  => 2_678_400,
        year   => 31_536_000,
    };

    $self->{sort_map} = {
        Owner                  => 'user_id',
        Responsible            => 'responsible_user_id',
        CustomerID             => 'customer_id',
        State                  => 'ticket_state_id',
        Lock                   => 'ticket_lock_id',
        Ticket                 => 'tn',
        TicketNumber           => 'tn',
        Title                  => 'title',
        Type                   => 'type_id',
        Queue                  => 'queue_id',
        Priority               => 'ticket_priority_id',
        Age                    => 'create_time',
        Changed                => 'change_time',
        Service                => 'service_id',
        SLA                    => 'sla_id',
        PendingTime            => 'until_time',
        TicketEscalation       => 'escalation_time',
        EscalationTime         => 'escalation_time',
        EscalationUpdateTime   => 'escalation_update_time',
        EscalationResponseTime => 'escalation_response_time',
        EscalationSolutionTime => 'escalation_solution_time',
    };

    $self->{order_map} = {
        Up      => 'ASC',
        Down    => 'DESC',
    };

    return $self;
}


sub search {
    my ( $self, %param ) = @_;

    # Init general query settings
    if ($param{'Result'}) {
        $self->{result} = $param{'Result'};
    }

    if ($param{'SortBy'} && $self->{sort_map}->{ $param{'SortBy'} }) {
        $self->{sort_by} = $self->{sort_map}->{ $param{'SortBy'} };
    }

    if ($param{'OrderBy'} &&  $self->{order_map}->{ $param{'OrderBy'} }) {
        $self->{order_by} = $self->{order_map}->{ $param{'OrderBy'} };
    }

    if ( $self->{sort_mode} == $SORT_MODE ) {
        $self->{sort_expr} = "$self->{sort_by} $self->{order_by}";
    }

    # Set query body
    if ( $param{'Fulltext'} ) {
        $self->{query} .= '@(a_from,a_to,a_cc,a_subject,a_body) ' . "$param{'Fulltext'} ";
    }

    # Set query body additional
    while ( my ($key, $value) = each %{ $self->{text_field_map} } ) {
            # next if attribute is not used
            next unless $param{$key};

            $self->{query} .= q{@} . "$value $param{$key} ";
    }

    # Set field filters with uint values
    while ( my ($key, $value) = each %{ $self->{uint_field_map} } ) {
        next unless defined $param{$key};
        next unless ref $param{$key} eq 'ARRAY';

        # $param{'SomeFieldIDsExclude'} = 1|0
        $param{ $key . 'Exclude' } ||= 0;

        # $sph->SetFilter($attr, \@values, $exclude = 0);
        $self->{sphinx_object}->SetFilter(
            $value,
            \@{ $param{$key} },
            $param{ $key . 'Exclude' }
        );
    }

    # Set time filters
    while ( my ($key, $value) = each %{ $self->{time_field_map} } ) {
        next unless defined $param{$key};

        # If we are have more one a time filters reset it
        ( $self->{time_start}, $self->{time_stop} ) = undef;

        if ( $param{$key} eq 'TimePoint' ) {
            $self->_get_time_point({
                time_point_start  => $param{$value.'TimePointStart'},
                time_point        => $param{$value.'TimePoint'},
                time_point_format => $param{$value.'TimePointFormat'},
                time_point_base   => $param{$value.'TimePointBase'} || 0,
            });
        }
        elsif ( $param{$key} eq 'TimeSlot' ) {
            $self->_get_time_slot({
                time_start_day   => $param{$value.'TimeStartDay'},
                time_start_month => $param{$value.'TimeStartMonth'},
                time_start_year  => $param{$value.'TimeStartYear'},
                time_stop_day    => $param{$value.'TimeStopDay'},
                time_stop_month  => $param{$value.'TimeStopMonth'},
                time_stop_year   => $param{$value.'TimeStopYear'},
            });
        }

        if ( defined $self->{time_start} && defined $self->{time_stop} ) {
            $self->{sphinx_object}->SetFilterRange(
                $self->{time_filter_map}->{$value},
                $self->{time_start},
                $self->{time_stop},
            );
        }
    }

    # Connect setup
    $self->{sphinx_object}->SetServer( $self->{source_host}, $self->{source_port} );
    $self->{sphinx_object}->SetConnectTimeout( $self->{connect_timeout} );
    $self->{sphinx_object}->SetConnectRetries( $self->{connect_retries} );

    # General query settings
    $self->{sphinx_object}->SetLimits( 0, $self->{search_limit} );
    $self->{sphinx_object}->SetMaxQueryTime( $self->{max_query_time} );
    $self->{sphinx_object}->SetSelect( $self->{selected_field} );
    $self->{sphinx_object}->SetMatchMode( $self->{match_mode} );
    $self->{sphinx_object}->SetRankingMode( $self->{rank_mode} );
    $self->{sphinx_object}->SetFieldWeights( $self->{field_weights} );
    $self->{sphinx_object}->SetSortMode( $self->{sort_mode}, $self->{sort_expr} );

    # Query
    my $tickets = $self->{sphinx_object}->Query(
        $self->{query},
        $self->{index},
    );

    my $returns;
    my @ticket_ids;

    # Return count of the result
    if ( $self->{result} eq 'COUNT' ) {
        $returns->{viewable_ticket_ids} = $tickets->{total_found};
    }

    # Return array of the result
    elsif ( $self->{result} eq 'ARRAY' ) {
        @ticket_ids = map { $_->{id} } @{ $tickets->{matches} };

        $returns->{viewable_ticket_ids} = \@ticket_ids;
    }

    # True if connection failed
    my $error = 0;
    $error = 1 if $self->{sphinx_object}->IsConnectError();
    $returns->{error} = $error;

    return $returns;
}

# Private


sub _get_time_slot {
    my ( $self, $param ) = @_;

    for (qw(time_start_day time_start_month time_start_year
        time_stop_day time_stop_month time_stop_year
    )) {
        return unless defined $param->{$_};
    }

    my ($time_start, $time_stop);
    eval {
        $time_start = Time::Piece->strptime(
            $param->{time_start_day}.'.'
            .$param->{time_start_month}.'.'
            .$param->{time_start_year},
            '%d.%m.%Y',
        );

        $time_stop = Time::Piece->strptime(
            $param->{time_stop_day}.'.'
            .$param->{time_stop_month}.'.'
            .$param->{time_stop_year},
            '%d.%m.%Y',
        );
    };
    return if ($@);

    $self->{time_start} = $time_start->epoch;
    $self->{time_stop} = $time_stop->epoch + $ADDITIVE;

    return $self;
}


sub _get_time_point {
    my ( $self, $param ) = @_;

    for ( qw(time_point_start time_point time_point_format) ) {
        return unless defined $param->{$_};
    }
    return unless $param->{time_point_start} =~ m/Last|Before/;
    return unless defined $self->{time_dimension_map}->{ $param->{time_point_format} };

    my $time_point =
        $param->{time_point} * $self->{time_dimension_map}->{ $param->{time_point_format} };

    $self->{time_start} = 0;
    $self->{time_stop}  = time;

    if ( $param->{time_point_start} eq 'Last' ) {
        $self->{time_start} = $self->{time_stop} - $time_point;
    }
    elsif ( $param->{time_point_start} eq 'Before' ) {
        $self->{time_stop}  -= $time_point;
    }

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::SphinxSearch - Implementation of the OTRS search engine by Sphinx search

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use OTRS::SphinxSearch;
    my $sphinx_search = OTRS::SphinxSearch->new(
        config => $otrs_sphinx_search_config_part, # Optional
    );

    ... some manipulation with request data ...

    my $results = $sphinx_search->search(
        SortBy  => $sort_by,            # Optional, default is 'create_time'
        OrderBy => $order_by,           # Optional, default is 'DESC'
        Result  => 'ARRAY' | 'COUNT',   # Default is 'ARRAY'
        %Param,                         # Required
    );

=head1 DESCRIPTION

The module is designed as an alternative to the native search OTRS.
It serves to generate search queries from OTRS to the full-text
search engine Sphinx through module Sphinx::Search.
Using this module requires some changes in
the OTRS controller: Modules/AgentTikketsearh.pm. These changes
relate mainly to the processing of input data. For instance queue
names are converted to their IDs. All this is true if you do not
want something exotic.
Config example of the Sphinx and important parts of
the controller are located in the directory "samples/".

=head1 METHODS

=head2 new()

Create new OTRS::SphinxSearch object

Returns: self object

=head2 search()

Returns: an array with results or count founded results

=head2 _get_time_slot()

Get start and stop time points in UNIX format from calendar format start and stop points

Returns: Self object with hash refs
    $self->{time_start}
    $self->{time_stop}

=head2 _get_time_point

Get start and stop time points before or after some time

Returns: Self object with hash refs
    $self->{time_start}
    $self->{time_stop}

=head1 CONFIGURATION AND ENVIRONMENT

Minimum configuration required to submit name of the index which will be used
for searching.
Before using this module you will be needed create index. Sample of the Sphinx
config you can find in samples/ directory. Also you will be needed override
the method which will be get and parse fields of search form. The name of this
module is AgentTicketSearch.pm (trimmed version you can look in samples/ directory).

=head1 DEPENDENCIES

The Sphinx::Search version 0.28 or highter.

=head1 SEE ALSO

=over 4

=item *

L<Sphinx:Search>

=item *

L<Time::Piece>

=back

=head1 AUTHOR

Iurii Shikin <shikin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
