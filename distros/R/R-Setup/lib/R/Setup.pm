# perl program for R installation
# 
# Copyright (C) 2015, Snehasis Sinha <snehasis@cpan.org>
#

package R::Setup;

use 5.010001;
use strict;
use warnings;

use R::Setup::Bootstrap;
use R::Setup::Resolve;
use R::Setup::Download;
use R::Setup::Install;
use R::Setup::Local;

our @ISA = qw();
our $VERSION = '0.01';


# package methods

sub new {
	my $class = shift;
	my %params = @_;
	my $self = {
		bootstrap => $params{'bootstrap'} || undef,
		resolve   => $params{'resolve'}   || undef,
		download  => $params{'download'}  || undef,
		install   => $params{'install'}   || undef,
		asklist   => $params{'packages'},
		rsource   => $params{'rsource'} || 'R-3.1.2.tar.gz',
		urlbase   => $params{'urlbase'}, # only required for local
		deplist   => undef,
		tarlist   => undef,
		# listfile  => $params{'depslistfile'}  || 'package.list',
		verbose   => $params{'verbose'} || 1, # default:yes
	};
	bless $self, $class;
	return $self;
}

sub download_source {
	my ($self, %args) = (@_);

	$args{'source'} = $self->{'rsource'} unless defined $args{'source'};
	$self->{'download'} = R::Setup::Download->new unless defined $self->{'download'};
	$self->{'download'}->download_binary (source=>$args{'source'});
}

sub set_package_list {
	my ($self) = (@_);

	# resolve dependencies
	unless (defined $self->{'resolve'}) {
		unless (defined $self->{'asklist'}) {
			print "no package list supplied. exit!\n" if $self->{'verbose'};
		}
		
		$self->{'resolve'} = R::Setup::Resolve->new(packages=>$self->{'asklist'});
	}
	$self->{'deplist'} = $self->{'resolve'}->resolve;
	$self->save ( whichlist=>'deplist' );
}

sub download_packages {
	my ($self) = (@_);

	# read from default file for consistency
	$self->read ( whichlist=>'deplist' ) unless defined $self->{'deplist'};

	# download deps package in this session
	$self->{'download'} = R::Setup::Download->new ( packages=>$self->{'deplist'} ); 
	
	$self->{'download'}->prepare ( refresh=>1 );
	$self->{'tarlist'} = $self->{'download'}->dumplist;
	# store in file for offline installation
	$self->save ( whichlist=>'tarlist' );
	
	# download packages
	$self->{'download'}->download;
}

sub read {
	my ($self, %args) = (@_);
	my @t;

	open FILE, '<'.$args{'whichlist'} or die $!;
	@t = <FILE>;
	close FILE;
	chomp @t;

	$self->{$args{'whichlist'}} = \@t;
	print scalar @t." records loaded from ".$args{'whichlist'}."\n" if $self->{'verbose'};
}

sub save {
	my ($self, %args) = (@_);

	open FILE, '>'.$args{'whichlist'} or die $!;
	foreach ( @{$self->{$args{'whichlist'}}} ) {
		print FILE $_."\n";
	}
	close FILE;
}

sub build_from_source {
	my ($self) = (@_);

	$self->{'bootstrap'} = R::Setup::Bootstrap->new unless defined $self->{'bootstrap'};
	$self->{'bootstrap'}->build;
}

sub install {
	my ($self) = (@_);

	$self->{'bootstrap'} = R::Setup::Bootstrap->new unless defined $self->{'bootstrap'};

	# install R with sudo
	$self->{'bootstrap'}->install;
}

sub install_packages {
	my ($self) = (@_);

	# read from default file for consistency
	$self->read ( whichlist=>'tarlist' ) unless defined $self->{'tarlist'};

	$self->{'install'} = R::Setup::Install->new (list=>$self->{'tarlist'})
		unless defined $self->{'install'};

	# install packages with sudo
	$self->{'install'}->install;
}

sub download_local {
	my ($self) = (@_);

	my $ldw = R::Setup::Local->new ( urlbase=>$self->{'urlbase'} );
	$ldw->download_local;
}

1;
__END__

=head1 NAME

R::Setup - Perl extension for R installation

=head1 SYNOPSIS

use R::Setup;

my $setup = R::Setup->new ( urlbase=>'http://host/dir' );
   $setup->download_local;
   $setup->build_from_source;
   $setup->install;
   $setup->install_packages;

my $setup = R::Setup->new;
   $setup->download_source;
   $setup->build_from_source;

my $setup = R::Setup->new;
   $setup->install;

my @list = qw/caret ggplot2/; my $setup;
   $setup = R::Setup->new (packages=>\@list) 
   $setup->set_package_list;
   $setup->download_packages;

my $setup = R::Setup->new;
   $setup->install_packages;

=head1 DESCRIPTION

R::Setup installs R along with its pre-selected packages 
in an Internet denied cluster running Hadoop. Hadoop clusters
typically runs in Internet denied environment for security.
It addresses R installation in such clusters.

Internet enabled (one time):

Download downloads R source. Move the source to Hadoop cluster.

Resolve resolves R package dependencies and creates a list of 
dependent packages using a running R instance and connected to 
the Internet. This dumps a list of packages in the order of 
dependency.

Download downloads the R packages with dependencies from CRAN repo.
Move the package list and R package tars to Hadoop cluster.

Internet denied:

It has Bootstrap component that installs R binary from source
offline. R source tar should already been downloaded and 
available in local directory.

Build can run on one node in cluster, and then rsync to
other nodes before running install, assuming all nodes
in a cluster as identical to one another as building on
each node is not required!

Install installs R packages as in the package list in order on 
the Hadoop cluster with no Internet connectivity.


=head1 SEE ALSO

R::Setup::Bootstrap
R::Setup::Resolve
R::Setup::Download
R::Setup::Install
R::Setup::Local


=head1 AUTHOR

Snehasis Sinha, <lt>snehasis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
