#!/usr/bin/perl
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2009,2010,2012,2013,2014,2015 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use strict;
use warnings;

use CPAN::DistnameInfo ();

######################################################################

{
    package Parse::CPAN::Packages::Fast;

    our $VERSION = '0.09';
    $VERSION =~ s{_}{};

    use IO::Uncompress::Gunzip qw($GunzipError);
    use CPAN::Version ();

    # Note: this function is possibly interactive, i.e. if CPAN.pm was
    # never configured, or if CPAN's Config.pm needs reconfiguration.
    sub _default_packages_file_interactive {
	my($class) = @_;
	require CPAN;
	no warnings 'once';
	local $CPAN::Be_Silent = 1;
	CPAN::HandleConfig->load;
	my $packages_file = $CPAN::Config->{keep_source_where} . "/modules/02packages.details.txt.gz";
	$packages_file;
    }

    # Note: this function is guaranteed to be non-interactive, but it
    # is using just default locations to look at the CPAN config, or
    # the 02packages files.
    sub _default_packages_file_batch {
	my($class) = @_;

	my $home_cpandir = do {
	    no warnings 'uninitialized'; # HOME may be uninitialized on some systems e.g. Windows
	    "$ENV{HOME}/.cpan";
	};
	if (!$INC{"CPAN/MyConfig.pm"}) {
	    my $home_myconfig = "$home_cpandir/CPAN/MyConfig.pm";
	    if (-r $home_myconfig) {
		local @INC = ($home_cpandir);
		eval { require CPAN::MyConfig };
	    }
	}
	if ($INC{"CPAN/MyConfig.pm"} && $CPAN::Config->{keep_source_where}) {
	    my $packages_file = $CPAN::Config->{keep_source_where} . "/modules/02packages.details.txt.gz";
	    if (-r $packages_file && -s $packages_file) {
		return $packages_file;
	    }
	}

	# Cannot find a usable CPAN::MyConfig, try a default location
	my $packages_file = "$home_cpandir/sources/modules/02packages.details.txt.gz";
	if (-r $packages_file && -s $packages_file) {
	    return $packages_file;
	}

	undef;
    }

    *_default_packages_file = \&_default_packages_file_interactive;

    sub new {
	my($class, $packages_file) = @_;

	if (!$packages_file) {
	    $packages_file = $class->_default_packages_file;
	    if (!$packages_file) {
		die "packages file not specified and cannot be determined from CPAN.pm configuration";
	    }
	}

	my %pkg_to_dist;
	my %dist_to_pkgs;
	my %pkg_ver;

	my $FH;
	if ($packages_file !~ m{\.gz$}) { # assume uncompressed file
	    open $FH, '<', $packages_file
		or die "Can't open $packages_file: $!";
	} else {
	    $FH = IO::Uncompress::Gunzip->new($packages_file)
		or die "Can't open $packages_file: $GunzipError";
	}
	# overread header
	while(<$FH>) {
	    last if /^$/;
	}
	# read payload
	while(<$FH>) {
	    my($pkg, $ver, $dist) = split;
	    $pkg_to_dist{$pkg} = $dist;
	    $pkg_ver{$pkg} = $ver;
	    push @{ $dist_to_pkgs{$dist} }, $pkg;
	}
	
	bless { pkg_to_dist  => \%pkg_to_dist,
		dist_to_pkgs => \%dist_to_pkgs,
		pkg_ver      => \%pkg_ver,
	      }, $class;
    }

    sub package {
	my($self, $package_name) = @_;
	return undef if !exists $self->{pkg_ver}{$package_name};
	Parse::CPAN::Packages::Fast::Package->new($package_name, $self);
    }

    sub packages {
	my $self = shift;
	keys %{ $self->{pkg_ver} };
    }

    sub package_count {
	my $self = shift;
	scalar keys %{ $self->{pkg_ver} };
    }

    sub distribution {
	my($self, $distribution_name) = @_;
	die "Distribution $distribution_name does not exist" if !exists $self->{dist_to_pkgs}{$distribution_name}; # XXX die or not?
	Parse::CPAN::Packages::Fast::Distribution->new($distribution_name, $self);
    }

    sub distributions {
	my $self = shift;
	map { Parse::CPAN::Packages::Fast::Distribution->new($_, $self) } keys %{ $self->{dist_to_pkgs} };
    }

    sub distribution_count {
	my $self = shift;
	my @dists = $self->distributions;
	scalar @dists;
    }

    sub latest_distribution {
	my($self, $distribution_name) = @_;
	my @candidates;
	for my $candidate (keys %{ $self->{dist_to_pkgs} }) {
	    if ($candidate =~ m{^./../.*/\Q$distribution_name}) {
		# Possibly pure CPAN::DistnameInfo is somewhat faster
		# than Parse::CPAN::Packages::Fast::Distribution (no
		# inside-out handling, no additional DESTROY)
		my $d = CPAN::DistnameInfo->new($candidate);
		no warnings 'uninitialized'; # Some distributions have no parseable dist name
		if ($d->dist eq $distribution_name) {
		    push @candidates, $d;
		}
	    }
	}
	return if !@candidates; # XXX die or not?
	my $best_candidate = pop @candidates;
	my $best_candidate_version = $best_candidate->version;
	for my $candidate (@candidates) {
	    my $this_version = $candidate->version;
	    if (CPAN::Version->vlt($best_candidate_version, $this_version)) {
		$best_candidate = $candidate;
		$best_candidate_version = $this_version;
	    }
	}
	Parse::CPAN::Packages::Fast::Distribution->new($best_candidate->pathname, $self);
    }

    sub latest_distributions {
	my $self = shift;
	my %latest_dist;
	for my $pathname (keys %{ $self->{dist_to_pkgs} }) {
	    my $d = Parse::CPAN::Packages::Fast::Distribution->new($pathname, $self);
	    my $dist = $d->dist;
	    next if !defined $dist;
	    if (!exists $latest_dist{$dist}) {
		$latest_dist{$dist} = $d;
	    } else {
		if (CPAN::Version->vlt($latest_dist{$dist}->version, $d->version)) {
		    $latest_dist{$dist} = $d;
		}
	    }
	}
	values %latest_dist;
    }

    sub latest_distribution_count {
	my $self = shift;
	my @dists = $self->latest_distributions;
	scalar @dists;
    }

    # Addition: fast module lookup without loading whole packages file
    # Not yet official!
    sub _module_lookup {
	die "Usage?" if @_ != 4;
	my($class, $module, $orig_packages_file, $cache_file) = @_;
	require Search::Dict;
	my $pwhfh = $class->_get_plain_packages_fh($orig_packages_file, $cache_file);
	my $skey = "$module ";
	return if Search::Dict::look($pwhfh, $skey, 0, 1) == -1;
	while () {
	    my $got = <$pwhfh>;
	    if (index($got, $skey) == 0) {
		chomp $got;
		my($pkg, $ver, $dist) = split /\s+/, $got;
		return {
			package => $pkg,
			version => $ver,
			dist    => $dist,
		       };
	    }
	    return if lc(substr($got, 0, length($skey))) gt lc($skey);
	    return if eof($pwhfh);
	}
    }
	
    sub _get_plain_packages_fh {
	die "Usage?" if @_ != 3;
	my(undef, $orig_packages_file, $cache_file) = @_;
	die "$orig_packages_file does not exist" if !-e $orig_packages_file;
	if (!-e $cache_file || -M $cache_file > -M $orig_packages_file) {
	    my $ifh = IO::Uncompress::Gunzip->new($orig_packages_file)
		or die "Can't open $orig_packages_file: $GunzipError";
	    require File::Temp;
	    require File::Basename;
	    my($tmpfh,$tmpfile) = File::Temp::tempfile(DIR => File::Basename::dirname($cache_file))
		or die "Can't create temporary file: $!";
	    while (<$ifh>) {
		last if /^$/;
	    }
	    {
		local $/ = \8192;
		while (<$ifh>) {
		    print $tmpfh $_;
		}
	    }
	    close $tmpfh
		or die "Error while writing temporary file $tmpfile: $!";
	    rename $tmpfile, $cache_file
		or die "While renaming $tmpfile to $cache_file: $!";
	}
	open my $fh, $cache_file
	    or die "Can't open $cache_file: $!";
	$fh;
    }
	
}

######################################################################

{

    package Parse::CPAN::Packages::Fast::Package;

    our $VERSION = $Parse::CPAN::Packages::Fast::VERSION;

    # Use inside-out technique for this member, to hide it in dumps etc.
    my %obj_to_packages;

    sub new {
	my($class, $package_name, $packages) = @_;
	my $self = bless { package  => $package_name,
			   version  => $packages->{pkg_ver}{$package_name},
			 }, 'Parse::CPAN::Packages::Fast::Package';
	$obj_to_packages{$self} = $packages;
	$self;
    }

    for my $method (qw(package version)) {
	no strict 'refs';
	*{$method} = sub { shift->{$method} };
    }

    sub distribution {
	my $self = shift;
	my $packages = $obj_to_packages{$self};
	my $dist = $packages->{pkg_to_dist}->{$self->package};
	Parse::CPAN::Packages::Fast::Distribution->new($dist, $packages);
    }

    sub prefix {
	my $self = shift;
	$self->distribution->prefix;
    }

    sub DESTROY {
	my $self = shift;
	delete $obj_to_packages{$self};
    }
}

######################################################################

{
    package Parse::CPAN::Packages::Fast::Distribution;

    our $VERSION = $Parse::CPAN::Packages::Fast::VERSION;

    use base qw(CPAN::DistnameInfo);

    # Use inside-out technique for this member, to hide it in dumps etc.
    my %obj_to_packages;

    sub new {
	my($class, $pathname, $packages) = @_;
	my $self = $class->SUPER::new($pathname);
	$obj_to_packages{$self} = $packages;
	$self;
    }
    
    sub prefix {
	my $self = shift;
	my $prefix = $self->pathname;
	$prefix =~ s{^authors/id/}{};
	$prefix;
    }

    sub contains {
	my $self = shift;
	my $packages = $obj_to_packages{$self};
	map { Parse::CPAN::Packages::Fast::Package->new($_, $packages) } @{ $packages->{dist_to_pkgs}{$self->pathname} };
    }

    sub DESTROY {
	my $self = shift;
	delete $obj_to_packages{$self};
    }

    # Methods found in original Parse::CPAN::Packages::Distribution
    sub add_package {
	die "NYI";
    }

    # Would be nice to have:
    sub is_latest_distribution {
	die "NYI";
    }
}

######################################################################

1;

__END__

=head1 NAME

Parse::CPAN::Packages::Fast - parse CPAN's package index

=head1 SYNOPSIS

    use Parse::CPAN::Packages::Fast;

    my $p = Parse::CPAN::Packages::Fast->new("/path/to/02packages.details.txt.gz");
    ## Or alternatively, if CPAN.pm is configured
    #my $p = Parse::CPAN::Packages::Fast->new;

    my $m = $p->package("Kwalify");
    # $m is a Parse::CPAN::Packages::Fast::Package object
    print $m->package, "\n";   # Kwalify
    print $m->version, "\n";   # 1.21

    my $d = $m->distribution;
    # $d is a Parse::CPAN::Packages::Fast::Distribution object
    print $d->dist,    "\n";   # Kwalify
    print $d->version, "\n";   # 1.21

=head1 DESCRIPTION

This is a largely API compatible rewrite of L<Parse::CPAN::Packages>.

Notable differences are

=over

=item * The method add_package of
Parse::CPAN::Packages::Fast::Distribution is not implemented

=item * Parse::CPAN::Packages::Fast::Distribution is really a
L<CPAN::DistnameInfo> (but this one is compatible with
Parse::CPAN::Packages::Distribution>

=item * A Parse::CPAN::Packages::Fast::Distribution object does not
have its packages included in the data structure, but it's necessary
to use the C<contains> method. Likewise, a
Parse::CPAN::Packages::Fast::Package object does not include the
containing distribution in the data structure, but it's necessary to
use the C<distribution> method.

=item * The C<new> constructor may be called without the path to the
C<02packages.details.txt> file. In this case L<CPAN.pm|CPAN>'s logic
is used to find an existing packages file. Note that this might be
interactive (i.e. if CPAN.pm was never configured, or needs
reconfiguration), so don't do this in batch systems.

=back

=head2 WHY?

Calling C<Parse::CPAN::Packages>' constructor is quite slow and takes
about 10 seconds on my machine. In contrast, the reimplementation just
takes a second.

I did some benchmarking of the original module and found no obvious
weak point to speed it up. Moose is used here, but does not seem to
cause the problem. I suspect that the real problem is just heavy use
of method calls.

Also, this module does not have problems with circular references like
the original. See L<Parse::CPAN::Packages/BUGS>.

=head1 SEE ALSO

L<Parse::CPAN::Packages>, L<CPAN::DistnameInfo>.

=cut
