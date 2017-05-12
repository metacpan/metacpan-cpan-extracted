use Test::Spec;

use OTRS::SphinxSearch;

my $config = {Index => 'test_index'};
my $uint_field_map = {
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

describe "OTRS::SphinxSearch" => sub {
    my $oss = OTRS::SphinxSearch->new(config => $config);

    it "can't compile without config" => sub {
        is(OTRS::SphinxSearch->new(), undef);
    };
    it "compile with config" => sub {
        isa_ok($oss, 'OTRS::SphinxSearch');
    };
    it "with blessed Sphinx::Search object" => sub {
        isa_ok($oss->{sphinx_object}, 'Sphinx::Search');
    };
    it "should compile" => sub {
        cmp_deeply($uint_field_map, $oss->{uint_field_map});
    };
};

runtests unless caller;
