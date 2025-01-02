package Slackware::SBoKeeper;
use 5.016;
our $VERSION = '2.01';
use strict;
use warnings;

use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long;
use List::Util qw(uniq);

use Slackware::SBoKeeper::Config qw(read_config);
use Slackware::SBoKeeper::Database;
use Slackware::SBoKeeper::Home;
use Slackware::SBoKeeper::System;

my $PRGNAM = 'sbokeeper';
my $PRGVER = $VERSION;

my $HELP_MSG = <<END;
$PRGNAM $PRGVER
Usage: $0 [options] command [args]

Commands:
  add       <pkgs>       Add pkgs + dependencies.
  tack      <pkgs>       Add pkgs (no dependencies).
  addish    <pkgs>       Add pkgs + dependencies, do not mark as manually added.
  tackish   <pkgs>       Add pkgs, do not mark as manually added.
  rm        <pkgs>       Remove pkg(s).
  clean                  Remove unnecessary pkgs.
  deps      <pkg>        Print dependencies for pkg.
  depadd    <pkg> <deps> Add deps to pkg's dependencies.
  deprm     <pkg> <deps> Remove deps from pkg's dependencies.
  pull                   Find and add installed SlackBuilds.org pkgs.
  diff                   Show discrepancies between installed pkgs and database.
  depwant                Show missing dependencies for pkgs.
  depextra               Show extraneous dependencies for pkgs.
  unmanual  <pkgs>       Unset pkg(s) as manually added.
  print     <cats>       Print all pkgs in specified categories.
  tree      <pkgs>       Print dependency tree.
  dump                   Dump database.
  help      <cmd>        Print cmd help message.

Options:
  -c <path>   --config=<path>         Specify config file location.
  -d <path>   --datafile=<path>       Specify data file location.
  -s <path>   --sbodir=<path>         Specify SBo directory.
  -t <tag>    --tag=<tag>             Specify SlackBuild package tag.
  -y          --yes                   Automatically agree to all prompts.
  -h          --help                  Print help message and exit.
  -v          --version               Print version + copyright info and exit.
END

my $VERSION_MSG = <<END;
$PRGNAM $PRGVER

Copyright (C) 2024-2025 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See <https://dev.perl.org/licenses/> for more information.
END

my %COMMAND_HELP = (
	'add' => <<END,
Usage: add <pkg> ...

Add one or more packages to package database, marking them as manually added.
Dependencies will automatically be added as well. If a specified package is
already present in the database but is not marked as manually added, sbokeeper
will mark it as manually added.
END
	'tack' => <<END,
Usage: tack <pkg> ...

Add one or more packages to package database. Does not pull in dependencies.
Besides that, same behavior as add.
END
	'addish' => <<END,
Usage: addish <pkg> ...

Same thing as add, but added packages are not marked as manually added.
END
	'tackish' => <<END,
Usage: tackish <pkg> ...

Same thing as tack, but added packages are not marked as manually added.
END
	'rm' => <<END,
Usage: rm <pkg> ...

Removes one or more packages from package database. Dependencies are not
automatically removed.
END
	'clean' => <<END,
Usage: clean

Removes unnecessary packages from package database. This command is the same
as running 'sbokeeper rm \@unnecessary'.
END
	'deps' => <<END,
Usage: deps <pkg>

Prints list of dependencies for specified package, according to the database.
Does not print complete dependency tree, for that one should use the tree
command.
END
	'depadd' => <<END,
Usage: depadd <pkg> <dep> ...

Add one or more deps to pkg's dependencies. Dependencies that are not present in
the database will automatically be added.

** IMPORTANT**
Be cautious when using this command. This command provides an easy way for you
to screw up your package database by introducing circular dependencies which
sbokeeper cannot handle. When using this command, be sure you are not accidently
introducing circular dependencies!
END
	'deprm' => <<END,
Usage: deprm <pkg> <dep> ...

Remove one or more deps from pkg's dependencies.
END
	'pull' => <<END,
Usage: pull

Find any SlackBuilds.org packages that are installed on your system but not
present in your package database and attempt to add them to it. All packages
added are marked as manually added. Packages that are already present are
skipped.
END
	'diff' => <<END,
Usage: diff

Prints a list of SlackBuild packages that are present on your system but not in
your database and vice versa.
END
	'depwant' => <<END,
Usage: depwant

Prints a list of packages that, according to the SlackBuild repo, are missing
dependencies and prints a list of their dependencies.
END
	'depextra' => <<END,
Usage: depextra

Prints a list of packages with extra dependencies and said extra dependencies.
Extra dependencies are dependencies listed in the package database that are not
present in the SlackBuild repo.
END
	'unmanual' => <<END,
Usage: unmanual <pkg> ...

Unset one or more packages as being manually installed, but do not remove them
from database.
END
	'print' => <<END,
Usage: print [<cat> ...]

Prints a unique list of packages in the specified categories. The following are
valid categories:

  all           All added packages
  manual        Packages added manually
  nonmanual     Packages added not manually
  necessary     Packages added manually, or dependency of a manual package
  unnecessary   Packages not manually added and not depended on by another
  missing       Missing dependencies

If no category is specified, defaults to 'all'.
END
	'tree' => <<END,
Usage: tree [<pkgs>] ...

Prints a dependency tree. If pkgs is not specified, prints a dependency tree
for each manually added package. If pkgs are given, prints a dependency tree of
each package specified.
END
	'dump' => <<END,
Usage: dump

Dumps contents of data file to stdout.
END
	'help' => <<END,
Usage: help <cmd>

Print help message for cmd.
END
);

my @CONFIG_PATHS = (
	"$HOME/.config/sbokeeper.conf",
	"$HOME/.sbokeeper.conf",
	"/etc/sbokeeper.conf",
);

my $SLACKWARE_VERSION = Slackware::SBoKeeper::System->version();

my $DEFAULT_DATADIR = "$HOME/.local/share/$PRGNAM";

# Hash of commands and some info about them
# Method: Reference to the method to call.
# NeedDatabase: Does a database need to already be present?
# NeedSlack: Does the command only work on Slackware systems?
# Args: Minimum number of args needed.
my %COMMANDS = (
	'add' => {
		Method       => \&add,
		NeedDatabase => 0,
		NeedSlack    => 0,
		Args         => 1,
	},
	'tack' => {
		Method       => \&tack,
		NeedDatabase => 0,
		NeedSlack    => 0,
		Args         => 1,
	},
	'addish' => {
		Method       => \&addish,
		NeedDatabase => 0,
		NeedSlack    => 0,
		Args         => 1,
	},
	'tackish' => {
		Method       => \&tackish,
		NeedDatabase => 0,
		NeedSlack    => 0,
		Args         => 1,
	},
	'rm' => {
		Method       => \&rm,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 1,
	},
	'clean' => {
		Method       => \&clean,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 0,
	},
	'deps' => {
		Method       => \&deps,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 1,
	},
	'depadd' => {
		Method       => \&depadd,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 2,
	},
	'deprm' => {
		Method       => \&deprm,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 2,
	},
	'pull' => {
		Method       => \&pull,
		NeedDatabase => 0,
		NeedSlack    => 1,
		Args         => 0,
	},
	'diff' => {
		Method       => \&diff,
		NeedDatabase => 1,
		NeedSlack    => 1,
		Args         => 0,
	},
	'depwant' => {
		Method       => \&depwant,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 0,
	},
	'depextra' => {
		Method       => \&depextra,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 0,
	},
	'unmanual' => {
		Method       => \&unmanual,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 1,
	},
	'print' => {
		Method       => \&sbokeeper_print,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 0,
	},
	'tree' => {
		Method       => \&tree,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 0,
	},
	'dump' => {
		Method       => \&dump,
		NeedDatabase => 1,
		NeedSlack    => 0,
		Args         => 0,
	},
	'help' => {
		Method       => \&help,
		NeedDatabase => 0,
		NeedSlack    => 0,
		Args         => 0,
	},
);

my $CONFIG_READERS = {
	'DataFile' => sub {

		my $val = shift;

		$val =~ s/^~/$HOME/;

		unless (File::Spec->file_name_is_absolute($val)) {
			die "DataFile must be absolute path\n";
		}

		return $val;

	},
	'SBoPath' => sub {

		my $val = shift;

		$val =~ s/^~/$HOME/;

		unless (File::Spec->file_name_is_absolute($val)) {
			die "SBoPath must be absolute path\n";
		}

		unless (-d $val) {
			die "$val is not a directory or does not exist\n";
		}

		return $val;

	},
	'Tag' => sub {

		return shift;

	},
	'PkgtoolLogs' => sub {

		warn "'PkgtoolLogs' is deprecated\n";

		# We can't return nothing, so return :-/
		return ':-/';

	},
};

sub get_default_sbopath {

	unless (Slackware::SBoKeeper::System->is_slackware()) {
		return undef;
	}

	# Default repo locations for popular SlackBuild package managers. This sub
	# finds the first SlackBuild package manager that is installed in the
	# following list then returns its default repo location.
	my %sbopaths = (
		'00_sbopkg'    => "/var/lib/sbopkg/SBo/$SLACKWARE_VERSION",
		'01_sbotools'  => "/usr/sbo/repo",
		'02_sbotools2' => "/usr/sbo/repo",
		'03_sbpkg'     => "/var/lib/sbpkg/SBo/$SLACKWARE_VERSION",
		'04_slpkg'     => "/var/lib/slpkg/repos/sbo",
		'05_slackrepo' => "/var/lib/slackrepo/SBo/slackbuilds",
		# sboui should be last as it can be used with other
		# package management tools, meaning if it is installed along with
		# another manager it could possibly be using their default repo.
		'06_sboui'     => "/var/lib/sboui/repo",
	);

	foreach my $m (sort keys %sbopaths) {

		my $p = $m =~ s/^\d+_//r;

		unless (Slackware::SBoKeeper::System->installed($p)) {
			next;
		}

		next unless -d $sbopaths{$m};

		return $sbopaths{$m};

	}

	return undef;

}

sub yesno {

	my $prompt = shift;

	while (1) {

		print "$prompt [y/N] ";

		my $l = readline(STDIN);
		chomp $l;

		if (fc $l eq fc 'y') {
			return 1;
		# If no input is given, assume 'no'.
		} elsif (fc $l eq fc 'n' or $l eq '') {
			return 0;
		} else {
			print "Invalid input '$l'\n"
		}

	}

}

# Expand aliases to package lists. Also gets rid of redundant packages and sorts
# returned list.
sub alias_expand {

	my $sbokeeper = shift;
	my $args      = shift;

	my @rtrn;
	my @alias;

	foreach my $a (@{$args}) {
		if ($a =~ /^@/) {
			push @alias, $a;
		} else {
			push @rtrn, $a;
		}
	}

	foreach my $a (@alias) {
		# Get rid of '@'
		$a = substr $a, 1;
		push @rtrn, $sbokeeper->packages($a);
	}

	return uniq sort @rtrn;

}

sub backup {

	my $file = shift;

	if (-r $file) {
		copy($file, "$file.bak")
			or die "Failed to copy $file to $file.bak: $!\n";
	}

}

sub print_package_list {

	my $pref = shift;
	my @list = @_;

	@list = ('(none)') unless @list;

	foreach my $p (@list) {
		print "$pref$p\n";
	}

}

sub package_branch {

	my $sbokeeper = shift;
	my $pkg       = shift;
	my $str       = shift;

	my $has = $sbokeeper->has($pkg);

	# Add '(missing)' if package is not present in database but depended on by
	# another package.
	printf "%s%s %s\n", $str, $pkg, $has ? '' : '(missing?)';

	return unless $has;

	foreach my $d ($sbokeeper->immediate_dependencies($pkg)) {
		package_branch($sbokeeper, $d, $str . '  ');
	}

}

sub add {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		-s $self->{DataFile} ? $self->{DataFile} : '',
		$self->{SBoPath}
	);

	my @pkgs = alias_expand($sbokeeper, $self->{Args});

	my @add = $sbokeeper->add(\@pkgs, 1);

	printf "The following packages will be added:\n";
	print_package_list('  ', @add);
	printf "The following packages will be marked as manually added:\n";
	print_package_list('  ', grep { $sbokeeper->is_manual($_) } @pkgs);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages added\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages added\n", scalar @add;

}

sub tack {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		-s $self->{DataFile} ? $self->{DataFile} : '',
		$self->{SBoPath}
	);

	my @pkgs = alias_expand($sbokeeper, $self->{Args});

	my @add = $sbokeeper->tack(\@pkgs, 1);

	printf "The following packages will be added:\n";
	print_package_list('  ', @add);
	printf "The following packages will be marked as manually added:\n";
	print_package_list('  ', sort @pkgs);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages added\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages added\n", scalar @add;

}

sub addish {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		-s $self->{DataFile} ? $self->{DataFile} : '',
		$self->{SBoPath}
	);

	my @pkgs = alias_expand($sbokeeper, $self->{Args});

	my @add = $sbokeeper->add(\@pkgs, 0);

	unless (@add) {
		die "No packages could be added\n";
	}

	printf "The following packages will be added:\n";
	print_package_list('  ', @add);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages added\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages added\n", scalar @add;

}

sub tackish {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		-s $self->{DataFile} ? $self->{DataFile} : '',
		$self->{SBoPath}
	);

	my @pkgs = alias_expand($sbokeeper, $self->{Args});

	my @add = $sbokeeper->tack(\@pkgs, 0);

	unless (@add) {
		die "No packages could be added\n";
	}

	printf "The following packages will be added:\n";
	print_package_list('  ', @add);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages added\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages added\n", scalar @add;

}

sub rm {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my @pkgs = alias_expand($sbokeeper, $self->{Args});

	my @rm = $sbokeeper->remove(\@pkgs);

	unless (@rm) {
		die "No packages could be removed\n";
	}

	printf "The following packages will be removed:\n";
	print_package_list('  ', @rm);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages removed\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages removed\n", scalar @rm;

}

sub clean {

	my $self = shift;

	$self->{Args} = ['@unnecessary'];

	rm($self);

}

sub deps {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my $pkg = shift @{$self->{Args}};

	unless ($sbokeeper->has($pkg)) {
		die "$pkg not present in database\n";
	}

	my @deps = $sbokeeper->immediate_dependencies($pkg);

	print @deps ? "@deps\n" : "No dependencies found\n";

}

sub depadd {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my $pkg = shift @{$self->{Args}};
	my @deps = alias_expand($sbokeeper, $self->{Args});

	my @add = $sbokeeper->add(\@deps, 0);
	my @depadd = $sbokeeper->depadd($pkg, \@deps);

	if (!@add and !@depadd) {
		die "No dependencies could be added to $pkg\n";
	}

	printf "The following packages will be added to your database:\n";
	print_package_list('  ', @add);
	printf "The following dependencies will be added to %s:\n", $pkg;
	print_package_list('  ', @depadd);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages changed\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages added\n", scalar @add;
	printf "%d dependencies added to %s\n", scalar @depadd, $pkg;

}

sub deprm {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my $pkg = shift @{$self->{Args}};
	my @deps = alias_expand($sbokeeper, $self->{Args});

	my @rm = $sbokeeper->depremove($pkg, \@deps);

	unless (@rm) {
		die "No dependencies could be removed from $pkg\n";
	}

	printf "The following dependencies will be removed from %s\n", $pkg;
	print_package_list('  ', @rm);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages changed\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d dependencies removed from %s\n", scalar @rm, $pkg;

}

sub pull {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		-s $self->{DataFile} ? $self->{DataFile} : '',
		$self->{SBoPath}
	);

	my @installed = Slackware::SBoKeeper::System->packages_by_tag($self->{Tag});

	my @pull;

	foreach my $i (@installed) {

		unless ($sbokeeper->exists($i)) {
			warn "Could not find $i in SlackBuild repo, skipping\n";
			next;
		}

		next if $sbokeeper->has($i);

		push @pull, $i;

	}

	my @add = $sbokeeper->add(\@pull, 1);

	unless (@add) {
		print "No packages need to be added, doing nothing\n";
		return;
	}

	printf "The following packages will be added:\n";
	print_package_list('  ', @add);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages added\n";
		return;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	printf "%d packages added\n", scalar @add;

}

sub diff {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my %installed =
		map { $_ => 1 }
		Slackware::SBoKeeper::System->packages_by_tag($self->{Tag})
	;

	my %added = map { $_ => 1 } $sbokeeper->packages('all');

	my (@idiff, @adiff);

	foreach my $i (keys %installed) {
		push @idiff, $i unless defined $added{$i};
	}

	foreach my $a (keys %added) {
		push @adiff, $a unless defined $installed{$a};
	}

	if (!@idiff && !@adiff) {
		print "No package differences found\n";
		return;
	}

	# Tell the user if the packages that differ are actually in the repo or
	# not.
	@idiff =
		map { $sbokeeper->exists($_) ? $_ : "$_ (does not exist in repo)" }
		sort @idiff
	;
	# This shouldn't happen, but we'll check for consistency's sake.
	@adiff =
		map { $sbokeeper->exists($_) ? $_ : "$_ (does not exist in repo)" }
		sort @adiff
	;

	if (@idiff) {
		printf "Packages found installed on system that are not present in database:\n";
		print_package_list('  ', @idiff);
		printf "\n" if @adiff;
	}

	if (@adiff) {
		printf "Packages found in database that are not installed on system:\n";
		print_package_list('  ', @adiff);
	}

}

sub depwant {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my %missing = $sbokeeper->missing();

	unless (%missing) {
		print "There no dependencies missing from your database\n";
		return;
	}

	foreach my $p (sort keys %missing) {
		printf "%s:\n", $p;
		print_package_list('  ', @{$missing{$p}});
		print "\n";
	}

}

sub depextra {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my %extra = $sbokeeper->extradeps();

	unless (%extra) {
		print "No packages have extraneous dependencies in your database\n";
		return;
	}

	foreach my $p (sort keys %extra) {
		printf "%s:\n", $p;
		print_package_list('  ', @{$extra{$p}});
		print "\n";
	}

}

sub unmanual {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my @pkgs = alias_expand($sbokeeper, $self->{Args});

	foreach my $p (@pkgs) {
		die "$p is not present in database\n" unless $sbokeeper->has($p);
	}

	printf "The following packages will have their manually added flag unset\n";
	print_package_list('  ', @pkgs);
	my $ok = $self->{YesAll} ? 1 : yesno("Is this okay?");

	unless ($ok) {
		print "No packages changed\n";
		return;
	}

	my $n = 0;
	foreach my $p (@pkgs) {
		next unless $sbokeeper->is_manual($p);
		$sbokeeper->unmanual($p);
		$n++;
	}

	backup($self->{DataFile});
	$sbokeeper->write($self->{DataFile});

	print "$n packages updated\n";

}

sub sbokeeper_print {

	my $self = shift;

	my @cat = @{$self->{Args}};

	@cat = ('all') unless @cat;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my @pkgs =
		uniq sort
		map { $sbokeeper->packages($_) }
		# Get rid of alias '@' if present
		map { s/^@//r } @cat
	;

	print_package_list('', @pkgs) if @pkgs;

}

sub tree {

	my $self = shift;

	my $sbokeeper = Slackware::SBoKeeper::Database->new(
		$self->{DataFile},
		$self->{SBoPath}
	);

	my @pkgs;
	if (@{$self->{Args}}) {

		@pkgs = alias_expand($sbokeeper, $self->{Args});

		foreach my $p (@pkgs) {
			die "$p is not present in package database\n"
				unless $sbokeeper->has($p);
		}

	} else {

		@pkgs = $sbokeeper->packages('manual');

	}

	foreach my $p (@pkgs) {
		package_branch($sbokeeper, $p, '');
		print "\n";
	}

}

sub dump {

	my $self = shift;

	open my $fh, '<', $self->{DataFile}
		or die "Failed to open sbokeeper data file $self->{DataFile} for " .
		       "reading: $!\n";

	while (my $l = readline $fh) {
		print $l;
	}

}

sub help {

	my $self = shift;

	# If no argument was given, just print help message and exit.
	unless (@{$self->{Args}}) {
		print $HELP_MSG;
		exit 0;
	}

	my $help = lc shift @{$self->{Args}};

	unless (defined $COMMAND_HELP{$help}) {
		die "$help is not a command\n";
	}

	print $COMMAND_HELP{$help};

}

sub init {

	my $class = shift;

	my $self = {
		ConfigFile  => '',
		DataFile    => '',
		SBoPath     => '',
		Tag         => '',
		YesAll      => 0,
		Command     => '',
		Args        => [],
	};

	Getopt::Long::config('bundling');
	GetOptions(
		'config|c=s'       => \$self->{ConfigFile},
		'datafile|d=s'     => \$self->{DataFile},
		'sbodir|s=s'       => \$self->{SBoPath},
		'tag|t=s'          => \$self->{Tag},
		'yes|y'            => \$self->{YesAll},
		'help|h'           => sub { print $HELP_MSG;    exit 0 },
		'version|v'        => sub { print $VERSION_MSG; exit 0 },
	) or die "Error in command line arguments\n";

	unless (@ARGV) {
		die $HELP_MSG;
	}

	unless ($self->{ConfigFile}) {
		($self->{ConfigFile}) = grep { -r } @CONFIG_PATHS;
	}

	if ($self->{ConfigFile}) {
		my $config = read_config($self->{ConfigFile}, $CONFIG_READERS);
		foreach my $cf (keys %{$config}) {
			$self->{$cf} ||= $config->{$cf};
		}
	}

	$self->{Command} = lc shift @ARGV;

	$self->{Args} = \@ARGV;

	unless ($self->{DataFile}) {
		make_path($DEFAULT_DATADIR) unless -d $DEFAULT_DATADIR;
		$self->{DataFile} = "$DEFAULT_DATADIR/data.$PRGNAM";
	}

	unless ($self->{SBoPath}) {
		$self->{SBoPath} = get_default_sbopath($self->{PkgtoolLogs})
			or die "Cannot determine default path for SBo repo, please use " .
			       "the 'SBoPath' config option or '-s' CLI option\n";
	}

	unless (-d $self->{SBoPath}) {
		die "SlackBuild repo directory $self->{SBoPath} does not exit or " .
		    "is not a directory\n";
	}

	$self->{Tag} ||= '_SBo';

	return bless $self, $class;

}

sub run {

	my $self = shift;

	unless (defined $COMMANDS{$self->{Command}}) {
		die "$self->{Command} is not a valid command\n";
	}

	if (
		$COMMANDS{$self->{Command}}->{NeedDatabase} and
		not -s $self->{DataFile}
	) {
		die "'$self->{Command}' requires an already-existing database\n";
	}

	if (
		$COMMANDS{$self->{Command}}->{NeedSlack} and
		not Slackware::SBoKeeper::System->is_slackware()
	) {
		die "'$self->{Command}' can only be used in Slackware systems\n";
	}

	if (+@{$self->{Args}} < $COMMANDS{$self->{Command}}->{Args}) {
		die $COMMAND_HELP{$self->{Command}};
	}

	$COMMANDS{$self->{Command}}->{Method}($self);

}

1;

=head1 NAME

Slackware::SBoKeeper - SlackBuild package manager helper

=head1 SYNOPSIS

  use Slackware::SBoKeeper;

  my $sbokeeper = Slackware::SBoKeeper->init();
  $sbokeeper->run();

=head1 DESCRIPTION

Slackware::SBoKeeper is the workhorse module behind L<sbokeeper>. It should not
be used by any other script/program other than L<sbokeeper>. If you are looking
for L<sbokeeper> user documentation, please consult its manual.

=head1 SUBROUTINES/METHODS

=over 4

=item init()

Reads C<@ARGV> and returns a blessed Slackware::SBoKeeper object. For the list
of options that are available to C<init()>, please consult the L<sbokeeper>
manual.

=item run()

Runs L<sbokeeper>.

=back

The following methods correspond to L<sbokeeper> commands. Consult its manual
for information on their functionality.

=over 4

=item add()

=item tack()

=item addish()

=item tackish()

=item rm()

=item clean()

=item deps()

=item depadd()

=item deprm()

=item pull()

=item diff()

=item depwant()

=item depextra()

=item unmanual()

=item sbokeeper_print()

=item tree()

=item dump()

=item help()

=back

=head1 AUTHOR

Written by Samuel Young, L<samyoung12788@gmail.com>.

=head1 BUGS

Report bugs on my Codeberg, E<lt>https://codeberg.org/1-1samE<gt>.

=head1 COPYRIGHT

Copyright (C) 2024-2025 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

=head1 SEE ALSO

L<sbokeeper>

=cut
