use warnings;
use strict;
use Test::Most tests => 24;
use Test::Moose;

require_ok('Siebel::Srvrmgr::OS::Process');

my $proc;

ok(
    $proc = Siebel::Srvrmgr::OS::Process->new(
        {
            pid    => 4568,
            fname  => 'siebmtshmw',
            pctcpu => 0.35,
            pctmem => 10,
            rss    => 12345,
            vsz    => 123456
        }
    ),
    'can create a instance of Process'
);

foreach my $attrib (qw(pid fname pctcpu pctmem rss vsz comp_alias tasks_num)) {

    has_attribute_ok( $proc, $attrib );

}

can_ok( $proc,
    qw(get_pid get_fname get_pctcpu get_pctmem get_rss get_vsz get_comp_alias get_tasks_num set_comp_alias _build_set _set_tasks_num set_tasks_num is_comp)
);

is( $proc->get_pid,    4568,         'get_pid returns the correct value' );
is( $proc->get_fname,  'siebmtshmw', 'get_fname returns the correct value' );
is( $proc->get_pctcpu, 0.35,         'get_pctcpu returns the correct value' );
is( $proc->get_pctmem, 10,           'get_pctmem returns the correct value' );
is( $proc->get_rss,    12345,        'get_rss returns the correct value' );
is( $proc->get_vsz,    123456,       'get_vsz returns the correct value' );
isnt( $proc->is_comp, 1, 'process is not from a component' );
ok( $proc->set_comp_alias('SRBroker'), 'set_comp_alias works' );
is( $proc->get_comp_alias, 'SRBroker',
    'get_comp_alias returns the correct value' );
ok( $proc->is_comp, 'is_comp returns true' );
dies_ok { $proc->set_tasks_num(0.5) }
'set_tasks_num generates exception with non-integer parameter';
ok( $proc->set_tasks_num(5), 'set_tasks_num works' );
is( $proc->get_tasks_num, 5, 'get_tasks_num returns the correct value' );

