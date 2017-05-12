use Test::Spec;
use Test::MockTime qw( set_fixed_time restore_time );

use OTRS::SphinxSearch;

set_fixed_time(time);

my $config = {Index => 'test_index'};
my %sort_default_params = (Result => 'REGRU');
my %sort_custom_params = (
    Result  => 'REGRU',
    SortBy  => 'State',
    OrderBy => 'Up'
);
my %sort_invalid_params = (
    Result  => 'REGRU',
    SortBy  => 'SomeState',
    OrderBy => 'AAAAAA'
);
my %query_fulltext = (
    Result  => 'REGRU',
    Fulltext => 'ASDFasdf'
);
my %query_custom = (
    Result       => 'REGRU',
    TicketNumber => '1234509876',
);

my %uint_valid1_filter = (
    Result          => 'REGRU',
    CreatedQueueIDs => [ 100, 111 ],
);
my @uint_valid1_filter = (
    {
        attr    => 'created_queue_id',
        values  => [ 100, 111 ],
        exclude => 0
    }
);
my %uint_valid2_filter = (
    Result          => 'REGRU',
    OwnerIDs        => [ 100 ],
    OwnerIDsExclude => 1,
);
my @uint_valid2_filter = (
    {
        attr    => 'user_id',
        values  => [ 100 ],
        exclude => 1
    }
);
my %uint_invalid_filter = (
    Result          => 'REGRU',
    CreatedQueueIDs => 100,
);
my @get_time_slot_data_sets = (
    {
        comment => 'on incomplete data set',
        data => {
            time_start_month => 10,
            time_start_year  => 2014,
            time_stop_day    => 4,
            time_stop_month  => 11,
            time_stop_year   => 2014,
        },
        result => {
            time_start => undef,
            time_stop  => undef
        }
    },
    {
        comment => 'on invalid data set',
        data => {
            time_start_day   => 3,
            time_start_month => 'october',
            time_start_year  => 2014,
            time_stop_day    => 4,
            time_stop_month  => 11,
            time_stop_year   => 2014,
        },
        result => {
            time_start => undef,
            time_stop  => undef
        }
    },
    {
        comment => 'on correct data set',
        data => {
            time_start_day   => 3,
            time_start_month => 10,
            time_start_year  => 2014,
            time_stop_day    => 4,
            time_stop_month  => 11,
            time_stop_year   => 2014,
        },
        result => {
            time_start => 1412294400,
            time_stop  => 1415145600
        }
    },
);

my @get_time_point_data_sets = (
    {
        comment => 'on incomplete data set',
        data => {
            time_point_start => 'Last',
            time_point       => 2,
        },
        result => {
            time_start => undef,
            time_stop  => undef
        }
    },
    {
        comment => 'on invalid data set 1',
        data => {
            time_point_start  => 'Lasp',
            time_point        => 2,
            time_point_format => 'day',
        },
        result => {
            time_start => undef,
            time_stop  => undef
        }
    },
    {
        comment => 'on invalid data set 2',
        data => {
            time_point_start  => 'Around',
            time_point_format => 'seconds',
            time_point        => 2,
            base_point_day    => 3,
            base_point_month  => 4,
            base_point_year   => 2014,
        },
        result => {
            time_start => undef,
            time_stop  => undef
        }
    },
    {
        comment => 'on correct data set 1',
        data => {
            time_point_start  => 'Before',
            time_point_format => 'day',
            time_point        => 1,
        },
        result => {
            time_start => 0,
            time_stop  => time-86400
        }
    },
    {
        comment => 'on correct data set 2',
        data => {
            time_point_start  => 'Last',
            time_point_format => 'day',
            time_point        => 1,
        },
        result => {
            time_start => time-86400,
            time_stop  => time
        }
    },
);

describe "OTRS::SphinxSearch" => sub {
    my $oss;

    before each => sub {
        $oss = OTRS::SphinxSearch->new(config => $config);
        $oss->{sphinx_object}->expects( 'Query' )
                             ->returns( 0 )
                             ->any_number;
    };

    describe "search()" => sub {
        describe "on set sorting with" => sub {
            it "default params" => sub {
                $oss->search(%sort_default_params);
                is($oss->{sort_expr}, 'create_time DESC');
            };

            it "custom params" => sub {
                $oss->search(%sort_custom_params);
                is($oss->{sort_expr}, 'ticket_state_id ASC');
            };

            it "invalid params" => sub {
                $oss->search(%sort_invalid_params);
                is($oss->{sort_expr}, 'create_time DESC');
            };
        };

        describe "on set query" => sub {
            it "with Fulltext" => sub {
                $oss->search(%query_fulltext);
                is($oss->{query}, '@(a_from,a_to,a_cc,a_subject,a_body) ASDFasdf ');
            };

            it "with custom fields" => sub {
                $oss->search(%query_custom);
                is($oss->{query}, '@tn 1234509876 ');
            };
        };

        describe "on set fiter" => sub {
            before each => sub {
                $oss->{sphinx_object}->stubs( 'SetFilter' => sub {
                    my ($self, $attribute, $values, $exclude) = @_;

                    return unless (defined $attribute);
                    return unless (ref($values) eq 'ARRAY');
                    return unless (scalar(@$values));

                    push @{ $self->{_filter} }, {
                        attr   => $attribute,
                        values => $values,
                        exclude => $exclude ? 1 : 0
                    };

                    return $self;
                });
            };

            it "with uint values" => sub {
                $oss->search(%uint_valid1_filter);
                cmp_deeply($oss->{sphinx_object}->{_filter}, \@uint_valid1_filter);
            };

            it "with excluded uint values" => sub {
                $oss->search(%uint_valid2_filter);
                cmp_deeply($oss->{sphinx_object}->{_filter}, \@uint_valid2_filter);
            };

            it "with invalid uint values" => sub {
                $oss->search(%uint_invalid_filter);
                is($oss->{sphinx_object}->{_filter}, undef);
            };
        };
    };

    describe "_get_time_slot()" => sub {
        foreach my $gtsds (@get_time_slot_data_sets) {
            it "$gtsds->{comment}" => sub {
                my $gts = $oss->_get_time_slot($gtsds->{data});
                my $tmp = {
                    time_start => $gts->{time_start},
                    time_stop  => $gts->{time_stop}
                };

                cmp_deeply($tmp, $gtsds->{result});
            };
        }
    };

    describe "_get_time_point()" => sub {
        foreach my $gtpds (@get_time_point_data_sets) {
            it "$gtpds->{comment}" => sub {
                my $gtp = $oss->_get_time_point($gtpds->{data});
                my $tmp = {
                    time_start => $gtp->{time_start},
                    time_stop  => $gtp->{time_stop}
                };

                cmp_deeply($tmp, $gtpds->{result});
            };
        }
    };
};

runtests unless caller;

restore_time();
