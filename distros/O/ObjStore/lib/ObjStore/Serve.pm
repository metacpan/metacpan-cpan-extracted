use 5.005; #probably
use strict;
package ObjStore::Serve;
use Carp;
use Exporter ();
use Event 0.42 qw(loop unloop_all);
use ObjStore;
use base 'ObjStore::HV';
use vars qw($VERSION @ISA @EXPORT_OK $SERVE $Init $TXOpen);
$VERSION = '0.06';
push @ISA, 'Exporter', 'osperlserver';
@EXPORT_OK = qw(&txqueue &txretry &seconds_delta &dyn_begin &dyn_commit
		&init_signals &meter &exitloop $ChkptEv);

my $meter_warn=0;
sub meter {
    carp "meter is deprecated" if ++$meter_warn > 5;
}
use vars qw(@TXready @TXtodo);
sub txretry {
    use attrs 'locked';
    lock $TXOpen;
    push @TXready, map { { retry => 1, code => $_ } } @_;
}
sub txqueue {
    use attrs 'locked';
    lock $TXOpen;
    if ($TXOpen) {
        $_->() for @_;
    } else {
        push @TXready, map { { retry => 0, code => $_ } } @_;
    }
}

sub seconds_delta {
    my ($d) = @_;
    if ($d <120) {
	if ($d != int $d) {
	    sprintf "%.2f secs", $d
	} else {
	    "$d sec" . ($d > 1?'s':'')
	}
    }
    elsif ($d < 2*60*60) { int($d/60) ." minutes" }
    elsif ($d < 2*60*60*24) { int($d/(60**2))." hours" }
    else { int($d/(60*60*24))." days" }
}

sub get_all_versions {
    # adapted from Devel::Symdump!
    my ($V, @todo) = @_;
    my @more;
    for my $pack (@todo) {
	no strict;
	while (my ($key,$val) = each %{*{"$pack\::"}}) {
	    local(*ENTRY) = $val;
	    if (defined $val and defined *ENTRY{HASH} and $key =~ /::$/ and 
		$key ne "main::") {

		my($p) = $pack ne "main" ? "$pack\::" : "";
		($p .= $key) =~ s/::$//;
		my $ver = $ {"$p\::VERSION"} if defined $ {"$p\::VERSION"};
		$V->{$p} = $ver if $ver;
		push @more, $p;
	    }
	}
    }
    get_all_versions($V, @more) if @more;
    $V;
}

use Time::Local;
use vars qw($TodaySeconds);
sub cache_todayseconds {
    $TodaySeconds = int timelocal(0,0,0,(localtime)[3,4,5]);
}
cache_todayseconds();

sub form_time {
    my $t;
    $t = Event::time() - $TodaySeconds;
    if ($t > 3600 * 24) {
	cache_todayseconds();
	$t = Event::time() - $TodaySeconds;
    }
    my $h = int($t/3600);
    $t -= $h * 3600;
    my $m = int($t/60);
    $t -= $m * 60;
    my $s = int $t;
    $t -= $s;
    my $f = sprintf "%.3f", $t;
    sprintf "%02d:%02d:%02d%s", $h, $m, $s, substr($f,1);
}

sub install_warn_timestamp {
    # This is useful in general.  Split this into a separate tarball? XXX

    my $epat = qr/\[\d\d:\d\d:\d\d\.\d\d\d \d+\]/;
    $SIG{__WARN__} =
	sub { 
	    if ($_[0] !~ /^$epat/) {
		warn '['.form_time()." $$]: $_[0]"
	    } else {
		warn $_[0];
	    }
	};

    # $SIG{__DIE__} can wreck havoc on the exception system
}

sub restart {
    my ($o) = @_;

    install_warn_timestamp();

    # If we made it here, our assumption is that the database
    # is not currently being serviced by a live server.
    # We take control.
    $ObjStore::TRANSACTION_PRIORITY = 0x8000;

    $SERVE = $o->new_ref('transient','hard');
    my $h = $$o{history} ||= [];
    my $now = time;
    my $V = get_all_versions({},'main');
    $V->{'perl'} = $];
    $h->UNSHIFT({ VERSION => $V, restart => $now, mtime => $now,
		  recent => [], total => {} });
}

sub VERSION {
    my ($o,$p,$req) = @_;
    return $o->SUPER::VERSION($p) if $p =~ /^[\d\._]$/;
    my $v = $o->{history}[0]{VERSION}{$p} || 0;
    if (defined $req and $req > $v) {
	croak "$p version $req required--this is only version $v"
    } else { $v }
}

# Don't wait forever! XXX
for (qw(read write)) { ObjStore::lock_timeout($_,15); }

sub init_signals {
    for my $sig (qw(INT TERM)) {
	Event->signal(desc => "ObjStore::Serve $sig", signal => $sig,
		      cb => sub { unloop_all("SIG$sig\n"); });
    }
}

################################################# UTIL

use vars qw($Aborts $Commits $LoopTime @Commit);
$LoopTime = 2;

my $LoopState;

sub before_checkpoint {
    my ($t) = @_;
    die $LoopState if $LoopState ne 'start';
    $LoopState = 'before';

    $TXOpen=0;
    $t ||= ObjStore::Transaction::get_current();
    if ($SERVE and !$t->is_aborted) {
	eval {
	    my $now = time;

	    # make sure we're still in charge
	    ObjStore::ServerInfo->touch($now);  #why method call? XXX

	    # update various stats
	    my $o = $SERVE->focus;

	    for (@Commit) { $_->($o, $now) }

	    my $r = $o->{history}[0];

	    do {
		local $^W=0; #lexical warnings XXX
		my $tot = $$r{total};
		if ($Aborts) { $tot->{aborts} += $Aborts; $Aborts = 0; }
		if ($Commits) { $tot->{commits} += $Commits; $Commits = 0; }
	    };
	    $$r{mtime} = $now;
	    
	    $LoopTime = $$o{looptm} ||= $LoopTime;
	    $t->post_transaction(); #1
	};
	if ($@) { $t->abort; warn; }
    }
    $t->is_aborted? ++$Aborts : ++$Commits;
}

sub after_checkpoint {
    die $LoopState if $LoopState ne 'before';
    $LoopState = 'after';
}

sub start_transaction {
    $LoopState ||= 'after';
    die $LoopState if $LoopState ne 'after';
    $LoopState = 'start';

    $TXOpen = 1;
    push @TXready, @TXtodo;
    @TXtodo = ();
}

use vars qw($TXN $UseOSChkpt);
sub dotodo {
    confess "no transaction" if !lock $TXOpen;
    my @c = @TXready;
    @TXready = ();
    while (@c) {
	my $j = shift @c;
	eval {
	    my $c = $$j{code};
	    if ($$j{retry}) { push @TXtodo, $j if !$c->(); }
	    else { $c->(); }
	};
	if ($@) { $TXN->abort; warn; last }  # is this correct? XXX
    }
    unshift @TXtodo, @c;
}

sub dyn_start {
    if (!$TXN) {
	confess "Cannot nest dynamic transactions"
	    if @ObjStore::Transaction::Stack;
	$TXN = ObjStore::Transaction->new($SERVE? 'update' : 'read');
    }
    start_transaction();
    dotodo();
}

sub dyn_commit {
    my $continue = shift;
    if ($TXN) {
	before_checkpoint($TXN);
        if ($UseOSChkpt and $continue and
	    !ObjStore::Transaction::is_aborted($TXN)) {
            # This will not work properly until Object Design
	    # fixes the checkpoint code. XXX
            $TXN->checkpoint();
        } else {
            $TXN->commit();
            undef $TXN;
        }
        after_checkpoint();
    }
}

################################################# default
use vars qw($ChkptEv);
sub prepare_default {
    require ObjStore::Serve::Notify;
    ObjStore::Serve::Notify::init_autonotify();
    if (!$Init) { &init_signals; ++$Init }
    $ChkptEv = Event->timer(desc => 'ObjStore::Serve checkpoint',
			    nice => -1, hard => 0, repeat => 0,
			    interval => \$LoopTime, max_cb_tm => 60,
			    cb => sub {
				eval { dyn_commit($ChkptEv->repeat) };
				if ($@) { warn; unloop_all() }
			    });
    $Event::DIED = sub {
	my ($run, $why) = @_;
	my $desc = $run ? $run->w->desc : '?';
	my $how = 'died';
	if ($TXN and !$TXN->is_aborted) {
	    $TXN->abort;
	    $how = 'aborted';
	}
	my $m = "Event '$desc' $how: $why";
	$m .= "\n" if $m !~ m/\n$/;
	warn $m;
    };
}

sub defaultLoop {
    prepare_default();
    loop();
}

# For continuous transactions:
#
# $ChkptEv->{e_repeat} = 1;
# Event->add_hooks(callback => \&dyn_begin);

sub dyn_begin {
    return if ($TXN and !ObjStore::Transaction::is_aborted($TXN));
    # the eval should never be triggered -- but we want to be extra careful
    eval {
	dyn_commit(1) if $TXN; #was aborted
	dyn_start(); 
	$ChkptEv->again
	    if defined $ChkptEv;
    };
    if ($@) { warn; unloop_all() }
}

################################################# VERY EXPERIMENTAL!!
################################################# threads (single)

use vars qw($Status $LoopLevel $ExitLevel);
$LoopLevel = $ExitLevel = 0;

sub Loop_async {
    warn "EXPERIMENTAL";
    my ($Q) = @_;
    local $Status = undef;
    local $LoopLevel = $LoopLevel+1;
    ++$ExitLevel;
    warn 1;
    while ($ExitLevel >= $LoopLevel) {
	warn 1;
	begin 'update', sub {
	    # not thread-safe? XXX
#	    Event->timer(-after => $LoopTime, -callback => sub {
#			     $Q->enqueue(DATA => 0, PRIORITY => 1)
#			 });
	    # XXX
	    warn 1;
            start_transaction();
	    dotodo() if @TXready;
	    while (1) {
		my $do = $Q->dequeue;
		warn $do;
		last if !ref $do;  #checkpoint
		$do->();
	    }
	    warn 1;
	    before_checkpoint();
	    warn 1;
	};
	warn 1;
	warn if $@;
	after_checkpoint();
    }
    $Status
}

################################################# VERY EXPERIMENTAL!!
################################################# threads (multi)

sub Loop_mt {
    warn "EXPERIMENTAL";
    my ($o) = @_;
    local $Status = undef;
    local $LoopLevel = $LoopLevel+1;
    ++$ExitLevel;
    if (!$Init) { &init_signals; ++$Init; }
    while ($ExitLevel >= $LoopLevel) {
        {
	    # UNUSEABLE FOR UPDATES XXX

	    # can't lock here, otherwise nested looping
	    # can't switch transactions
#	    lock $TXOpen;
	    eval {
	        {
		    lock $TXOpen;
		    dotodo() if $TXOpen && @TXready;
		}
		doOneEvent();
	    };
	    if ($@) {
		warn;
		# can't XXX
#		my $tx = ObjStore::Transaction::get_current();
#		$tx->abort() if $tx;
	    }
	}
    }
    $Status
}

sub async_checkpoint {
    warn "EXPERIMENTAL";
    # regex are not thread-safe! XXX
    while ($ExitLevel >= 1) {
        my $tx;
        do { 
            lock $TXOpen;
	    # think about updates XXX
            $tx ||= ObjStore::Transaction->new('global', 'read');
            start_transaction();
        };
        sleep $LoopTime;   #fractional? XXX
        do {
            lock $TXOpen;
	    before_checkpoint($tx);
	    if ($UseOSChkpt and !$tx->is_aborted and $tx->top_level) {
		$tx->checkpoint();
	    } else {
		$tx->commit();
		$tx = undef;
	    }
            after_checkpoint();
        };
    }
}

################################################# Exit

sub exitloop {
    carp "exitloop is deprecated";
    unloop_all();
}

1;
__END__

=head1 NAME

ObjStore::Serve - event loop integration

=head1 SYNOPSIS

=head1 DESCRIPTION

EXPERIMENTAL package to integrate ObjStore transactions with Event.
Implements dynamic transactions.

Great service is key.

=head1 SEE ALSO

L<Event>, L<ObjStore>

=cut
