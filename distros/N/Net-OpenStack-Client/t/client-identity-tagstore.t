use strict;
use warnings;

use File::Basename;
use Test::More;
use Test::Warnings;


BEGIN {
    push(@INC, dirname(__FILE__));
}

use Test::MockModule;

use Net::OpenStack::Client;
use Net::OpenStack::Client::Identity::Tagstore;
use mock_rest qw(identity_tagstore);
use logger;

my $openrcfn = dirname(__FILE__)."/openrc_example";
ok(-f $openrcfn, "example openrc file exists");

my $cl = Net::OpenStack::Client->new(log => logger->new(), debugapi => 1, openrc => $openrcfn);

=head functions

=over

=item new

=cut

my $ts = Net::OpenStack::Client::Identity::Tagstore->new($cl, "tagprojectid");
isa_ok($ts, 'Net::OpenStack::Client::Identity::Tagstore', 'Tagstore instance returned');
is($ts->{project}, "tagprojectid", "project id attribute set");
is($ts->{client}, $cl, "client attribute set");
is($ts->{log}, $cl, "log is client");
ok(!defined($ts->{cache}), "cache undef after new");
ok(!defined($ts->{counter}), "counter undef after new");

=item fetch / flush

=cut

my $exp_cache = {(map {$_ => 6} (1..70)), (map {$_ => 5} (101..169))};;
$ts->fetch();
#diag "ts after fetch 1 ", explain $ts, explain $exp_cache;
is_deeply($ts->{cache}, $exp_cache, "cache after fetch");
is($ts->{counter}, 5, "counter set to highest child project");

$ts->flush();
ok(!defined($ts->{cache}), "cache undef after flush");

# fake existing cache
my $fake_cache = {a => 1};
$ts->{cache} = $fake_cache;
$ts->fetch();
is_deeply($ts->{cache}, $fake_cache, "existing cache not modified after fetch");

$ts->flush();
ok(!defined($ts->{cache}), "cache undef after flush 2");

$ts->fetch();
is_deeply($ts->{cache}, $exp_cache, "cache after fetch 2");

=item _sane_data

=cut

ok(!defined($ts->_sane_data('some message', undef)), "undef is not sane");
ok(!defined($ts->_sane_data('some message', {a=>0})), "non-scalar is not sane");
ok($ts->_sane_data('some message', 123), "scalar is sane");

=item add

=cut

$ts->add('atag');
is($ts->{cache}->{atag}, 5, "tag added to cache");

$ts->add('atag2');
is($ts->{cache}->{atag2}, 9, "tag added to cache (pid of new project)");
is($ts->{counter}, 6, "new child project with increased counter");

=item get

=cut

is($ts->get('atag'), 5, 'get tag returns project id');
ok(!defined($ts->get('notag')), 'get missing tag returns undef');
ok(!exists($ts->{cache}->{notag}), 'missing tag not vivified in cache');
is_deeply($ts->get(), {%$exp_cache, atag => 5, atag2 => 9}, "get w/o tag returns full cache");

=item delete

=cut

$ts->delete('atag');
ok(!exists($ts->{cache}->{atag}), "tag removed from cache");

=item empty tag subproject

=cut

my $tse = Net::OpenStack::Client::Identity::Tagstore->new($cl, "tagprojectempty");
$tse->fetch();
is_deeply($tse->{empty}, [11113], "one empty subproject");
ok($tse->delete(1));
is_deeply($tse->{empty}, [11113, 11112], "new empty subproject added");
ok($tse->add('atagempty'));
is_deeply($tse->{empty}, [11112], "used first empty subproject to add tag");

diag explain $tse;

=item history

=cut

dump_method_history;
ok(method_history_ok(
       [
        'GET http://controller:35357/v3/projects[?]name=tagprojectid ',
        'GET http://controller:35357/v3/projects[?]parent_id=2 ',
        'GET http://controller:35357/v3/projects[?]parent_id=2 ',
        'PUT http://controller:35357/v3/projects/5/tags/atag \{\} ',
        'POST http://controller:35357/v3/projects .*"name":"tagprojectid_6","parent_id":"2".* ',
        'PUT http://controller:35357/v3/projects/9/tags/atag2 \{\} ',
        'DELETE http://controller:35357/v3/projects/5/tags/atag ',
        'GET http://controller:35357/v3/projects[?]name=tagprojectempty ',
        'GET http://controller:35357/v3/projects[?]parent_id=11111 ',
        'DELETE http://controller:35357/v3/projects/11112/tags/1 ',
        'PUT http://controller:35357/v3/projects/11113/tags/atagempty \{\} ',
       ]), "tagstore history ok");


=pod

=back

=cut

done_testing();
