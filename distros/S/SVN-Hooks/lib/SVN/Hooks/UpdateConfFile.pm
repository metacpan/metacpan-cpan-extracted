package SVN::Hooks::UpdateConfFile;
# ABSTRACT: Maintain the repository configuration versioned.
$SVN::Hooks::UpdateConfFile::VERSION = '1.36';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use File::Spec::Functions;
use File::Temp qw/tempdir/;
use Cwd qw/abs_path/;
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'UPDATE_CONF_FILE';
our @EXPORT = ($HOOK);


my @Config;

sub UPDATE_CONF_FILE {
    my ($from, $to, @args) = @_;

    is_string($from) || is_rx($from) or croak "$HOOK: invalid first argument.\n";
    is_string($to)                   or croak "$HOOK: invalid second argument.\n";
    (@args % 2) == 0                 or croak "$HOOK: odd number of arguments.\n";
    file_name_is_absolute($to)      and croak "$HOOK: second argument cannot be an absolute pathname ($to).\n";

    my %confs = (from => $from, to => $to);

    my %args = @args;

    for my $function (qw/validator generator actuator/) {
	if (my $what = delete $args{$function}) {
	    if (is_code_ref($what)) {
		$confs{$function} = $what;
	    } elsif (is_array_ref($what)) {
		# This should point to list of command arguments
		@$what > 0    or croak "$HOOK: $function argument must have at least one element.\n";
		$confs{$function} = _functor($what);
	    } else {
		croak "$HOOK: $function argument must be a CODE-ref or an ARRAY-ref.\n";
	    }

	    PRE_COMMIT(\&pre_commit);
	}
    }

    if (my $rotate = delete $args{rotate}) {
	$rotate =~ /^\d+$/ or croak "$HOOK: rotate argument must be numeric, not '$rotate'";
	$rotate < 10       or croak "$HOOK: rotate argument must be less than 10, not '$rotate'";
	$confs{rotate} = $rotate;
    }

    if (my $remove = delete $args{remove}) {
        $confs{remove} = $remove;
    }

    keys %args == 0
	or croak "$HOOK: invalid option names: ", join(', ', sort keys %args), ".\n";

    push @Config, \%confs;

    POST_COMMIT(\&post_commit);

    return 1;
}

sub pre_commit {
    my ($svnlook) = @_;

  CONF:
    foreach my $conf (@Config) {
	if (my $validator = $conf->{validator}) {
	    my $from = $conf->{from};
	    for my $file ($svnlook->added(), $svnlook->updated()) {
		if (is_string($from)) {
		    next if $file ne $from;
		} else {
		    next if $file !~ $from;
		}

		my $text = $svnlook->cat($file);

		if (my $generator = $conf->{generator}) {
		    $text = eval { $generator->($text, $file, $svnlook) };
		    defined $text
			or croak "$HOOK: Generator aborted for: $file\n", $@, "\n";
		}

		my $validation = eval { $validator->($text, $file, $svnlook) };
		defined $validation
		    or croak "$HOOK: Validator aborted for: $file\n", $@, "\n";

		next CONF;
	    }
	}
    }
    return;
}

sub post_commit {
    my ($svnlook) = @_;

    my $absbase = abs_path(catdir($SVN::Hooks::Repo, 'conf'));

    foreach my $conf (@Config) {
	my $from = $conf->{from};
	for my $file ($svnlook->added(), $svnlook->updated()) {
            my $to = _post_where_to($absbase, $file, $from, $conf->{to});
            next unless defined $to;

	    my $text = $svnlook->cat($file);

	    if (my $generator = $conf->{generator}) {
		$text = eval { $generator->($text, $file, $svnlook) };
		defined $text or croak <<"EOS";
$HOOK: generator in post-commit aborted for: $file

This means that $file was committed but the associated
configuration file wasn't generated in the server at:

  $to

Please, investigate the problem and re-commit the file.

Any error message produced by the generator appears below:

$@
EOS
	    }

            # Create the directory where $to is to be created, if it doesn't
            # already exist.
            my $todir = (File::Spec->splitpath($to))[1];
            unless (-d $todir) {
                require File::Path;
                File::Path::make_path($todir);
            }

	    open my $fd, '>', "$to.new"
		or croak "$HOOK: Can't open file \"$to.new\" for writing: $!\n";
	    print $fd $text;
	    close $fd;

            _rotate($to, $conf->{rotate}) if $conf->{rotate};

	    rename "$to.new", $to;

	    if (my $actuator = $conf->{actuator}) {
		my $rc = eval { $actuator->($text, $file, $svnlook) };
		defined $rc or croak <<"EOS";
$HOOK: actuator in post-commit aborted for: $file

This means that $file was committed and the associated
configuration file was generated in the server at:

  $to

But the actuator command that was called after the file generation
didn't work right.

Please, investigate the problem.

Any error message produced by the actuator appears below:

$@
EOS
	    }
	}
        if ($conf->{remove}) {
            for my $file ($svnlook->deleted()) {
                my $to = _post_where_to($absbase, $file, $from, $conf->{to});
                next unless defined $to && -f $to;
                if (my $rotate = $conf->{rotate}) {
                    _rotate($to, $rotate);
                } else {
                    unlink $to or carp "$HOOK: can't unlink '$to'.\n";
                }
            }
        }
    }
    return;
}

sub _functor {
    my ($cmdlist) = @_;
    my $cmd = join(' ', @$cmdlist);

    return sub {
	my ($text, $path, $svnlook) = @_;

	my $temp = tempdir('UpdateConfFile.XXXXXX', TMPDIR => 1, CLEANUP => 1);

	# FIXME: this is Unix specific!
	open my $th, '>', "$temp/file"
	    or croak "Can't create $temp/file: $!";
	print $th $text;
	close $th;

	local $ENV{SVNREPOPATH} = $svnlook->repo();
	if (system("$cmd $temp/file $path $ENV{SVNREPOPATH} 1>$temp/output 2>$temp/error") == 0) {
	    return `cat $temp/output`;
	} else {
	    croak `cat $temp/error`;
	}
    };
}

# Return the server-side absolute path mapping for the configuration file, or
# undef if $file doesn't match $from. $absbase is the absolute path to the
# repo's conf directory. $file is the path of a file added, modified, or
# deleted in the commit. $from and $to are the configured mapping.

sub _post_where_to {
    my ($absbase, $file, $from, $to) = @_;

    if (is_string($from)) {
        return if $file ne $from;
    } else {
        return if $file !~ $from;
        # interpolate backreferences
        $to = eval qq{"$to"};   ## no critic (BuiltinFunctions::ProhibitStringyEval)
    }

    $to !~ m@(?:^|/)\.\.(?:/|$)@
        or croak <<"EOS";
$HOOK: post-commit aborted for: $file

This means that $file was committed but the associated
configuration file wasn't generated because its specified
location ($to)
contains a '..' path component which is not accepted by this hook.

Please, correct the ${HOOK}'s second argument.
EOS

    my $is_directory = ($to =~ s:/$::);

    $to =~ s:^/+::;

    my $abs_to = catfile($absbase, $to);
    if ($is_directory || -d $abs_to) {
        $abs_to = catfile($abs_to, (File::Spec->splitpath($file))[2]);
    }

    return $abs_to;
}

# Rotates file $to $rotate times.

sub _rotate {
    my ($to, $rotate) = @_;
    for (my $i=$rotate-1; $i >= 0; --$i) {
        rename "$to.$i", sprintf("$to.%d", $i+1)
            if -e "$to.$i";
    }
    rename $to, "$to.0"
        if -e $to;
}

1; # End of SVN::Hooks::UpdateConfFile

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::UpdateConfFile - Maintain the repository configuration versioned.

=head1 VERSION

version 1.36

=head1 SYNOPSIS

This SVN::Hooks plugin allows you to maintain the repository
configuration files under version control.

The repository configuration is usually kept in the directory C<conf>
under the directory where the repository was created. In a brand new
repository you see there the files C<authz>, C<passwd>, and
C<svnserve.conf>. It's too bad that these important files are usually
kept out of any version control system. This plugin tries to solve
this problem allowing you to keep these files versioned under the same
repository where they are used.

It's active in the C<pre-commit> and the C<post-commit> hooks.

It's configured by the following directive.

=head2 UPDATE_CONF_FILE(FROM, TO, @ARGS)

This directive makes that after a successful commit in which the file
FROM, under version control, have been added or modified, its newest
version is copied to TO.

FROM can be a string or a qr/Regexp/ specifying the file path relative
to the repository's root (e.g. "trunk/src/version.c" or
"qr:^conf/(\w+).conf$:").

TO must be a relative path indicating where the original file must be copied
to below the C</repo/conf> directory in the server. It can be an explicit
file name or a directory, in which case the basename of FROM is used as the
name of the destination file. Non-existing directory components of TO are
automatically created.

Note that if the path doesn't exist the hook assumes that it should be a
file. To make sure it's understood as a directory you may end it with a
forward slash (/).

If FROM is a qr/Regexp/, TO is evaluated as a string in order to allow
for the interpolation of capture buffers from the regular
expression. This is useful to map the copy operation to a different
directory structure. For example, this configuration
"qr:^conf/(\w+).conf$: => '$1.conf'" updates any .conf file in the
repository conf directory.

The optional @ARGS must be a sequence of pairs like these:

=over

=item validator => ARRAY or CODE

A validator is a function or a command (specified by an array of
strings that will be passed to the shell) that will check the contents
of FROM in the pre-commit hook to see if it's valid. If there is no
validator, the contents are considered valid.

The function receives three arguments:

=over

=item A string with the contents of FROM

=item A string with the relative path to FROM in the repository

=item An SVN::Look object representing the commit transaction

=back

The command is called with three arguments:

=over

=item The path to a temporary copy of FROM

=item The relative path to FROM in the repository

=item The path to the root of the repository in the server

=back

=item generator => ARRAY or CODE

A generator is a function or a command (specified by an array of
strings that will be passed to the shell) that will transform the
contents of FROM in the post-commit hook before copying it to TO. If
there is no generator, the contents are copied as is.

The function receives the same three arguments as the validator's
function above.

The command is called with the same three arguments as the validator's
command above.

=item actuator => ARRAY or CODE

An actuator is a function or a command (specified by an array of
strings that will be passed to the shell) that will be invoked after a
successful commit of FROM in the post-commit hook.

The function receives the same three arguments as the validator's
function above.

The command is called with the same three arguments as the validator's
command above.

=item rotate => NUMBER

By default, after each successful commit the TO file is overwritten by
the new contents of FROM. With this option, the last NUMBER versions
of TO are kept on disk with numeric suffixes ranging from C<.0> to
C<.NUMBER-1>. This can be useful, for instance, in case you manage to
commit a wrong authz file that denies any subsequent commit.

=item remove => BOOL

By default, if FROM is B<deleted> in the commit, nothing happens to
TO. If you want to have the file TO removed from the repository when
FROM is deleted, set this option to a true value such as '1'.

=back

	UPDATE_CONF_FILE(
	    'conf/authz' => 'authz',
	    validator 	 => ['/usr/local/bin/svnauthcheck'],
	    generator 	 => ['/usr/local/bin/authz-expand-includes'],
            actuator     => ['/usr/local/bin/notify-auth-change'],
	    rotate       => 2,
	);

	UPDATE_CONF_FILE(
	    'conf/svn-hooks.conf' => 'svn-hooks.conf',
	    validator 	 => [qw(/usr/bin/perl -c)],
            actuator     => sub {
                                my ($contents, $file) = @_;
                                die "Can't use Gustavo here." if $contents =~ /gustavo/;
                            },
	    rotate       => 2,
	);

	UPDATE_CONF_FILE(
	    qr:/file(\n+)$:' => 'subdir/$1/file',
	    rotate       => 2,
            remove       => 1,
	);

=for Pod::Coverage post_commit pre_commit

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
