use strict;
use warnings;

# vim:ts=4:shiftwidth=4:expandtab

use Test::More;
use MogileFS::Server;
use MogileFS::Test;
use MogileFS::Plugin::FileRefs;
use MogileFS::Worker::Query;
use Test::Exception;
use Time::HiRes qw/ gettimeofday /;

my $sto = eval { temp_store(); };
if (!$sto) {
        plan skip_all => "Can't create temporary test database: $@";
            exit 0;
}

my $store = Mgd::get_store;
isa_ok($store, 'MogileFS::Store');

lives_ok { $store->create_table("file_ref") };

open(my $null, "+>", "/dev/null") or die $!;
my $query = MogileFS::Worker::Query->new($null);
isa_ok($query, 'MogileFS::Worker::Query');

my $sent_to_parent;

no strict 'refs';
*MogileFS::Worker::Query::send_to_parent = sub {
    $sent_to_parent = $_[1];
};
use strict;

note "Testing add refs";

my $domfac = MogileFS::Factory::Domain->get_factory;
ok($domfac, "got a domain factory");

{
# Add in a test domain.
    my $dom = $domfac->set({ dmid => 1, namespace => 'eee'});
    ok($dom, "made a new domain object");
    is($dom->id, 1, "domain id is 1");
    is($dom->name, 'eee', 'domain namespace is toast');
}

is($store->create_domain("eee"), 1);

my $resp = qr/^[0-9]+(?:\.[0-9]+)? OK /;

is(add_file_ref($query, {domain => "zzz", arg1 => "zz", arg2 => "00001"}), undef);
like($sent_to_parent, qr/ERR unreg_domain Domain\+name\+invalid\/not\+found$/);

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is_deeply(x($sent_to_parent), { made_new_ref => 1 });

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is_deeply(x($sent_to_parent), { made_new_ref => 1 }, "Update counts as successful creation.");

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is_deeply(x($sent_to_parent), { made_new_ref => 1 }, "Update counts as successful creation.");

note "Testing del refs";

is(del_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is_deeply(x($sent_to_parent), { deleted_ref => 1 });

is(del_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is_deeply(x($sent_to_parent), { deleted_ref => 0 });

note "Testing rename";

is(rename_if_no_refs($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { files_outstanding => 0, updated => 0 });

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is(rename_if_no_refs($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "1");
is_deeply(x($sent_to_parent), { files_outstanding => 1 });

$store->replace_into_file( dmid => 1, key => "zz", fidid => 1, classid => 1, devcount => 0 );
is(rename_if_no_refs($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "1");
is_deeply(x($sent_to_parent), { files_outstanding => 1 });

is(del_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is(rename_if_no_refs($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { files_outstanding => 0, updated => 1 });

is(rename_if_no_refs($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { files_outstanding => 0, updated => 0 });

note "Testing locking behaviour";
my $fighting_dbh = DBI->connect($store->{dsn}, $store->{user}, $store->{pass}, {
    PrintError => 1,
    AutoCommit => 1,
    RaiseError => 1,
});

isa_ok($fighting_dbh, 'DBI::db');

is($fighting_dbh->do("SELECT GET_LOCK('mogile-filerefs-eee-zz', 20)"), 1);

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "0");
like($sent_to_parent, qr/ERR get_key_lock_fail get_key_lock_fail$/);

is(rename_if_no_refs($query, {domain => "eee", arg1 => "zz", arg2 => "yy"}), "0");
like($sent_to_parent, qr/ERR get_key_lock_fail get_key_lock_fail$/);

is($fighting_dbh->do("SELECT RELEASE_LOCK('mogile-filerefs-eee-zz')"), 1);
$fighting_dbh = undef;

note "Testing list_refs_for_key";

is(list_refs_for_dkey($query, {domain => "eee", arg1 => "zz"}), "1");
is_deeply(x($sent_to_parent), { total => 0 });

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is(list_refs_for_dkey($query, {domain => "eee", arg1 => "zz"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { total => 1, ref_0 => '00001' });

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00001"}), "1");
is(list_refs_for_dkey($query, {domain => "eee", arg1 => "zz"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { total => 1, ref_0 => '00001' });

is(add_file_ref($query, {domain => "eee", arg1 => "zz", arg2 => "00002"}), "1");
is(list_refs_for_dkey($query, {domain => "eee", arg1 => "zz"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { total => 2, ref_0 => '00001', ref_1 => '00002' });

is(add_file_ref($query, {domain => "eee", arg1 => "yy", arg2 => "00003"}), "1");
is(list_refs_for_dkey($query, {domain => "eee", arg1 => "zz"}), "1");
like($sent_to_parent, $resp);
is_deeply(x($sent_to_parent), { total => 2, ref_0 => '00001', ref_1 => '00002' });


done_testing();

sub add_file_ref {
    $_[0]->{querystarttime} = [gettimeofday];
    $sent_to_parent = undef;
    return MogileFS::Plugin::FileRefs::add_file_ref(@_);
}

sub del_file_ref {
    $_[0]->{querystarttime} = [gettimeofday];
    $sent_to_parent = undef;
    return MogileFS::Plugin::FileRefs::del_file_ref(@_);
}

sub list_refs_for_dkey {
    $_[0]->{querystarttime} = [gettimeofday];
    $sent_to_parent = undef;
    return MogileFS::Plugin::FileRefs::list_refs_for_dkey(@_);
}

sub rename_if_no_refs {
    $_[0]->{querystarttime} = [gettimeofday];
    $sent_to_parent = undef;
    return MogileFS::Plugin::FileRefs::rename_if_no_refs(@_);
}

sub x {
    my $s = shift;
    if ($s =~ qr/^[0-9]+(?:\.[0-9]+)? OK (.*)$/) {
        my $z = $1;
        return {
            map { split(qr/=/, $_) } split(qr/\&/, $z)
        }
    }
    else {
        warn "couldn't decode response: $s";
        return {};
    }
}
