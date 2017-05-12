package Parallel::MapReduce::Worker::SSHRemote;

#use Parallel::MapReduce;
#our $log = Parallel::MapReduce::_log();                                # just a local short, I hate typing

sub _pull_string_stdin {
    my $s = <STDIN>; chomp $s;
    return $s;
}

sub _pull_hlist_stdin {
    my $s = <STDIN>; chomp $s;
    return [ split /,/, $s ];
}

sub _pull_vlist_stdin {
    my $s;
    my @s;
    do {
	$s = <STDIN>; chomp $s;
	push @s, $s if $s;
    } while ($s);
    return \@s;
}

sub worker {
    use IO::Handle;
    STDOUT->autoflush(1);
    STDERR->autoflush(1);

    use constant COWS_COME_HOME => 0;

    do {
	my $mode = _pull_string_stdin();
	exit if $mode eq 'exit';
	if ($mode eq "mapper") {
	    my $job     = _pull_string_stdin();
	    my $slice   = _pull_string_stdin();
	    my $servers = _pull_hlist_stdin();
	    my $chunks  = _pull_vlist_stdin();
	    warn "gotta $job $slice servers ".scalar @$servers. "chunks: ".scalar @$chunks;  # debug output here should go to STDERR back to the caller

	    my $w  = new Parallel::MapReduce::Worker;
	    my $cs = $w->map ($chunks, $slice, $servers, $job);
	    print join ("\n", @$cs) . "\n\n";

	} elsif ($mode eq "reducer") {
	    my $job     = _pull_string_stdin();
	    my $servers = _pull_hlist_stdin();
	    my $keys    = _pull_vlist_stdin();
	    warn "reducer gotta $job servers ".scalar @$servers. "keys: ".scalar @$keys;

	    my $w  = new Parallel::MapReduce::Worker;
	    my $cs = $w->reduce ($keys, $servers, $job);
	    print join ("\n", @$cs) . "\n\n";
	}
	sleep 2;
    } until (COWS_COME_HOME);
}

our $VERSION = 0.01;

1;
