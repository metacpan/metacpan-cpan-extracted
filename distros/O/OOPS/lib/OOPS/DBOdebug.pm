

package OOPS::DBO;

use strict;

sub query_debug
{ #debug
	my ($dbo, $dprefix, $q, %debug_args) = @_;

	my $debug_rx_target;
	if ($OOPS::debug_q_regex_target eq 'data') {
		require Data::Dumper; # debug;
		$debug_rx_target = Data::Dumper::Dumper(%debug_args);
	} elsif ($OOPS::debug_q_regex_target eq 'query') {
		$debug_rx_target = $dbo->{queries}{$q};
	} elsif ($OOPS::debug_q_regex_target eq 'comment') {
		$debug_rx_target = $dbo->{debug_q}{$q};
	} # debug

	my $debug_match = $debug_rx_target =~ /$OOPS::debug_q_regex/;

	print STDERR "Q$dprefix: $q\n" if ($OOPS::debug_queries & 2) 
		&& (($OOPS::debug_queries & 1) || $debug_match);
	print STDERR "Q$dprefix: $dbo->{queries}{$q}" if ($OOPS::debug_queries & 4) 
		&& (($OOPS::debug_queries & 1) || $debug_match);

	my @debug_args = exists($debug_args{execute})
		? (defined($debug_args{execute})
			? (ref($debug_args{execute})
				? @{$debug_args{execute}}
				: $debug_args{execute})
			: ()) # debug
		: %debug_args;

	print STDERR "A$dprefix: ".join(',', $q, @debug_args)."\n" 
		if ($OOPS::debug_queries & 8) 
			&& (($OOPS::debug_queries & 1) || $debug_match);
} #debug


package OOPS::DBO::DBIdebug;

use strict;
use warnings;
use Carp qw(confess longmess);
use POSIX qw(EAGAIN ENOENT EEXIST O_RDWR); 
use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB LOCK_UN);
use Scalar::Util qw(weaken);

my $id = 1;

sub new
{
	my ($pkg, $dbh) = @_;

	if ($ENV{OOPS_DEBUGLOG}) {
		open(DBOdebug, ">>$ENV{OOPS_DEBUGLOG}") || die "open >> $ENV{OOPS_DEBUGLOG}: $!";
	} else {
		open(DBOdebug, ">&STDOUT") || die "can't dup STDOUT: $!";
	}
	my $lastq = "idle";
	my $self = bless { dbh => $dbh, id => $id++, primary => 1 };
	$self->output("Connect");
	$self->{lastq} = \$lastq;
	push(@OOPS::transaction_rollback, sub {
		my $lq = ${$self->{lastq}};
		$lq = "<UNDEF>" unless defined $lq;
		print STDERR "Last query before rollback: $lq\n"
			unless $lq =~ /^(idle|disconnect)$/
	}) if $OOPS::transaction_tries;
	return $self;
}

sub subnew
{
	my ($pkg, $sth, $parent) = @_;
	my $self = bless { dbh => $sth, id => $parent->{id}, parent => $parent, lastq => $parent->{lastq} };
	push(@{$parent->{children}}, $self);
	weaken($parent->{children}[$#{$parent->{children}}]);
	weaken($self->{parent});
	return $self;
}

sub AUTOLOAD
{
	my $self = shift;
	our $AUTOLOAD;
	my $a = $AUTOLOAD;
	$a =~ s/.*:://;
	die "USING AUTOLOAD ON $self->{dbh} ->$a()\n";
	my $method = $self->{dbh}->can($a) || $self->{dbh}->can($AUTOLOAD) || confess "cannot find method $a for $self->[0]";
	my @r;
	if (wantarray) {
		@r = &$method($self->{dbh}, @_);
	} else {
		$r[0] = &$method($self->{dbh}, @_);
	}
	if (ref $r[0] && ref($r[0]) ne __PACKAGE__) {
		$r[0] = __PACKAGE__->subnew($r[0], $self);
	}
	return @r if wantarray;
	return $r[0];
}

sub prepare
{
	my $self = shift;
	my ($query) = @_;
	my $sth;
	confess if @_ > 2;
	eval {
		$sth = __PACKAGE__->subnew($self->{dbh}->prepare($query), $self);
	};
	confess $@ if $@;
	$sth->{query} = $query;
	return $sth;
}

sub prepare_cached
{
	my $self = shift;
	my ($query) = @_;
	my $sth = __PACKAGE__->subnew($self->{dbh}->prepare_cached($query), $self);
	$sth->{query} = $query;
	return $sth;
}

sub execute
{
	my $self = shift;
	my (@values) = scalar(@_)
		? @_
		: ($self->{values}
			? @{$self->{values}}
			: ());
	my $query = $self->{query};
	die unless $query;
	my $code = "Do";
	$self->{display} = preformat($self->{query}, @values);
	${$self->{lastq}} = $self->{display};
	if ($query =~ /\bSELECT\b/i) {
		$code = "Query";
	}
	$self->output("Pre-$code", $self->{display});
	die "PREVIOUSLY DISCONNECTED AT <<<<<<<$self->{parent}{disconnect}>>>>>>>>" if $self->{parent}{disconnect};
	my $r = $self->{dbh}->execute(@_);
	my $dr = $r ? $r : "ERROR";
	$self->output($code, "[$dr] = ", $self->{display});
	${$self->{lastq}} = "idle";
	return $r;
}

sub selectrow_array
{
	my $self = shift;
	my ($query) = @_;
	$self->{display} = preformat($query);
	$self->output("Pre-Fetch", $self->{display});
	${$self->{lastq}} = $self->{display};
	my (@r) = $self->{dbh}->selectrow_array($query);
	$self->output("Fetch", resultsformat(@r). " = ".$self->{display});
	${$self->{lastq}} = "idle";
	return @r;
}

sub bind_param
{
	my $self = shift;
	my ($num, $value) = @_;
	$self->{values}[$num-1] = $value;
	$self->{dbh}->bind_param(@_);
}

sub fetchrow_array
{
	my $self = shift;
	die unless $self->{display};
	$self->output("Pre-fetch", $self->{display});
	${$self->{lastq}} = $self->{display};
	my (@r) = $self->{dbh}->fetchrow_array();
	$self->output("fetch", resultsformat(@r)." = $self->{display}");
	${$self->{lastq}} = "idle";
	return @r;
}

sub fetchall_arrayref
{
	my $self = shift;
	die unless $self->{display};
	$self->output("Pre-fetchall_arrayref", $self->{display});
	${$self->{lastq}} = $self->{display};
	my $r = $self->{dbh}->fetchall_arrayref();
	my $o = '';
	for my $a (@$r) {
		$o .= resultsformat(@$a);
	}
	$self->output("fetch", "$o = $self->{display}");
	${$self->{lastq}} = "idle";
	return $r;
}


sub do
{
	my $self = shift;
	my ($query, undef, @values) = @_;
	$self->{display} = preformat($query, @values);
	$self->output("Pre-do", $self->{display});
	${$self->{lastq}} = $self->{display};
	my $r = $self->{dbh}->do(@_);
	my $dr = $r ? $r : "ERROR";
	$self->output("do", "[$dr] = $self->{display}");
	${$self->{lastq}} = "idle";
	return $r;
}

sub preformat
{
	my ($query, @values) =  @_;
	$query =~ s/\n/ /g;
	$query =~ s/\s\s*/ /g;
	$query =~ s/^\s+//;
	$query =~ s/\?$/? /;
	my @q = split(/\?/, $query);
	my $display = shift(@q);
	while (@q && @values) {
		my $v = shift(@values);
		if (defined $v) {
			$display .= "'$v'";
		} else {
			$display .= "NULL";
		}
		$display .= shift(@q);
	}
	$display = "<UNDEF>" unless defined $display;
	$display =~ s/\s+$//;
	return $display;
}

sub resultsformat
{
	my (@r) = @_;
	return "[". join(", ", map { defined $_ ? "'$_'" : 'undef' } @r)."]";
	#return "[]" unless @r;
	#return ("['".join("', '", @r). "']");
}

sub output
{
	my $self = shift;
	my $code = shift;
	my $stuff = join('', map { defined $_ ? $_ : '<UNDEF>' } @_);
	$stuff =~ s/^\s+//;
	if ($ENV{OOPS_DEBUGLOG}) {
		flock(DBOdebug, LOCK_EX);
		print DBOdebug "\t\t  $$.$self->{id} $code $stuff\n";
		flock(DBOdebug, LOCK_UN);
	} else {
		print DBOdebug "\t\t  $$.$self->{id} $code $stuff\n";
	}
}

sub display
{
	my $self = shift;
	my $code = shift;
	$self->output($code, preformat(@_));
}

sub DESTROY
{
	my $self = shift;
	unless (exists $self->{parent}) {
		$self->output("DESTROY");
		for my $child (@{$self->{children}}) {
			next unless $child;
			next unless $child->{active};
			print STDERR "ACTIVE STATEMENT: $child->{output}\n";
		}
	}
	%$self = ();
}

sub disconnect
{
	my $self = shift;
	return unless $self->{dbh};
	delete $self->{display};
	${$self->{lastq}} = "disconnect";
	$self->{disconnect} = longmess();
	$self->output("Disconnect");
	$self->{dbh}->disconnect(@_);
}

sub commit
{
	my $self = shift;
	$self->output("Pre-Commit");
	${$self->{lastq}} = "commit";
	my $r = $self->{dbh}->commit(@_);
	my $dr = $r ? $r : "ERROR";
	${$self->{lastq}} = "idle";
	$self->output("Commit", "[$dr]");
	return $r;
}

sub rollback
{
	my $self = shift;
	$self->output("Pre-Rollback");
	my $r = $self->{dbh}->rollback(@_);
	my $dr = $r ? $r : "ERROR";
	$self->output("Rollback", "[$dr]");
	return $r;
}

sub finish
{
	my $self = shift;
	$self->{dbh}->finish(@_);
}

sub err
{
	my $self = shift;
	$self->{dbh}->err(@_);
}

sub errstr
{
	my $self = shift;
	$self->{dbh}->errstr(@_);
}

sub func
{
	my $self = shift;
	$self->{dbh}->func(@_);
}

sub begin_work
{
	my $self = shift;
	$self->output("Pre-BeginWork");
	my $r = $self->{dbh}->begin_work(@_);
	my $dr = $r ? $r : "ERROR";
	$self->output("BeginWork", "[$dr]");
	return $r;
}

	
1;

