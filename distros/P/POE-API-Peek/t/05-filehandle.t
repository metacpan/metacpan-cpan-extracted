
# Tests for filehandle related code. See code block labeled "Filehandle fun"

use Test::More tests => 11;

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

# handle_count {{{
    my $handle_count;
    eval { $handle_count = $api->handle_count() };
    ok(!$@, 'handle_count() causes no exceptions');
    is($handle_count, 0, 'handle_count() returns proper count');
# }}}

# session_handle_count {{{
    my $sess_handle_count;
    eval { $sess_handle_count = $api->session_handle_count() };
    ok(!$@, 'session_handle_count() causes no exceptions');
    is($sess_handle_count, 0, 'session_handle_count() returns proper count');

    my $new_handle_count;
    eval { $new_handle_count = $api->session_handle_count($sess) };
    ok(!$@, 'session_handle_count(session) causes no exceptions');
    is($new_handle_count, 0, 'session_handle_count(session) returns proper count');

    eval { $new_handle_count = $api->session_handle_count($sess->ID) };
    ok(!$@, 'session_handle_count(ID) causes no exceptions');
    is($new_handle_count, 0, 'session_handle_count(ID) returns proper count');


# }}}

# is_handle_tracked {{{
    use IO::Handle;
    my $io = IO::Handle->new();
    $io->fdopen(fileno(STDIN),'r');

    my $bool;
    eval { $bool = $api->is_handle_tracked($io, 'r') };
    ok(!$@, "is_handle_tracked() causes no exceptions");
    is($bool, 0, 'is_handle_tracked() properly returns that STDIN is not being tracked');

    $io->close();
# }}}

}


sub _stop {


}
