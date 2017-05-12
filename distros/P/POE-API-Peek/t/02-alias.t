
# Tests for alias related code. See code block labeled "Alias fun"

use Test::More tests => 24;

use warnings;
use strict;
use POE;
use Data::Dumper;

use_ok('POE::API::Peek');

my $api = POE::API::Peek->new();

POE::Session->create(
    inline_states => {
        _start => \&_start,
        _stop => \&_stop,

    },
    heap => { api => $api },
);

POE::Kernel->run();

###############################################

sub _start {
    my $sess = $_[SESSION];
    my $api = $_[HEAP]->{api};
    my $cur_sess;

    my $sid = $sess->ID;

# session_id_loggable {{{
    my $log_id;
    eval { $log_id = $api->session_id_loggable() };
    ok(!$@, "session_id_loggable() causes no exceptions");
    like($log_id, qr/session $sid/, "session_id_loggable() returns proper string when no alias");

    my $new_log_id;
    eval { $new_log_id = $api->session_id_loggable($sess) };
    ok(!$@, "session_id_loggable(session) causes no exceptions");
    is($new_log_id, $log_id, "session_id_loggable(session) returns proper string when no alias");
    eval { $new_log_id = $api->session_id_loggable($sid) };
    ok(!$@, "session_id_loggable(ID) causes no exceptions");
    is($new_log_id, $log_id, "session_id_loggable(ID) returns proper string when no alias");

    $_[KERNEL]->alias_set('PIE');

    $log_id = undef;
    eval { $log_id = $api->session_id_loggable() };
    ok(!$@, "session_id_loggable() causes no exceptions");
    like($log_id, qr/session $sid \(PIE/, "session_id_loggable() returns proper string when alias is set");

# }}}

# session alias_count {{{

    my $alias_count;
    eval { $alias_count = $api->session_alias_count() };
    ok(!$@, "session_alias_count() causes no exceptions");
    is($alias_count, 1, "session_alias_count() returns the proper alias count");

	POE::Session->create(
		inline_states => {
			_start => sub {
                my $new_alias_count;
                eval { $new_alias_count = $api->session_alias_count($sess) };
                ok(!$@, "session_alias_count(session) causes no exceptions");
                is($new_alias_count, $alias_count, "session_alias_count(session) returns the proper alias count");
                eval { $new_alias_count = $api->session_alias_count($sid) };
                ok(!$@, "session_alias_count(ID) causes no exceptions");
                is($new_alias_count, $alias_count, "session_alias_count(ID) returns the proper alias count");
            },
            _stop => sub {},
        }
    );


# }}}

# session_alias_list {{{

    my @aliases;
    eval { @aliases = $api->session_alias_list() };
    ok(!$@, "session_alias_list() causes no exceptions");
    is(scalar @aliases, 1, 'session_alias_list() returns proper amount of data');
    is($aliases[0], 'PIE', 'session_alias_list() returns proper data');
	POE::Session->create(
		inline_states => {
			_start => sub {
                my @new_aliases;
                eval { @new_aliases = $api->session_alias_list($sess) };
                ok(!$@, "session_alias_list(session) causes no exceptions");
                is_deeply(\@new_aliases, \@aliases, 'session_alias_list(session) returns proper data');
                eval { @new_aliases = $api->session_alias_list($sess) };
                ok(!$@, "session_alias_list(ID) causes no exceptions");
                is_deeply(\@new_aliases, \@aliases, 'session_alias_list(ID) returns proper data');
            },
            _stop => sub {},
        }
    );

# }}}

# resolve_alias {{{

    my $session;
    eval { $session = $api->resolve_alias('PIE') };
    ok(!$@, "resolve_alias() causes no exceptions");
    is_deeply($session, $sess, "resolve_alias() resolves the provided alias properly");

# }}}

}


sub _stop {


}
