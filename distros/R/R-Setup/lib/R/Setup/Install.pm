# perl program
# R package installation routine
# it requires 
#   inputs: list of all package tars
#   source: directory where package_version.tar.gz are, default=$PWD
#
# Copyright (C) 2015, Snehasis Sinha <snehasis@cpan.org>
#

package R::Setup::Install;

use 5.010001;
use strict;
use warnings;

our @ISA = qw();
our $VERSION = '0.01';


# package methods

sub new {
	my $class = shift;
	my %params = (@_);
	my $self = {
		_install => 'R CMD INSTALL',            # R install command, R should be in $PATH
		_rbin    => 'R -q --no-save',           # R query command
		_file    => $params{'file'} || undef,   # filename containing package list in order
		_list    => $params{'list'} || undef,   # listref containing package list in order
		_has     => undef,                      # listref of already installed packages
		_verbose => $params{'verbose'} || 1,    # default: yes
	};
	bless $self, $class;
	return $self;
}

# extract from package list (persistency)
sub p_read_from_file {
	my ($self) = (@_);
	return unless (defined $self->{'file'} && -f $self->{'file'} ); 
	
	open FILE, "<".$self->{'file'} or die $!;
	my @list = <FILE>;
	close FILE;
	chomp @list;

	$self->{'_list'} = \@list;
}

# gets package id
sub p_get_package_id {   
	my ($self, $pkgname) = (@_);
	$pkgname =~ s/\_.*//;
	return $pkgname;
}

# gets installed packages
sub p_installed_packages {
	my ($self) = (@_);
	my $rcmd = 'installed.packages\(.Library\)';

	my @out = qx(echo $rcmd | $self->{'_rbin'});
	chomp @out;
	@out = grep(/^[a-zA-Z]+/, @out);

	my %pkgs;
	foreach (@out) { 
		s/\s+.*//g;
		$pkgs{$_}=1;
	}

	$self->{'_has'} = \%pkgs;
}

# actually install a package
sub p_install {
	my ($self, %args) = (@_);
	my $ret;
	my $cmd = $self->{'_install'}.' '.$args{'package'}.' 2>&1';

	print "executing ".$cmd."\n" if defined $self->{'_verbose'};
	$ret = qx($cmd);
}

sub pr {
	my ($self, %args) = (@_);
	print sprintf "%-40s _%s_\n", $args{'package'}, $args{'state'} if $self->{'_verbose'};
}

sub install {
	my ($self) = (@_);

	# read from file, if any
	$self->p_read_from_file;

	# populate hash of installed packages
	$self->p_installed_packages;

	# actually install
	$self->p_install_packages;
}

# install packages from the given list
sub p_install_packages {
	my ($self) = (@_);
	my $p;

	foreach my $pkg ( @{$self->{'_list'}} ) {
		# get the package id
		$p = $self->p_get_package_id ( $pkg );

		# check if already installed
		if (defined $self->{'_has'}->{$p}) {
			$self->pr (package=>$p, state=>'skipped');
			next;
		}

		# check if the tarball is available
		unless ( -f $pkg ) {
			$self->pr (package=>$p, state=>'missing');
			next;
		}

		# now install
		$self->p_install (package=>$pkg);
		$self->pr (package=>$p, state=>'done');
	}
}

1;

__END__

=head1 NAME

R::Setup::Install - Perl extension for installing R packages offline

=head1 SYNOPSIS

  use R::Setup::Install;

  my $inst = R::Setup::Install->new ( file=>$filename, verbose=>1 );

  OR $inst = R::Setup::Install->new ( list=>\@list, verbose=>1 );

  $inst->install;

  exit (0);


=head1 DESCRIPTION

R::Setup::Install installs R packages offline in an Internet denied
cluster running Hadoop.


=head1 SEE ALSO

R::Setup
R::Setup::Resolve
R::Setup::Download
R::Setup::Bootstrap


=head1 AUTHOR

Snehasis Sinha, <lt>snehasis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

