use strict;
use warnings;

use File::Basename;
use Test::More;

BEGIN {
    push(@INC, dirname(__FILE__));
}

use mock_rpc qw(common);

use Test::MockModule;

use Net::FreeIPA;
use Net::FreeIPA::API::Magic;

use version;

use Net::FreeIPA::Common;

my $mockbase = Test::MockModule->new("Net::FreeIPA::Base");

$mockbase->mock('debug', sub {shift; diag "debug: @_"});

my $error;
$mockbase->mock('error', sub {shift; $error = \@_; diag "error: @_"});

my $warn;
$mockbase->mock('warn', sub {shift; $warn = \@_; diag "warn: @_"});

# Should not change by accident
is_deeply(\%Net::FreeIPA::Common::FIND_ONE, {
    aci => 'aciname',
    cert => 'cn',
    delegation => 'aciname',
    dnsforwardzone => 'idnsname',
    dnsrecord => 'idnsname',
    dnszone => 'idnsname',
    group => 'cn',
    host => 'fqdn',
    hostgroup => 'fqdn',
    server => 'cn',
    service => 'krbprincipalname',
    trust => 'cn',
    user => 'uid',
    vault => 'cn',
}, "FIND_ONE as expected");

my $f = Net::FreeIPA->new("myhost");

=head2 unknown method

=cut

$error = undef;
ok(! defined($f->find_one('woohaha', 100)), "unsupported method returns undef");
is($error->[0], "find_one: unknown API method api_woohaha_find",
   "unsupported method reports error");

=head2 method without mapping

=cut

# batch will never have a find, so will never end up in the map
# inject it here in the cache
Net::FreeIPA::API::Magic::cache({name => 'batch_find'});

$error = undef;
ok(! defined($f->find_one('batch', 100)), "not-mapped attr method returns undef");
is($error->[0], "find_one: no supported attribute for api batch",
   "not-mapped attr method reports error");

=head2 find_one: method fails

=cut

$error = undef;
reset_POST_history();
ok(! defined($f->find_one('host', 'my.host')), "failed method returns undef");
ok(POST_history_ok(["0 host_find  all=1,fqdn=my.host,"]), "api_host_find called with correct args/opts id=0");
ok($f->{response}->{error} == 'unittest error', "answer with error result");
like($error->[0], qr{^host_find got error}, "failed method reports error");

=head2 find_one: method finds no answers

=cut

# return 1 for success, but count=0
$error = undef;
reset_POST_history();
$f->{id} = 1;
ok(! defined($f->find_one('host', 'my.host')), "0 answers returns undef");
ok(POST_history_ok(["1 host_find  all=1,fqdn=my.host,"]), "api_host_find called with correct args/opts id=1");
is($f->{response}->{answer}->{result}->{count}, 0, "result with count=0");
ok(! defined($error), "no error reported");

=head2 find_one: one answer

=cut

$error = undef;
reset_POST_history();
$f->{id} = 2;
is_deeply($f->find_one('host', 'my.host'), {unittest => 1}, "return result");
ok(POST_history_ok(["2 host_find  all=1,fqdn=my.host,"]), "api_host_find called with correct args/opts id=2");
is($f->{response}->{answer}->{result}->{count}, 1, "result with count=1");
ok(! defined($error), "no error reported");

=head2 find_one: 2 answers

=cut

# return 1 for success, count=2, result
$warn = undef;
$error = undef;
reset_POST_history();
$f->{id} = 3;
is_deeply($f->find_one('host', 'my.host'), {unittest => 2}, "return first result");
ok(POST_history_ok(["3 host_find  all=1,fqdn=my.host,"]), "api_host_find called with correct args/opts id=3");
is($f->{response}->{answer}->{result}->{count}, 2, "result with count=2");
is($warn->[0], 'one_find method api_host_find and value my.host returns 2 answers',
   "warn reported on more than one answer");
ok(! defined($error), "no error reported");


=head2 do_one: fail and error

=cut

# add
$error = undef;
reset_POST_history();
$f->{id} = 0;
ok(! defined($f->do_one('host', 'add', 'my.host')),
   "do_one host add fails id=0");
ok(POST_history_ok(["0 host_add my.host "]), "api_host_add called with correct args/opts id=0");
like($error->[0], qr{^host_add got error}, "error reported");

# mod with NotFound gives error
$error = undef;
reset_POST_history();
$f->{id} = 1;
ok(! defined($f->do_one('host', 'mod', 'my.host')),
   "do_one host mod fails id=1");
ok(POST_history_ok(["1 host_mod my.host "]), "api_host_mod called with correct args/opts id=1");
ok($f->{response}->{error}->is_not_found(), 'NotFound error');
like($error->[0], qr{^host_mod got error}, "failed method reports error");

=head2: do_one: fail, pass __noerror and no error

=cut

$error = undef;
reset_POST_history();
$f->{id} = 0;
ok(! defined($f->do_one('host', 'add', 'my.host', __noerror => ['unittest'])),
   "do_one host add fails id=0 and __noerror passed");
ok(POST_history_ok(["0 host_add my.host "]), "api_host_add called with correct args/opts id=0");
ok(! defined($error), "no error reported with add and unittest and __noerror passed");


=head2 do_one: fail and no error

=cut

# add
$error = undef;
reset_POST_history();
$f->{id} = 1;
# also tests if already existing noerror do not interfere
ok(! defined($f->do_one('host', 'add', 'my.host', __noerror => ['unittest'])),
   "do_one host add fails id=1");
ok(POST_history_ok(["1 host_add my.host "]), "api_host_add called with correct args/opts id=1");
ok($f->{response}->{error}->is_duplicate(), 'DuplicateEntry error');
ok(! defined($error), "no error reported with add and DuplicateEntry");

$error = undef;
reset_POST_history();
$f->{id} = 4;
ok(! defined($f->do_one('host', 'find', 'my.host')),
   "do_one host mod fails id=4");
ok(POST_history_ok(["4 host_find my.host "]), "api_host_find called with correct args/opts id=4");
ok($f->{response}->{error}->is_not_found(), 'NotFound error');
ok(! defined($error), "no error reported with find and NotFound");

$error = undef;
reset_POST_history();
$f->{id} = 1;
ok(! defined($f->do_one('host', 'disable', 'my.host')),
   "do_one host disable fails id=1");
ok(POST_history_ok(["1 host_disable my.host "]), "api_host_disable called with correct args/opts id=1");
ok($f->{response}->{error}->is_already_inactive(), 'AlreadyInactive error');
ok(! defined($error), "no error reported with disable and AlreadyInactive");


=head2 do_one: success, no error

=cut

# test result_path
$error = undef;
reset_POST_history();
$f->{id} = 2;
is_deeply($f->do_one('host', 'add', 'my.host', __result_path => 'result/result/unittest'),
          {woohoo => 1}, "return result with custom result_path");
ok(POST_history_ok(["2 host_add my.host "]), "api_host_add called with correct args/opts id=2");
ok(! defined($error), "no error reported");


done_testing();
