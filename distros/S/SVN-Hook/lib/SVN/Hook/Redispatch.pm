package SVN::Hook::Redispatch;
use strict;
use Path::Class;
use SVN::Hook;

sub import {
    my $class = shift;
    my $spec  = shift;
    return unless $spec;

    my $hook_base = Path::Class::File->new($0);

    my $type;
    my $svnlook_arg;

    # $0 can be either hooks/_pre-commit/random_name or
    # hooks/pre-commit itself

    if ($hook_base->parent =~ m'hooks$') { # the hook file itself
	$type = $hook_base->basename;
	$hook_base = $hook_base->parent->subdir("_".$type);
    }
    else {
	$hook_base = $hook_base->parent;
	$type = $hook_base;
	$type =~ s{^.*/_}{};
    }

    # if we are able to pull out the toplevel path
    if ($type eq 'pre-commit') {
	$svnlook_arg = "-t $_[1]";
    }
    elsif ($type eq 'post-commit') {
	$svnlook_arg = "-r $_[1]";
    }
    else {
    }

    my $ignore_error = $type =~ m/^post-/? 1 : 0;

    if (defined (my $dir = delete $spec->{''})) { # global ones
	my @scripts = SVN::Hook::Script->load_from_dir
	    ( $hook_base.'/'.$dir );
	SVN::Hook->run_scripts( \@scripts, $ignore_error, @_ );
    }

    return unless $svnlook_arg;

    my $toplevel = $class->find_toplevel_change($_[0], $svnlook_arg);

    for (map { Path::Class::Dir->new_foreign('Unix', $_) } sort keys %$spec) {
	next unless $_ eq $toplevel || $_->subsumes($toplevel);
	my @scripts = SVN::Hook::Script->load_from_dir
	    ( $hook_base.'/'.$spec->{$_} );
	SVN::Hook->run_scripts( \@scripts, $ignore_error, @_ );
    }

};

sub find_toplevel_change {
    my $class = shift;
    my $repos = shift;
    my $arg   = shift;

    my $svnlook = $ENV{SVNLOOK} || 'svnlook';
    open my $fh, '-|', "$svnlook dirs-changed $arg $repos"
	or die "Unable to run svnlook: $!";
    my $toplevel;
    while (<$fh>) {
	chomp;
	if (!$toplevel) {
	    $toplevel = Path::Class::Dir->new_foreign('Unix', $_);
	}
	else {
	    while (!$toplevel->subsumes($_)) {
		$toplevel = $toplevel->parent;
	    }

	}
    }
    return $toplevel;
}

1;
