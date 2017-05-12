# -*- perl -*-
#
# Test::AutoBuild::Stage::ISOBuilder by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2004 Daniel Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::Stage::ISOBuilder - creates CD ISO images

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::ISOBuilder


=head1 DESCRIPTION

This module creates CD ISO images containing packages for
a number of modules

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::ISOBuilder;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Digest::MD5;
use Log::Log4perl;
use Test::AutoBuild::Lib;
use File::Spec::Functions qw(catfile tmpdir catdir);

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();

    my $destdir = $self->option("iso-dest-dir");
    if (! -e $destdir) {
	mkdir $destdir
	    or die "cannot create dir $destdir: $!";
    }

    my $scratchdir = $self->option("scratch-dir");
    $scratchdir = tmpdir() unless defined $scratchdir;

    my %images = %{$self->option("images")};
    foreach my $key (sort keys %images) {
	my $image = $images{$key};

	my @cd_modules = @{$image->{'modules'}};
	@cd_modules = $runtime->modules
	    unless @cd_modules;

	foreach my $mod (@cd_modules) {
	    my $module = $runtime->module($mod);
	    die "cannot find module $mod" unless defined $module;
	    if ($module->build_status() ne "success" &&
		$module->build_status() ne "cached") {
		$self->fail("cannot create ISO because module " . $module->name . " failed");
		return;
	    }
	}
    }

    my @isos;

    foreach my $key (sort keys %images) {
	my $image = $images{$key};
	my $name = $image->{name};

	my $vroot = catdir($scratchdir, "$$-$name");
	mkdir $vroot
	    or die "cannot create virtual root directory $vroot: $!";

	my @cd_package_types = @{$image->{'package-types'}};
	my @cd_modules = @{$image->{'modules'}};

	@cd_package_types = $runtime->package_types
	    unless @cd_package_types;
	@cd_modules = $runtime->modules
	    unless @cd_modules;

	my %types;
	foreach my $type (@cd_package_types) {
	    my $dir = catdir($vroot, $type);
	    mkdir $dir
		or die "cannot create dir $dir: $!";
	    $types{$type} = 1;
	}


	foreach my $mod (@cd_modules) {
	    my $module = $runtime->module($mod);
	    die "cannot find module $mod" unless defined $module;
	    $log->info("Process ISO $mod");

	    my $packages = $module->packages;

	    foreach my $filename (keys %{$packages}) {
		my $pkg = $packages->{$filename};

		if (exists $types{$pkg->type->name}) {
		    (my $file = $filename) =~ s,^.*/,,;
		    my $dst = catfile($vroot, $pkg->type->name, $file);

		    $log->info("Copy $filename -> $dst");
		    next if $file =~ /.md5$/;

		    $self->_copy_file($filename, $dst);
		    $self->_create_file($pkg->md5sum, $dst . ".md5");
		} else {
		    $log->info("Skip $filename because " . $pkg->type->name . " is not wanted");
		}
	    }
	}


	my $isofile = catfile($destdir, $name);

	my $label = $image->{"label"} || "Untitled-Auto-Build-CD";

	my $log = `mkisofs -A '$label' -J --hide-joliet '*.md5' -r -o $isofile $vroot 2>&1`;
	$self->log($log);

	# cleanup
	foreach my $mod (@cd_modules) {
	    my $module = $runtime->module($mod);
	    my $packages = $module->packages;
	    foreach my $filename (keys %{$packages}) {
		my $pkg = $packages->{$filename};

		if (exists $types{$pkg->type->name}) {
		    (my $file = $filename) =~ s,^.*/,,;
		    my $dst = catfile($vroot, $pkg->type->name, $file);

		    next if $file =~ /.md5$/;

		    unlink $dst
			or die "cannot delete $dst: $!";
		    unlink "$dst.md5"
			or die "cannot delete $dst.md5: $!";
		}
	    }
	}
	foreach my $type (@cd_package_types) {
	    my $dir = catdir($vroot,$type);
	    rmdir $dir
		or die "cannot delete dir $dir: $!";
	}
	rmdir $vroot
	    or die "cannot delete $vroot: $!";


	my $md5 = Digest::MD5->new();
	open FILE, $isofile or die "cannot open $isofile: $!";
	$md5->addfile(\*FILE);

	my @stat = stat $isofile;

	push @isos, {
	    label => $label,
	    filename => $name,
	    md5sum => $md5->hexdigest,
	    size => Test::AutoBuild::Lib::pretty_size($stat[7])
	    };

	$runtime->attribute("isos", \@isos);
    }

}

sub _copy_file {
    my $self = shift;
    my $src = shift;
    my $dst = shift;

    open SRC, "<$src"
	or die "cannot read $src: $!";
    open DST, ">$dst"
	or die "cannot create $dst: $!";

    # Memory is practically free!
    # ...but we should fix this to be efficient.
    local $/ = undef;
    print DST <SRC>;

    close SRC;
    close DST;

}

sub _create_file {
    my $self = shift;
    my $data = shift;
    my $dst = shift;

    open DST, ">$dst"
	or die "cannot create $dst: $!";

    print DST $data;

    close DST;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2004 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>

=cut
