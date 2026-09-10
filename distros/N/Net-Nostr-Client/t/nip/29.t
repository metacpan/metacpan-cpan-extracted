use strictures 2;
use Test2::V0 -no_srand => 1;
use AnyEvent;
use Net::Nostr::Key;
use Net::Nostr::Group;
use Net::Nostr::List;
ok eval { require Net::Nostr::GroupDiscovery; 1 }, 'group discovery module loads';
unless (Net::Nostr::GroupDiscovery->can('new')) { done_testing; exit }
my ($master,$admin,$friend,$stranger,$user) = map { Net::Nostr::Key->new } 1..5;
my (@filters,@callbacks,@candidates,@errors);
my %args = (group_id=>'pizza',relay=>'wss://old.example',relay_pubkey=>$master->pubkey_hex,
    admins=>[$admin->pubkey_hex],trusted_friends=>[$friend->pubkey_hex],
    lookup=>sub { push @filters,$_[0]->to_hash; push @callbacks,$_[1] },
    on_candidate=>sub { push @candidates,$_[0] }, on_error=>sub { push @errors,$_[0] });
for my $bad ({admins=>['bad']},{trusted_friends=>{}},{relay=>'https://bad.example'},
    {relay_pubkey=>'bad'},{lookup=>undef},{on_candidate=>[]},{interval=>0},{group_id=>''},{typo=>1}) {
    ok dies { Net::Nostr::GroupDiscovery->new(%args,%$bad) }, 'strict discovery configuration';
}
my $watch = Net::Nostr::GroupDiscovery->new(%args);
my $list_event = sub {
    my ($key,$timestamp,@tags) = @_;
    return $key->create_event(kind=>10009,created_at=>$timestamp,content=>'',tags=>\@tags);
};
subtest 'offline lookup uses cached admins and trusted friends, and reports forks' => sub {
    $watch->primary_unreachable;
    is shift(@filters), {kinds=>[10009],authors=>[sort($admin->pubkey_hex,$friend->pubkey_hex)]}, 'offline discovery filter';
    my $event = $list_event->($admin,1000,['group','pizza','wss://new.example','Pizza Lovers']);
    shift(@callbacks)->([$event],undef);
    is \@errors, [], 'valid discovery succeeds';
    is scalar @candidates,1,'notifies user about changed relay';
    is $candidates[0]{relay},'wss://new.example','candidate relay';
    is $candidates[0]{group_id},'pizza','group ID remains stable';
    is $watch->relay,'wss://old.example','notification alone does not migrate user';
    $watch->check;
    shift(@callbacks)->([$event],undef);
    is scalar @candidates,1,'same candidate does not repeatedly notify';
    $watch->check;
    my $fork = $list_event->($friend,1000,['group','pizza','wss://fork.example']);
    shift(@callbacks)->([$fork],undef);
    is scalar @candidates,2,'trusted friend may report an independent fork';
    $watch->check;
    shift(@callbacks)->([$list_event->($stranger,1001,['group','pizza','wss://evil.example'])],undef);
    is scalar @candidates,2,'untrusted authors do not influence discovery';
};
subtest 'cache signed admins before the primary relay goes offline' => sub {
    my $event = Net::Nostr::Group->admins(pubkey=>$master->pubkey_hex,group_id=>'pizza',
        members=>[{pubkey=>$admin->pubkey_hex,roles=>['admin']},{pubkey=>$user->pubkey_hex,roles=>['admin']}]);
    $master->sign_event($event);
    $watch->cache_admins($event);
    is $watch->admins,[sort($admin->pubkey_hex,$user->pubkey_hex)],'cached validated admin list';
    push @{$watch->admins},$stranger->pubkey_hex;
    is scalar @{$watch->admins},2,'cache accessor is defensive';
    $watch->primary_unreachable;
    my $filter=pop @filters;
    is $filter->{authors},[sort($admin->pubkey_hex,$user->pubkey_hex,$friend->pubkey_hex)],'offline filter uses refreshed cache';
    shift(@callbacks)->([],undef);
    my $wrong = Net::Nostr::Group->admins(pubkey=>$stranger->pubkey_hex,group_id=>'pizza',members=>[]);
    $stranger->sign_event($wrong);
    like dies { $watch->cache_admins($wrong) },qr/relay|author/,'wrong relay cannot replace admin cache';
};
subtest 'newest announcements win and malformed or forged input is rejected' => sub {
    $watch->check;
    shift(@callbacks)->([$list_event->($admin,2000,['group','pizza','wss://old.example'])],undef);
    my $count = @candidates;
    $watch->check;
    shift(@callbacks)->([$list_event->($admin,999,['group','pizza','wss://obsolete.example'])],undef);
    is scalar @candidates,$count,'stale alternate hint ignored';
    for my $bad ($list_event->($admin,3000,['group','pizza','javascript:bad']),
        $list_event->($admin,3001,['group','pizza']),
        Net::Nostr::Event->new(%{$list_event->($admin,3002,['group','pizza','wss://bad.example'])->to_hash},sig=>'0'x128)) {
        $watch->check;
        my $before=@errors;
        shift(@callbacks)->([$bad],undef);
        is scalar @errors,$before+1,'bad lookup result reports an error';
        is scalar @candidates,$count,'bad data cannot generate migration candidate';
    }
};
subtest 'periodic discovery is opt-in and can be stopped' => sub {
    my $ticks=0;
    my $periodic=Net::Nostr::GroupDiscovery->new(%args,interval=>0.02,
        lookup=>sub { $ticks++; $_[1]->([],undef) });
    is $ticks,0,'constructor does not start network work';
    $periodic->start;
    my $cv=AnyEvent->condvar;
    my $timer=AnyEvent->timer(after=>0.07,cb=>sub { $cv->send });
    $cv->recv;
    ok $ticks>=2,'start checks immediately and periodically';
    $periodic->stop;
    my $before=$ticks;
    $cv=AnyEvent->condvar;
    $timer=AnyEvent->timer(after=>0.04,cb=>sub { $cv->send });
    $cv->recv;
    is $ticks,$before,'stop cancels periodic checks';
};
subtest 'in-flight discovery honors the current administrator roster' => sub {
    my ($complete,@seen);
    my $local=Net::Nostr::GroupDiscovery->new(%args,
        lookup=>sub { $complete=$_[1] },on_candidate=>sub { push @seen,$_[0] });
    $local->check;
    my $removed=Net::Nostr::Group->admins(pubkey=>$master->pubkey_hex,group_id=>'pizza',members=>[]);
    $master->sign_event($removed);
    $local->cache_admins($removed);
    $complete->([$list_event->($admin,4000,['group','pizza','wss://revoked.example'])],undef);
    is \@seen,[],'removed administrator cannot redirect a pending lookup';
    for my $tags ([['d','pizza'],['d','pizza']],
        [['d','pizza'],['p',$admin->pubkey_hex]],
        [['d','pizza'],['p',$admin->pubkey_hex,'admin'],['p',$admin->pubkey_hex,'admin']]) {
        my $malformed=$master->create_event(kind=>39001,content=>'',tags=>$tags);
        like dies { $local->cache_admins($malformed) },qr/admin|group|role/,'malformed cache metadata rejected';
    }
};

subtest 'timeouts, duplicate completions, and overlapping requests are bounded' => sub {
    my (@pending,@failed,@seen);
    my $local=Net::Nostr::GroupDiscovery->new(%args,timeout=>0.02,
        lookup=>sub { push @pending,$_[1] },on_error=>sub { push @failed,$_[0] },on_candidate=>sub { push @seen,$_[0] });
    $local->check;
    $local->primary_unreachable;
    is scalar @pending,1,'offline signal reuses pending lookup';
    my $cv=AnyEvent->condvar;
    my $timer=AnyEvent->timer(after=>0.05,cb=>sub { $cv->send });
    $cv->recv;
    like $failed[0],qr/timed out/,'timeout reported';
    $pending[0]->([$list_event->($admin,4000,['group','pizza','wss://too-late.example'])],undef);
    is \@seen,[],'late completion ignored';
    $local->check;
    is scalar @pending,2,'timeout allows retry';
    $pending[1]->([],undef);
    $pending[1]->([$list_event->($admin,4001,['group','pizza','wss://duplicate.example'])],undef);
    is \@seen,[],'second completion ignored';
};

subtest 'raw group IDs and case-insensitive naddr references remain distinct' => sub {
    for my $case (['naddr1raw-group','naddr1raw-group'], ['pizza',uc(Net::Nostr::Group->format_id(
        pubkey=>$master->pubkey_hex,group_id=>'pizza',relay=>'wss://old.example'))]) {
        my ($id,$reference)=@$case;
        my ($complete,@seen,@failed);
        my $local=Net::Nostr::GroupDiscovery->new(%args,group_id=>$id,
            lookup=>sub {$complete=$_[1]},on_candidate=>sub {push @seen,$_[0]},on_error=>sub {push @failed,$_[0]});
        $local->check;
        $complete->([$list_event->($admin,4000,['group',$reference,'wss://new.example'])],undef);
        is \@failed,[],'valid group reference accepted';
        is scalar @seen,1,'alternate relay discovered';
    }
};

subtest 'explicit migration builds a signed user list and retains other forks' => sub {
    my $own=Net::Nostr::List->new(kind=>10009);
    $own->add('group','pizza','wss://old.example','Pizza');
    $own->add('group','pizza','wss://independent.example','Other fork');
    $own->add('group','other','wss://old.example','Other group');
    $own->add('r','wss://old.example');
    $own->add_private('group','pizza','wss://old.example','Private copy');
    my $event=$own->to_event(pubkey=>$user->pubkey_hex,key=>$user,created_at=>1000);
    $user->sign_event($event);
    my $moved=$watch->migration_event(relay=>'wss://new.example',event=>$event,key=>$user);
    ok lives { $moved->validate },'migration event signed by user';
    my $parsed=Net::Nostr::List->from_event($moved,key=>$user);
    is $parsed->items,[['group','pizza','wss://new.example','Pizza'],
        ['group','pizza','wss://independent.example','Other fork'],
        ['group','other','wss://old.example','Other group'],['r','wss://old.example'],['r','wss://new.example']],
        'only selected group and relay instance moves';
    is $parsed->private_items,[['group','pizza','wss://new.example','Private copy']], 'private participation updated and reencrypted';
    is $event->created_at,1000,'input event unchanged';
    is $watch->relay,'wss://old.example','builder does not silently change active relay';
    like dies { $watch->migration_event(relay=>'wss://new.example',event=>$event,key=>$stranger) },qr/author|key/,'must own list';
    like dies { $watch->migration_event(relay=>'ftp://bad',event=>$event,key=>$user) },qr/relay/,'bad migration relay rejected';
};
subtest 'review: unrelated raw group IDs cannot poison discovery or migration' => sub {
    my ($complete,@seen,@failed);
    my $local=Net::Nostr::GroupDiscovery->new(%args,
        lookup=>sub {$complete=$_[1]},on_candidate=>sub {push @seen,$_[0]},on_error=>sub {push @failed,$_[0]});
    my @tags=(['group','pizza','wss://new.example'],['group','naddr1raw-other','wss://other.example']);
    $local->check;
    $complete->([$list_event->($admin,5000,@tags)],undef);
    is \@failed, [], 'arbitrary unrelated raw ID accepted';
    is scalar @seen,1,'valid alternate hint still found';
    my $old=$list_event->($user,1000,['group','pizza','wss://old.example'],$tags[1]);
    my $moved;
    ok lives {$moved=$local->migration_event(event=>$old,key=>$user,relay=>'wss://new.example')}, 'migration accepts raw other IDs';
    is [grep {$_->[0] eq 'group'} @{$moved->tags}], \@tags, 'unrelated raw ID retained' if $moved;
};

done_testing;
