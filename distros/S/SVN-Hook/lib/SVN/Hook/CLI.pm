package SVN::Hook::CLI;
use strict;
use warnings;
use SVN::Hook;

sub dispatch {
    my $class = shift;
    my $cmd   = shift or die "$0 version $SVN::Hook::VERSION.\n";
    die if $cmd =~ m/^_/;
    my $func  = $class->can($cmd) or die "no such command $cmd.\n";

    $func->($class, @_);
}

sub run {
    my $class     = shift;
    my $repospath = shift or die "repository required.\n";
    my $hook      = shift or die "hook name required.\n";
    unshift @_, $class, $hook, $repospath;
    goto \&run;
}

sub _run {
    my $class = shift;
    my $hook  = shift;

    my ($repospath) = @_;
    my $h = SVN::Hook->new({repospath => $repospath});

    $h->run_hook( $hook, @_ );
}

sub init {
    my $class = shift;
    my $repospath = shift or die "repository required.\n";
    my @hooks = @_ ? @_ : SVN::Hook->ALL_HOOKS;

    my $h = SVN::Hook->new({repospath => $repospath});
    $h->init($_) for @hooks;
    print "initialized.\n";
}

sub list {
    my $class     = shift;
    my $repospath = shift or die "repository required.\n";
    my $hook      = shift or die "hook name required.\n";

    my $h = SVN::Hook->new({repospath => $repospath});
    my $i = 0;
    for my $script ($h->scripts($hook)) {
	printf '[%d] %s', ++$i, $script->path->basename;
	print " (disabled)" unless $script->enabled;
	print "\n";
    }
}

sub status {
    my $class     = shift;
    my $repospath = shift or die "repository required.\n";

    my $h = SVN::Hook->new({repospath => $repospath});
    my $status = $h->status;
    for (sort SVN::Hook->ALL_HOOKS) {
	if (defined $status->{$_}) {
	    print "$_: $status->{$_} scripts\n";
	}
	else {
	    print "svnhook not enabled for $_.\n";
	}
    }
}

1;
