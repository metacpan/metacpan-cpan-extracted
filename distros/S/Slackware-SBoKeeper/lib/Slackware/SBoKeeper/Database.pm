package Slackware::SBoKeeper::Database;
use 5.016;
our $VERSION = '2.05';
use strict;
use warnings;

use List::Util qw(any uniq);

sub write_data {

	my $data = shift;
	my $out  = shift;

	open my $fh, '>', $out or die "Failed to open $out for writing: $!\n";

	foreach my $p (sort keys %{$data}) {

		say { $fh } "PACKAGE: $p";
		say { $fh } "DEPS: ", join(' ', @{$data->{$p}->{Deps}});
		say { $fh } "MANUAL: $data->{$p}->{Manual}";
		say { $fh } '%%';

	}

	close $fh;

}

sub read_data {

	my $file      = shift;
	my $blacklist = shift // {};

	my $data = {};

	open my $fh, '<', $file or die "Failed to open $file for reading: $!\n";

	my $pkg = '';
	my $lnum = 1;

	while (my $l = readline $fh) {

		chomp $l;

		if ($l eq '%%') {
			$pkg = '';
		} elsif ($l =~ /^PACKAGE: /) {
			$pkg = $l =~ s/^PACKAGE: //r;
			$data->{$pkg} = {};
		} elsif ($pkg eq '') {
			die "Bad line in $file at line $lnum: PACKAGE not set\n";
		} elsif ($l =~ /^DEPS: /) {
			my $depstr = $l =~ s/^DEPS: //r;
			@{$data->{$pkg}->{Deps}} =
				grep { not exists $blacklist->{$_} }
				split /\s/, $depstr;
		} elsif ($l =~ /^MANUAL: /) {
			my $manual = $l =~ s/^MANUAL: //r;
			$data->{$pkg}->{Manual} = $manual eq '1' ? 1 : 0;
		} else {
			die "Bad line in $file at line $lnum\n";
		}

		$lnum++;

	}

	close $fh;

	# Weed out blacklisted packages
	for my $p (keys %{$blacklist}) {
		delete $data->{$p};
	}

	return $data;

}

sub new {

	my $class     = shift;
	my $file      = shift;
	my $sbodir    = shift;
	my $blacklist = shift // {};

	$blacklist->{'%README%'} = 1;

	my $self = {
		_data      => {},
		_sbodir    => '',
		_blacklist => $blacklist,
	};

	if ($file) {
		$self->{_data} = read_data($file, $self->{_blacklist});
	}

	$self->{_sbodir} = $sbodir;

	bless $self, $class;
	return $self;

}

sub add {

	my $self   = shift;
	my $pkgs   = shift;
	my $manual = shift;

	my @added;

	foreach my $p (@{$pkgs}) {

		next if $self->blacklist($p);

		unless ($self->exists($p)) {
			die "$p does not exist in SlackBuild repo\n";
		}

		# pkg already present, do not add. Set manual flag if desired.
		if (defined $self->{_data}->{$p}) {
			$self->{_data}->{$p}->{Manual} = $manual if $manual;
			next;
		}

		$self->{_data}->{$p}->{Manual} = $manual;

		my @deps = $self->real_immediate_dependencies($p);
		$self->{_data}->{$p}->{Deps} = \@deps;

		my @add = $self->add($self->{_data}->{$p}->{Deps}, 0);

		push @added, @add;
		push @added, $p;

	}

	return sort @added;

}

sub tack {

	my $self   = shift;
	my $pkgs   = shift;
	my $manual = shift;

	my @tack;

	foreach my $p (@{$pkgs}) {

		next if $self->blacklist($p);

		unless ($self->exists($p)) {
			die "$p does not exist in SlackBuild repo\n";
		}

		if (defined $self->{_data}->{$p} and $manual) {
			$self->{_data}->{$p}->{Manual} = $manual;
			push @tack, $p;
		} else {
			$self->{_data}->{$p} = {
				Deps   => [],
				Manual => $manual,
			};
			push @tack, $p;
		}

	}

	return @tack;

}

sub remove {

	my $self = shift;
	my $pkgs = shift;

	my @rm;

	foreach my $p (@{$pkgs}) {

		unless (defined $self->{_data}->{$p}) {
			warn "$p not present in database, not removing\n";
			next;
		}

		delete $self->{_data}->{$p};

		push @rm, $p;

	}

	return sort @rm;

}

sub depadd {

	my $self = shift;
	my $pkg  = shift;
	my $deps = shift;

	unless ($self->has($pkg)) {
		die "$pkg is not present in database\n";
	}

	my @add;
	foreach my $d (@{$deps}) {

		next if $self->blacklist($d);

		unless ($self->has($d)) {
			warn "$d not present in database, skipping\n";
			next;
		}

		unless (any { $d eq $_ } @{$self->{_data}->{$pkg}->{Deps}}) {
			push @{$self->{_data}->{$pkg}->{Deps}}, $d;
			push @add, $d;
		}

	}

	return @add;

}

sub depremove {

	my $self = shift;
	my $pkg  = shift;
	my $deps = shift;

	my @kept;
	my @rm;
	foreach my $p (@{$self->{_data}->{$pkg}->{Deps}}) {
		if (any { $p eq $_ } @{$deps}) {
			push @rm, $p;
		} else {
			push @kept, $p;
		}
	}

	$self->{_data}->{$pkg}->{Deps} = \@kept;

	return @rm;

}

sub has {

	my $self = shift;
	my $pkg  = shift;

	return defined $self->{_data}->{$pkg};

}

sub packages {

	my $self = shift;

	return sort keys %{$self->{_data}};

}

sub missing {

	my $self = shift;

	my %missing;

	foreach my $p ($self->packages) {

		my @pmissing =
			grep { !$self->has($_) }
			$self->real_immediate_dependencies($p);

		push @{$missing{$p}}, @pmissing if @pmissing;

	}

	return %missing;

}

sub extradeps {

	my $self = shift;

	my @pkgs = $self->packages;

	my %extra;

	foreach my $p (@pkgs) {

		my %realdeps = map { $_ => 1 } $self->real_immediate_dependencies($p);

		my @pextra =
			grep { !defined $realdeps{$_} }
			$self->immediate_dependencies($p);

		push @{$extra{$p}}, @pextra if @pextra;

	}

	return %extra;

}

sub is_necessary {

	my $self = shift;
	my $pkg  = shift;

	unless (defined $self->{_data}->{$pkg}) {
		return 0;
	}

	if ($self->{_data}->{$pkg}->{Manual}) {
		return 1;
	}

	# Check if $pkg is a dependency of any manually installed package

	return
		any { $self->is_dependency($pkg, $_) }
		grep { $self->is_manual($_) }
		$self->packages
	;

}

sub is_dependency {

	my $self = shift;
	my $dep  = shift;
	my $of   = shift;

	foreach my $p (@{$self->{_data}->{$of}->{Deps}}) {

		if ($p eq $dep) {
			return 1;
		}

		if ($self->is_dependency($dep, $p)) {
			return 1;
		}

	}

	return 0;

}

sub is_immediate_dependency {

	my $self = shift;
	my $dep  = shift;
	my $of   = shift;

	foreach my $p (@{$self->{_data}->{$of}->{Deps}}) {
		if ($p eq $dep) {
			return 1;
		}
	}

	return 0;

}

sub is_manual {

	my $self = shift;
	my $pkg  = shift;

	return $self->{_data}->{$pkg}->{Manual} ? 1 : 0;

}

sub exists {

	my $self = shift;
	my $pkg  = shift;

	return 0 if $self->blacklist($pkg);

	if (() = glob "$self->{_sbodir}/*/$pkg/$pkg.info") {
		return 1;
	} else {
		return 0;
	}

}

sub blacklist {

	my $self = shift;
	my $pkg  = shift;

	return exists $self->{_blacklist}->{$pkg};

}

sub dependencies {

	my $self = shift;
	my $pkg  = shift;

	my @deps;

	@deps = $self->immediate_dependencies($pkg);

	foreach my $d (@deps) {
		push @deps, $self->dependencies($d);
	}

	return uniq sort @deps;

}

sub immediate_dependencies {

	my $self = shift;
	my $pkg  = shift;

	return sort @{$self->{_data}->{$pkg}->{Deps}};

}

sub real_dependencies {

	my $self = shift;
	my $pkg  = shift;

	my @deps;

	@deps = $self->real_immediate_dependencies($pkg);

	foreach my $d (@deps) {
		push @deps, $self->real_dependencies($d);
	}

	return uniq sort @deps;

}

sub real_immediate_dependencies {

	my $self = shift;
	my $pkg  = shift;

	my @deps;

	my ($info) = glob "$self->{_sbodir}/*/$pkg/$pkg.info";

	die "Could not find $pkg in $self->{_sbodir}\n" unless $info;

	open my $fh, '<', $info
		or die "Failed to open $info for reading: $!\n";

	while (my $l = readline $fh) {

		chomp $l;

		next unless $l =~ /^REQUIRES=".*("|\\)$/;

		my ($depstr) = $l =~ /^REQUIRES="(.*)("|\\)/;

		@deps = grep { !$self->blacklist($_) } split /\s/, $depstr;

		while (substr($l, -1) eq '\\') {

			$l = readline $fh;
			chomp $l;

			($depstr) = $l =~ /(^.*)("|\\)/;

			push @deps, grep { !$self->blacklist($_) } split(" ", $depstr);

		}

		last;

	}

	close $fh;

	return sort @deps;

}

sub reverse_dependencies {

	my $self = shift;
	my $pkg  = shift;

	return grep {
		$self->is_immediate_dependency($pkg, $_)
	} $self->packages;

}

sub unmanual {

	my $self = shift;
	my $pkg  = shift;

	unless (defined $self->{_data}->{$pkg}) {
		return 0;
	}

	$self->{_data}->{$pkg}->{Manual} = 0;

	return 1;

}

sub write {

	my $self = shift;
	my $path = shift;

	write_data($self->{_data}, $path);

}

1;



=head1 NAME

Slackware::SBoKeeper::Database - Read/write sbokeeper databases

=head1 SYNOPSIS

 use Slackware::SBoKeeper::Database;

 my $database = Slackware::SBoKeeper::Database->new($file, $repo);
 ...

=head1 DESCRIPTION

Slackware::SBoKeeper::Database is a module that handles reading and writing
L<sbokeeper> package database files. It is not meant to be used outside of
L<sbokeeper>. For user documentation of L<sbokeeper>, please consult its manual.

=head1 SUBROUTINES/METHODS

=head2 new($path, $sbodir, [ $blacklist ])

Returns blessed Slackware::SBoKeeper::Database object. $path is the path to a
file containing B<sbokeeper> data. If $path is '', creates an empty
database. $sbodir is the directory where the SBo repository is stored.

$blacklist is a hash ref of packages to ignore. Defaults to empty hash ref if
no hash is supplied.

=head2 add($pkgs, $manual)

Add array ref of pkgs and their dependencies to object. If $manual is true,
$pkgs are set to manually added (dependencies are still not).

Returns array of packages added.

=head2 tack($pkgs, $manual)

Add array ref of pkgs to database. $manual determines whether they are marked
as manually added or not. Does not pull in dependencies.

Returns array of packages added.

=head2 remove($pkgs)

Remove array ref pkgs from object. Dependencies pulled in from removed packages
will still remain.

Returns array of packages removed.

=head2 depadd($pkg, $deps)

Add array ref $deps to $pkg's dependencies. $deps must be a list of packages
already present in the database.

Returns list of dependencies added to $pkg.

=head2 depremove($pkg, $deps)

Removes array ref $deps from $pkg's dependency list.

Returns list of dependencies removed.

=head2 has($pkg)

Returns 1 or 0 depending on whether $pkg is currently in the database.

=head2 packages()

Returns array of packages present in database.

=head2 missing()

Returns hash of packages and their missing dependencies, according to the
SlackBuild repo.

=head2 extradeps()

Returns hash of packages with extra dependencies. An extra dependency is a
dependency that is not required by the package in the SlackBuild repo.

=head2 is_necessary($pkg)

Checks to see if $pkg is necessary (manually added or dependency on a manually
added package). Returns 1 for yes, 0 for no.

=head2 is_dependency($dep, $of)

Checks to see if $dep is a dependency (or a dependency of a dependency, etc.) of
$of. Returns 1 for yes, 0 for no.

$dep and $of must already be added to the object.

=head2 is_immediate_dependency($dep, $of)

Checks to see if $dep is a dependency of $of. Returns 1 for yes, 0 for no.

$dep and $of must already be added to the object.

=head2 is_manual($pkg)

Checks if $pkg is manually installed. Returns 1 for yes, 0 no.

=head2 exists($pkg)

Checks if $pkg is present in repo. Returns 1 for yes, 0 for no.

=head2 blacklist($pkg)

Checks if $pkg is in the blacklist. Returns 1 for yes, 0 for no.

=head2 dependencies($pkg)

Returns list of packages that are a dependency of $pkg, according to the
database.

=head2 immediate_dependencies($pkg)

Returns list of packages that are an immediate dependency of $pkg, according to
the database. Does not return dependencies of those dependencies.

=head2 real_dependencies($pkg)

Returns list of packages that are a dependency of $pkg, according to the
SlackBuild repo. $pkg does not have to have been added previously.

=head2 real_immediate_dependencies($pkg)

Returns list of packages that are an immediate dependency of $pkg, according
to the SlackBuild repo. Does not return packages that are dependencies of those
dependencies. $pkg does not have to have been added previously.

=head2 reverse_dependencies($pkg)

Returns list of packages that depend on $pkg, according to the sbokeeper
database.

=head2 unmanual($pkg)

Unset $pkg as manually installed. Returns 1 if successful, 0 if not.

=head2 write($path)

Write data file to $path.

=head1 DATA FILES

B<sbokeeper> data files are text files. Data files contain packages, which are
a series of lines that contain package information ended by a pair of percentage
signs (%%). A package entry should look something like this:

 PACKAGE: libreoffice
 DEPS: avahi zulu-openjdk8
 MANUAL: 1
 %%

=over 4

=item PACKAGE

Name of the package, which must have a corresponding SlackBuild in the
configured SlackBuild repo. This must be the first line in a package entry.

=item DEPS

Whitespace-seperated list of packages that PACKAGE depends on. Each package
must be present in the SlackBuild repo.

=item MANUAL

Specifies whether the package was manually added or not. 1 for yes, 0 for no.

=item %%

Marks the end of the current package entry.

=back

=head1 AUTHOR

Written by Samuel Young E<lt>samyoung12788@gmail.comE<gt>.

=head1 BUGS

This module does not know how to handle circular dependencies. This should not
be a problem if you stick with the official SlackBuild repo. One should
exercise caution when using the depadd method, as it can easily introduce
circular dependencies.

Report bugs on my Codeberg, L<https://codeberg.org/1-1sam>.

=head1 COPYRIGHT

Copyright (C) 2024-2025 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

=head1 SEE ALSO

L<sbokeeper>

=cut
