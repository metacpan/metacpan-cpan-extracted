package SVN::Hooks;
# ABSTRACT: Framework for implementing Subversion hooks
$SVN::Hooks::VERSION = '1.36';
use strict;
use warnings;

use File::Basename;
use File::Spec::Functions;
use Data::Util qw(:check);
use SVN::Look;

use Exporter qw/import/;

our @EXPORT = qw/run_hook POST_COMMIT POST_LOCK POST_REVPROP_CHANGE
                 POST_UNLOCK PRE_COMMIT PRE_LOCK PRE_REVPROP_CHANGE
                 PRE_UNLOCK START_COMMIT/;

our @Conf_Files = (catfile('conf', 'svn-hooks.conf'));
our $Repo       = undef;
our %Hooks      = ();

sub run_hook {
    my ($hook_name, $repo_path, @args) = @_;

    $hook_name = basename $hook_name;

    -d $repo_path or die "not a directory ($repo_path): $_\n";

    $Repo = $repo_path;

    # Allow all hooks assume they execute on the repository's root directory
    chdir $repo_path or die "cannot chdir to $repo_path: $!\n";

    # Reload all configuration files
    foreach my $conf (@Conf_Files) {
	my $conffile = file_name_is_absolute($conf) ? $conf : catfile($Repo, $conf);
	next unless -e $conffile; # Configuration files are optional

        # The configuration file must be evaluated in the main:: namespace
	package main;
$main::VERSION = '1.36';
unless (my $return = do $conffile) {
	    die "couldn't parse '$conffile': $@\n" if $@;
	    die "couldn't do '$conffile': $!\n"    unless defined $return;
	    die "couldn't run '$conffile'\n"       unless $return;
	}
    }

    # Substitute a SVN::Look object for the first argument
    # in the hooks where this makes sense.
    if ($hook_name eq 'pre-commit') {
	# The next arg is a transaction number
	$repo_path = SVN::Look->new($repo_path, '-t' => $args[0]);
    } elsif ($hook_name =~ /^(?:post-commit|(?:pre|post)-revprop-change)$/) {
	# The next arg is a revision number
	$repo_path = SVN::Look->new($repo_path, '-r' => $args[0]);
    }

    foreach my $hook (@{$Hooks{$hook_name}{list}}) {
	if (is_code_ref($hook)) {
	    $hook->($repo_path, @args);
	} elsif (is_array_ref($hook)) {
	    foreach my $h (@$hook) {
		$h->($repo_path, @args);
	    }
	} else {
	    die "SVN::Hooks: internal error!\n";
	}
    }

    return;
}

## no critic (Subroutines::ProhibitSubroutinePrototypes)

# post-commit(SVN::Look, revision, txn-name)

sub POST_COMMIT (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'post-commit'}{set}{$hook}) {
        push @{$Hooks{'post-commit'}{list}},
            ($Hooks{'post-commit'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# post-lock(repos-path, username)

sub POST_LOCK (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'post-lock'}{set}{$hook}) {
        push @{$Hooks{'post-lock'}{list}},
            ($Hooks{'post-lock'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# post-revprop-change(SVN::Look, revision, username, property-name, action)

sub POST_REVPROP_CHANGE (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'post-revprop-change'}{set}{$hook}) {
        push @{$Hooks{'post-revprop-change'}{list}},
            ($Hooks{'post-revprop-change'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# post-unlock(repos-path, username)

sub POST_UNLOCK (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'post-unlock'}{set}{$hook}) {
        push @{$Hooks{'post-unlock'}{list}},
            ($Hooks{'post-unlock'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# pre-commit(SVN::Look, txn-name)

sub PRE_COMMIT (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'pre-commit'}{set}{$hook}) {
        push @{$Hooks{'pre-commit'}{list}},
            ($Hooks{'pre-commit'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# pre-lock(repos-path, path, username, comment, steal-lock-flag)

sub PRE_LOCK (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'pre-lock'}{set}{$hook}) {
        push @{$Hooks{'pre-lock'}{list}},
            ($Hooks{'pre-lock'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# pre-revprop-change(SVN::Look, revision, username, property-name, action)

sub PRE_REVPROP_CHANGE (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'pre-revprop-change'}{set}{$hook}) {
        push @{$Hooks{'pre-revprop-change'}{list}},
            ($Hooks{'pre-revprop-change'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# pre-unlock(repos-path, path, username, lock-token, break-unlock-flag)

sub PRE_UNLOCK (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'pre-unlock'}{set}{$hook}) {
        push @{$Hooks{'pre-unlock'}{list}},
            ($Hooks{'pre-unlock'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

# <  1.8: start-commit(repos-path, username, capabilities)
# >= 1.8: start-commit(repos-path, username, capabilities, txn-name)

# Subversion 1.8 added a txn-name argument to the start-commit. However it's
# only good to get at the commit properties but not to know about the files
# being changed by the commit, which would allow us to use the start-commit
# to perform many of the checks that we perform currently in the pre-commit
# hook. So, for now I'm not going to use the new argument to construct a
# SVN::Look object, since it is mostly useless anyway.

sub START_COMMIT (&) {
    my ($hook) = @_;
    unless (exists $Hooks{'start-commit'}{set}{$hook}) {
        push @{$Hooks{'start-commit'}{list}},
            ($Hooks{'start-commit'}{set}{$hook} = sub { $hook->(@_); });
    }
    return;
}

## use critic

1; # End of SVN::Hooks

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks - Framework for implementing Subversion hooks

=head1 VERSION

version 1.36

=head1 SYNOPSIS

A single script can implement several hooks:

	#!/usr/bin/perl

	use SVN::Hooks;

	START_COMMIT {
	    my ($repo_path, $username, $capabilities, $txn_name) = @_;
	    # ...
	};

	PRE_COMMIT {
	    my ($svnlook) = @_;
	    # ...
	};

	run_hook($0, @ARGV);

Or you can use already implemented hooks via plugins:

	#!/usr/bin/perl

	use SVN::Hooks;
	use SVN::Hooks::DenyFilenames;
	use SVN::Hooks::DenyChanges;
	use SVN::Hooks::CheckProperty;
	...

	run_hook($0, @ARGV);

=for Pod::Coverage run_hook POST_COMMIT POST_LOCK POST_REVPROP_CHANGE POST_UNLOCK PRE_COMMIT PRE_LOCK PRE_REVPROP_CHANGE PRE_UNLOCK START_COMMIT

=head1 INTRODUCTION

In order to really understand what this is all about you need to
understand Subversion L<http://subversion.apache.org/> and its
hooks. You can read everything about this in the svnbook,
a.k.a. Version Control with Subversion, at
L<http://svnbook.red-bean.com/nightly/en/index.html>.

Subversion is a version control system, and as such it is used to keep
historical revisions of files and directories. Each revision maintains
information about all the changes introduced since the previous one:
date, author, log message, files changed, files renamed, etc.

Subversion uses a client/server model. The server maintains the
B<repository>, which is the database containing all the historical
information we talked about above. Users use a Subversion client tool
to query and change the repository but also to maintain one or more
B<working areas>. A working area is a directory in the user machine
containing a copy of a particular revision of the repository. The user
can use the client tool to make all sorts of changes in his working
area and to "commit" them all in an atomic operation that bumps the
repository to a new revision.

A hook is a specifically named program that is called by the
Subversion server during the execution of some operations. There are
exactly nine hooks which must reside under the C<hooks> directory in
the repository. When you create a new repository, you get nine
template files in this directory, all of them having the C<.tmpl>
suffix and helpful instructions inside explaining how to convert them
into working hooks.

When Subversion is performing a commit operation on behalf of a
client, for example, it calls the C<start-commit> hook, then the
C<pre-commit> hook, and then the C<post-commit> hook. The first two
can gather all sorts of information about the specific commit
transaction being performed and decide to reject it in case it doesn't
comply to specified policies. The C<post-commit> can be used to log or
alert interested parties about the commit just done.

IMPORTANT NOTE from the svnbook: "For security reasons, the Subversion
repository executes hook programs with an empty environment---that is,
no environment variables are set at all, not even $PATH (or %PATH%,
under Windows). Because of this, many administrators are baffled when
their hook program runs fine by hand, but doesn't work when run by
Subversion. Be sure to explicitly set any necessary environment
variables in your hook program and/or use absolute paths to programs."

Not even the current directory where the hooks run is specified by
Subversion. However, the hooks executed by the SVN::Hooks framework run with
their currect directory set to the repository's root directory in the
server. This can be useful sometimes.

There are several useful hook scripts available elsewhere
L<http://svn.apache.org/repos/asf/subversion/trunk/contrib/hook-scripts/>,
mainly for those three associated with the commit operation. However,
when you try to combine the functionality of two or more of those
scripts in a single hook you normally end up facing two problems.

=over

=item B<Complexity>

In order to integrate the funcionality of more than one script you
have to write a driver script that's called by Subversion and calls
all the other scripts in order, passing to them the arguments they
need. Moreover, some of those scripts may have configuration files to
read and you may have to maintain several of them.

=item B<Inefficiency>

This arrangement is inefficient in two ways. First because each script
runs as a separate process, which usually have a high startup cost
because they are, well, scripts and not binaries. And second, because
as each script is called in turn they have no memory of the scripts
called before and have to gather the information about the transaction
again and again, normally by calling the C<svnlook> command, which
spawns yet another process.

=back

SVN::Hooks is a framework for implementing Subversion hooks that tries
to solve these problems.

Instead of having separate scripts implementing different
functionality you have a single script implementing all the
funcionality you need either directly or using some of the existing
plugins, which are implemented by Perl modules in the SVN::Hooks::
namespace. This single script can be used to implement all nine
standard hooks, because each hook knows when to perform based on the
context in which the script was called.

=head1 USAGE

In the Subversion server, go to the C<hooks> directory under the
directory where the repository was created. You should see there the
nine hook templates. Create a script there using the SVN::Hooks module.

	$ cd /path/to/repo/hooks

	$ cat >svn-hooks.pl <<END_OF_SCRIPT
	#!/usr/bin/perl

	use SVN::Hooks;

	run_hook($0, @ARGV);

	END_OF_SCRIPT

	$ chmod +x svn-hooks.pl

This script will serve for any hook. Create symbolic links pointing to
it for each hook you are interested in. (You may create symbolic links
for all nine hooks, but this will make Subversion call the script for
all hooked operations, even for those that you may not be interested
in. Nothing wrong will happen, but the server will be doing extra work
for nothing.)

	$ ln -s svn-hooks.pl start-commit
	$ ln -s svn-hooks.pl pre-commit
	$ ln -s svn-hooks.pl post-commit
	$ ln -s svn-hooks.pl pre-revprop-change

As is the script won't do anything. You have to implement some hooks or
use some of the existing ones implemented as plugins. Either way, the
script should end with a call to C<run_hooks> passing to it the name
with which it wass called (C<$0>) and all the arguments it received
(C<@ARGV>).

=head2 Implementing Hooks

Implement hooks using one of the nine hook I<directives> below. Each
one of them get a single block (anonymous function) as argument. The
block will be called by C<run_hook> with proper arguments, as
indicated below. These arguments are the ones gotten from @ARGV, with
the exception of the ones identified by C<SVN::Look>. These are
SVN::Look objects which can be used to grok detailed information about
the repository and the current transaction. (Please, refer to the
L<SVN::Look> documentation to know how to use it.)

=over

=item * POST_COMMIT(SVN::Look)

=item * POST_LOCK(repos-path, username)

=item * POST_REVPROP_CHANGE(SVN::Look, username, property-name, action)

=item * POST_UNLOCK(repos-path, username)

=item * PRE_COMMIT(SVN::Look)

=item * PRE_LOCK(repos-path, path, username, comment, steal-lock-flag)

=item * PRE_REVPROP_CHANGE(SVN::Look, username, property-name, action)

=item * PRE_UNLOCK(repos-path, path, username, lock-token, break-unlock-flag)

=item * START_COMMIT(repos-path, username, capabilities, txn-name)

=back

This is an example of a script implementing two hooks:

	#!/usr/bin/perl

	use SVN::Hooks;

	# ...

	START_COMMIT {
	    my ($repos_path, $username, $capabilities, $txn_name) = @_;

	    exists $committers{$username}
		or die "User '$username' is not allowed to commit.\n";

	    $capabilities =~ /mergeinfo/
		or die "Your Subversion client does not support mergeinfo capability.\n";
	};

	PRE_COMMIT {
	    my ($svnlook) = @_;

	    foreach my $added ($svnlook->added()) {
		$added !~ /\.(exe|o|jar|zip)$/
		    or die "Please, don't commit binary files such as '$added'.\n";
	    }
	};

	run_hook($0, @ARGV);

Note that the hook directives resemble function definitions but
they're not. They are function calls, and as such must end with a
semi-colon.

Most of the C<start-commit> and C<pre-*> hooks are used to check some
condition. If the condition holds, they must simply end without
returning anything. Otherwise, they must C<die> with a suitable error
message.

Also note that each hook directive can be called more than once if you
need to implement more than one specific hook. The hooks will run
in the order they were defined.

=head2 Using Plugins

There are several hooks already implemented as plugin modules under
the namespace C<SVN::Hooks::>, which you can use. The main ones are
described succinctly below. Please, see their own documentation for
more details.

=over

=item SVN::Hooks::AllowPropChange

Allow only specified users make changes in revision properties.

=item SVN::Hooks::CheckCapability

Check if the Subversion client implements the required capabilities.

=item SVN::Hooks::CheckJira

Integrate Subversion with the JIRA
L<http://www.atlassian.com/software/jira/> ticketing system.

=item SVN::Hooks::CheckLog

Check if the log message in a commit conforms to a Regexp.

=item SVN::Hooks::CheckMimeTypes

Check if the files added to the repository have the C<svn:mime-type>
property set. Moreover, for text files, check if the properties
C<svn:eol-style> and C<svn:keywords> are also set.

=item SVN::Hooks::CheckProperty

Check for specific properties for specific kinds of files.

=item SVN::Hooks::CheckStructure

Check if the files and directories being added to the repository
conform to a specific structure.

=item SVN::Hooks::DenyChanges

Deny the addition, modification, or deletion of specific files and
directories in the repository. Usually used to deny modifications in
the C<tags> directory.

=item SVN::Hooks::DenyFilenames

Deny the addition of files which file names doesn't comply with a
Regexp. Usually used to disallow some characteres in the filenames.

=item SVN::Hooks::Notify

Sends notification emails after successful commits.

=item SVN::Hooks::UpdateConfFile

Allows you to maintain Subversion configuration files versioned in the
same repository where they are used. Usually used to maintain the
configuration file for the hooks and the repository access control
file.

=back

This is an example of a script using some plugins:

	#!/usr/bin/perl

	use SVN::Hooks;
	use SVN::Hooks::CheckProperty;
	use SVN::Hooks::DenyChanges;
	use SVN::Hooks::DenyFilenames;

	# Accept only letters, digits, underlines, periods, and hifens
	DENY_FILENAMES(qr/[^-\/\.\w]/i);

	# Disallow modifications in the tags directory
	DENY_UPDATE(qr:^tags:);

	# OpenOffice.org documents need locks
	CHECK_PROPERTY(qr/\.(?:od[bcfgimpst]|ot[ghpst])$/i => 'svn:needs-lock');

	run_hook($0, @ARGV);

Those directives are implemented and exported by the hooks. Note that
using hooks you don't need to be explicit about which one of the nine
hooks will be triggered by the directives. This is on purpose, because
some plugins can trigger more than one hook. The plugin documentation
should tell you which hooks can be triggered so that you know which
symbolic links you need to create in the F<hooks> repository
directory.

=head2 Configuration file

Before calling the hooks, the function C<run_hook> evaluates a file
called F<svn-hooks.conf> under the F<conf> directory in the
repository, if it exists. Hence, you can choose to put all the
directives in this file and not in the script under the F<hooks>
directory.

The advantage of this is that you can then manage the configuration
file with the C<SVN::Hooks::UpdateConfFile> and have it versioned
under the same repository that it controls.

One way to do this is to use this hook script:

	#!/usr/bin/perl

	use SVN::Hooks;
	use SVN::Hooks::UpdateConfFile;
	use ...

	UPDATE_CONF_FILE(
	    'conf/svn-hooks.conf' => 'svn-hooks.conf',
	    validator             => [qw(/usr/bin/perl -c)],
	    rotate                => 2,
	);

	run_hook($0, @ARGV);

Use this hook script and create a directory called F<conf> at the root
of the repository (besides the common F<trunk>, F<branches>, and
F<tags> directories). Add the F<svn-hooks.conf> file under the F<conf>
directory. Then, whenever you commit a new version of the file, the
pre-commit hook will validate it sintactically (C</usr/bin/perl -c>)
and copy its new version to the F<conf/svn-hooks.conf> file in the
repository. (Read the L<SVN::Hooks::UpdateConfFile> documentation to
understand it in details.)

Being a Perl script, it's possible to get fancy with the configuration
file, using variables, functions, and whatever. But for most purposes
it consists just in a series of configuration directives.

Don't forget to end it with the C<1;> statement, though, because it's
evaluated with a C<do> statement and needs to end with a true
expression.

Please, see the plugins documentation to know about the directives.

=head1 PLUGIN DEVELOPER TUTORIAL

Yet to do.

=head1 EXPORT

=head2 run_hook

This is responsible to invoke the right plugins depending on the
context in which it was called.

Its first argument must be the name of the hook that was
called. Usually you just pass C<$0> to it, since it knows to extract
the basename of the parameter.

Its second argument must be the path to the directory where the
repository was created.

The remaining arguments depend on the hook for which it's being
called, like this:

=over

=item * start-commit repo-path user capabilities txn-name

=item * pre-commit repo-path txn

=item * post-commit repo-path rev

=item * pre-lock repo-path path user

=item * post-lock repo-path user

=item * pre-unlock repo-path path user

=item * post-unlock repo-path user

=item * pre-revprop-change repo-path rev user propname action

=item * post-revprop-change repo-path rev user propname action

=back

But as these are exactly the arguments Subversion passes when it calls
the hooks, you usually call C<run_hook> like this:

	run_hook($0, @ARGV);

=head1 REPOSITORY

L<https://github.com/gnustavo/SVN-Hooks>

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
