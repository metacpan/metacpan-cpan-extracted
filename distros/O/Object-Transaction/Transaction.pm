
# Copyright (C) 1999-2002, Internet Journals Corporation <www.bepress.com>.
# Copyright (C) 2002 David Muir Sharnoff
# All rights reserved.  License hearby granted for anyone to use this 
# module at their own risk.   Please feed useful changes back to 
# David Muir Sharnoff <muir@idiom.com>.

package Object::Transaction;

my %cache;

$VERSION = 1.01;
my $lock_debugging = 0;
my $debug = 0;
my $warnings = 0;
my $registered;

require File::Flock;
use Storable;
use POSIX qw(O_CREAT O_RDWR);
require File::Sync;
use Carp;
use Carp qw(verbose);
use vars qw($magic_cookie);
$magic_cookie = "O:Ta";

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(transaction transaction_pending commit abandon uncache);

use strict;

# things to override

sub initialize { die "deferred" }
sub file { die "deferred" }
sub presave {}
sub postsave {}
sub postload {}
sub preload {}
sub preremove {}
sub postremove {}
sub id 
{
	my ($this) = @_;
	return $this->{'ID'};
}
sub precommit {}

# a few wrappers

my %locks;

sub _lock
{
	my ($file) = @_;
	if ($lock_debugging) {
		my ($package, $filename, $line) = caller;
		my ($package2, $filename2, $line2) = caller(1);
		print STDERR "\n{{{{ $file $line, $line2";
	}
	$locks{$file} = 1;
	File::Flock::lock($file);
}

sub _unlock
{
	my ($file) = @_;
	if ($lock_debugging) {
		my ($package, $filename, $line) = caller;
		my ($package2, $filename2, $line2) = caller(1);
		print STDERR "\n}}}} $file $line, $line2";
	}
	delete $locks{$file};
	File::Flock::unlock($file);
}

sub _lockrename
{
	my ($from, $to) = @_;
	if ($lock_debugging) {
		my ($package, $filename, $line) = caller;
		my ($package2, $filename2, $line2) = caller(1);
		print STDERR "{$from->$to} $line, $line2";
	}
	$locks{$to} = $locks{$from};
	delete $locks{$from};
	File::Flock::lock_rename($from, $to);
}

sub _unlock_all
{
	for my $f (keys %locks) {
		_unlock($f);
	}
}

sub _read_file
{
	my ($file) = @_;

	no strict;

	my $r;
	my (@r);

	local(*F);
	open(F, "<$file") || die "open $file: $!";
	@r = <F>;
	close(F);

	return join("",@r);
}

sub _write_file
{
	my ($f, @data) = @_;

	no strict;

	undef $!;
	my $d = join('', @data);

	local(*F,*O);
	open(F, ">$f") || die "open >$f: $!";
	$O = select(F);
	$| = 1;
	select($O);
	(print F $d) || die "write $f: $!";
	File::Sync::fsync_fd(fileno(F)) || die "fsync $f: $!";
	close(F) || die "close $f: $!";
	if ($d && ! -s $f) {
		# Houston, we have a problem!
		# Let's try this again!
		# this code may no longer be necessary.  
		confess "cannot write $f: $!" 
			if caller(50); # prevent deep recursion
		print STDERR "Write to $f failed ($!), trying again\n"
			if $warnings;
		_write_file($f, $d);
	}
	return 1;
}

# now the meat

sub new
{
	my ($pkg, @args) = @_;
	no strict 'refs';
	my $obj = ${pkg}->initialize(@args);
	bless $obj, $pkg;
	$obj->cache;
	return $obj;
}

use vars qw($commit_inprogress);
$commit_inprogress = 0;
my $firstload;

sub load
{
	my ($package, $baseid) = @_;

	print STDERR "LOAD $package $baseid\n" if $debug;

	if (exists $cache{$package}{$baseid}) {
		print STDERR "Returing cached $package $baseid\n" if $debug;
		return $cache{$package}{$baseid};
	}

	my $newid;
	eval {
		$newid = $package->preload($baseid);
	};
	confess $@ if $@;

	if ($newid && exists $cache{$package}{$newid}) {
		print STDERR "Returing cached $package $baseid\n" if $debug;
		return $cache{$package}{$newid};
	}

	$firstload = time unless $firstload;

	my $id = $newid || $baseid;

	return undef unless $id;

	my $file = $package->file($id);

	# all method invocations can have side-effects.
	if ($cache{$package}{$id}) {
		print STDERR "Returing recently-cached $package $id\n" if $debug;
		return $cache{$package}{$id};
	}

	# 
	# No read-lock is required because files are only modified
	# through rename rather than rewrite.
	#
	# This does create the possibility of a program failure if you
	# try to read a file that is deleted at just the right time.
	#
	return undef unless -e $file;
	my $frozen = _read_file($file);
	{
		no re 'taint';
		substr($frozen, 0, length($magic_cookie)) eq $magic_cookie
			or die "corrupt file: $file";
		substr($frozen, 0, length($magic_cookie)) = '';
	}
	my $obj = Storable::thaw $frozen;
	print STDERR "Pulling fresh copy for $package $id from $file\n" if $debug;
	die "unable to thaw $file!" unless $obj;
	$obj->{'OLD'} = Storable::thaw $frozen;
	$obj->{'OLD'}{'__frozen'} = \$frozen;

	$obj->postload($id);

	$cache{$package}{$id} = $obj;
	modperl_register() unless $registered;

	if ($obj->{'__transfollowers'}) {
		print STDERR "Transleader with followers\n" if $debug;
		for my $class (sort keys %{$obj->{'__transfollowers'}}) {
			for my $id (sort keys %{$obj->{'__transfollowers'}{$class}}) {
				# will rollback as side-effect
				my $follower = _loadany($class, $id);
			}
		}
		$obj = Storable::thaw ${$obj->{'__rollback'}};
		$cache{$package}{$id} = $obj;
		_lock $file;
		$obj->postload($id);
		_unlock $file;
		$obj->_realsave();
	} elsif ($obj->{'__transleader'}) {
		print STDERR "Transfollower\n" if $debug;
		my $leader = _loadany($obj->{'__transleader'}{'CLASS'}, 
			    $obj->{'__transleader'}{'ID'});
		if (exists $leader->{'__transfollower'}
			&& exists $leader->{'__transfollower'}{$package}
			&& exists $leader->{'__transfollower'}{$package}{$id})
		{
			# rollback time!
			$obj = Storable::thaw ${$obj->{'__rollback'}};
			$cache{$package}{$id} = $obj;
			_lock $file;
			$obj->postload($id);
			_unlock $file;
		} else {
			delete $obj->{'__transleader'};
			delete $obj->{'__rollback'};
		}

		eval {
			$obj->_realsave();
		};
		if ($@ =~ /^DATACHANGE: file/) {
			return load($package, $baseid);
		}
		die $@ if $@;
	}

	if ($obj->{'__removenow'}) {
		$obj->_realremove();
		return undef;
	}

	return $obj;
}

sub objectref
{
	my ($this) = @_;
	my $id = $this->id();
	die "id function returned empty on $this" unless $id;
	return bless [ ref $this, $id ], 'Object::Transaction::Reference';
}

{
	package Object::Transaction::Reference;

	sub loadref
	{
		my ($ref) = @_;
		my ($pkg, $id) = @$ref;
		return Object::Transaction::_loadany($pkg, $id);
	}
}

sub _loadany
{
	my ($pkg, $id) = @_;
	no strict qw(refs);
	unless (defined @{"${pkg}::ISA"}) {
		require "$pkg.pm";
	}
	return ${pkg}->load($id);
}

my %tosave;

sub abandon
{
	%tosave = ();
}

sub cache
{
	my ($this) = @_;
	my $pkg = ref $this;
	my $id = $this->id();
	confess unless defined $id;
	confess "id clash with $pkg $id\n" 
		if $cache{$pkg} 
			&& defined $cache{$pkg}{$id} 
			&& $cache{$pkg}{$id} ne $this;
	$cache{$pkg}{$id} = $this;
	modperl_register() unless $registered;
}

sub uncache
{
	my ($this) = @_;
	if (ref $this) {
		delete $cache{ref $this}{$this->id()};
		$this->{'__uncached'} = 1;
	} else {
		%cache = ();
		undef $firstload;
	}
}

sub removelater
{
	my ($this) = @_;
	$this->{'__removenow'} = 1;
	$this->savelater();
}

sub remove
{
	my ($this) = @_;
	$this->removelater()
		if $this;

	commit();
}

sub savelater
{
	my ($this, $trivial, $code) = @_;
	confess "attempt to call savelater() from within a presave() or postsave()"
		if $commit_inprogress == 2;
	my $id = $this->id();
	confess "id not defined" unless defined $id;
	$tosave{ref $this}{$id} = $this;
	$this->{'__readonly'} = 0;
	if ($code) {
		$this->{'__doatsave'} = []
			unless $this->{'__doatsave'};
	}
	if ($trivial) {
		$this->{'__trivial'} = 1;
	} else {
		delete $this->{'__trivial'};
	}
	$this->cache() unless $this->{'OLD'};

	check_hash($this);
}

sub readlock
{
	my ($this) = @_;
	my $id = $this->id();
	confess unless defined $id;
	$tosave{ref $this}{$id} = $this;
	$this->{'__readonly'} = 1
		unless exists $this->{'__readonly'};
}

sub save
{
	my ($this) = @_;
	$this->savelater()
		if $this;

	commit();
}

sub transaction_pending
{
	return 1 if %tosave;
	return 0;
}

sub transaction
{
	eval {
		require ObjTransLclCnfg;
	};
	shift if ref $_[0] ne 'CODE';
	my ($funcref, @args) = @_;
	my (%c) = (%cache);
	my $r;
	my @r;
	my $want = wantarray();
	my $die = 0;
	my $count = 0;
	for(;;) {
		die if $die; # protect against 'next' et al inside eval
		$die = 1;
		eval {
			if ($want) {
				@r = &$funcref(@args);
			} else {
				$r = &$funcref(@args);
			}
		};
		if ($@ =~ /^DATACHANGE: file/) {
			%cache = %c;
			print STDERR "Restarting transaction: $@" if $warnings;
			$die = 0;
			die "Aborting Transaction -- Too many locking failures ($count): $@"
				if $ObjTransLclCnfg::maxtries
					&& $count++ > $ObjTransLclCnfg::maxtries;
			redo;
		}
		require Carp;
		Carp::croak $@ if $@;
		last;
	}
	return @r if $want;
	return $r;
}

#
# One of the changed objects becomes the transaction leader.  The state
# of the leader determines the state of the entire transaction.  
#
# The leader gets modified twice: first to note the other participants 
# in the transaction and then later to commit the transaction.  
#
# The other participants also get written twice, but the second writing
# happens the next time the object gets loaded, rather than at the time
# of the transaction.
#

my $unlock;
my $datachangefailures;

sub commit
{
	confess "attemp to call commit() from within a precommit(), presave() or postsave()"
		if $commit_inprogress;
	local($commit_inprogress) = 1;

	return 0 unless %tosave;

	my @commitlist;
	my %precommitdone;

	my $done = 0;
	while (! $done) {
		$done = 1;
		for my $type (keys %tosave) {
			for my $obj (values %{$tosave{$type}}) {
				next if $precommitdone{$obj}++;
				if ($obj->precommit($obj->old)) {
					$done = 0;
				}
			}
		}
	}

	my @savelist;
	for my $cls (sort keys %tosave) {
		for my $id (sort keys %{$tosave{$cls}}) {
			push(@savelist, $tosave{$cls}{$id});
		}
	}

	$commit_inprogress = 2;

	if (@savelist == 1) {
		if ($savelist[0]->{'__removenow'}) {
			$savelist[0]->_realremove();
		} else {
			$savelist[0]->_realsave();
		}
		%tosave = ();
		$datachangefailures = 0;
		return 1;
	}

	my $leader = shift(@savelist);
	$leader->{'__rollback'} = exists $leader->{'OLD'} 
			? $leader->{'OLD'}{'__frozen'} 
			: Storable::nfreeze { '__removenow' => 1 };

	for my $s (@savelist) {
		die "attemp to save an 'uncached' object" 
			if exists $s->{'__uncached'};
		$leader->{'__toremove'}{ref($s)}{$s->id()} = 1
			if $s->{'__deletenow'};
		next if $s->{'__trivial'};
		$leader->{'__transfollowers'}{ref($s)}{$s->id()} = 1;
		$s->{'__transleader'} = {
			'CLASS' => ref($leader),
			'ID' => $leader->id(),
		};
		$s->{'__rollback'} = exists $s->{'OLD'}
			? $s->{'OLD'}{'__frozen'} 
			: Storable::nfreeze { '__removenow' => 1 };
	}

	delete $leader->{'__readonly'};
	if (! -e $leader->file()) {
		$leader->_realsave();
	}
	_lock $leader->file();
	$leader->_realsave(1);

	for my $s (@savelist) {
		$s->_realsave();
	}

	delete $leader->{'__transfollowers'};
	delete $leader->{'__rollback'};
	$leader->_realsave(1);

	if ($leader->{'__toremove'}) {
		$leader->_removeall();
		$leader->_realsave(1);
	}
	_unlock $leader->file();

	if (exists $leader->{'__removenow'}) {
		$leader->_realremove();
	}

	%tosave = ();
	$datachangefailures = 0;
	return 1;
}

my $srand;
sub _realsave
{
	my ($this, $keeplock) = @_;

	my $id = $this->id();
	my $file = $this->file($id);

	my $old = $this->old();

	my (@passby) = $this->presave($old);

	if (defined $old) {
		_lock $file unless $keeplock;
		my $frozen = _read_file($file);
		substr($frozen, 0, length($magic_cookie)) eq $magic_cookie
			or die "corrupt file: $file";
		substr($frozen, 0, length($magic_cookie)) = '';
		if ($frozen ne ${$old->{'__frozen'}}) {
			_unlock_all();
			abandon();
			uncache();
			srand(time ^ ($$ < 5)) 
				unless $srand;
			$srand = 1;
			require Time::HiRes;
			my $st = rand(0.5)*(1.3**$datachangefailures);
			$st = ($st % 200 + 100) if $st > 300;
			printf STDERR "DATACHANGE sleep %d for %.2f seconds\n", $$, $st
				if $warnings;
			Time::HiRes::sleep($st);
			printf STDERR "DATACHANGE sleep %d done\n", $$
				if $warnings;
			$datachangefailures++;
			$firstload = undef;
			if ($this->{__poison}) {
				die "Cached object from previous transaction reused";
			}
			$this->{__poison} = 'DATACHANGE';
			warn "DATACHANGE: file $file changed out from under $$\n"
				if $warnings;
			die "DATACHANGE: file $file changed out from under $$, please retry";
		}
		if ($this->{'__readonly'}) {
			_unlock $file unless $keeplock;
			return;
		}
	} else {
		_lock $file unless $keeplock;
	}

	delete $this->{'OLD'};
	delete $this->{'__readonly'};

	my $newfrozen = Storable::nfreeze($this);
	_write_file("$file.tmp", $magic_cookie, $newfrozen);

	_lock "$file.tmp";

	confess("write failed on $file.tmp") unless -s "$file.tmp";

	rename("$file.tmp", $file) 
		or die "rename $file.tmp -> $file: $!";

	die unless -e $file;

	_lockrename("$file.tmp", $file);

	$this->postsave($old, @passby);

	if ($file ne $this->file($id)) {
		# can change sometimes
		my $new = $this->file($id);
		File::Flock::lock_rename($file, $new);
		$file = $new;
	}
	_unlock $file
		unless $keeplock;

	$this->{'OLD'} = Storable::thaw($newfrozen);
	$this->{'OLD'}{'__frozen'} = \$newfrozen;
}

sub _removeall
{
	my ($this) = @_;
	for my $class (sort keys %{$this->{'__toremove'}}) {
		for my $id (sort keys %{$this->{'__toremove'}{$class}}) {
			# will remove as side-effect
			my $follower = $class->load($id);
		}
	}
}

sub _realremove
{
	my ($this) = @_;
	_lock $this->file();
	$this->preremove();
	_unlock $this->file();
	unlink($this->file());
	$this->postremove();
	delete $cache{ref $this}{$this->id()} 
}

sub old
{
	my ($this) = @_;
	return $this->{'OLD'} if exists $this->{'OLD'};
	return undef;
}

sub check_hash
{
	# Look for references used as hash keys.
	# XXXX Turn this off in production.
	my ($hash_ref) = @_;

	for my $key (keys %{$hash_ref}) {
		if($key =~ /HASH\(0x[0-9a-f]+\)/) {
			confess "Hash used as a key; class: " . ref($hash_ref) . 
				"; value: $hash_ref->{$key}\n";
		} else {
			my $val = $hash_ref->{$key};
			if(ref($val) eq 'HASH') {
				check_hash($val);
			}
		}
	}
}

sub modperl_register
{
	$registered = 1;
	return unless $ENV{MOD_PERL};
	Apache->push_handlers("PerlCleanupHandler", \&modperl_cleanup);
}

sub modperl_cleanup
{
	$registered = 0;
	undef %locks;
	undef %tosave;
	$datachangefailures = 0;
	$commit_inprogress = 0;

	#
	# This next one is debateable.  If we don't clear
	# out the cache then the process will grow and grow.
	# If we don't clear out the cache we will have many
	# more aborted transactions.  An in-between setting
	# is probably necessary.  
	#
	undef %cache;
}

1;
