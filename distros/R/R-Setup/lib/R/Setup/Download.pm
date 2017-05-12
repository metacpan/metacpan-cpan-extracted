# perl program
# requires: R instance with Internet connection
# accept: a list of package ids
# processes: 
# 	- get index from CRAN and creates hash of id:tar
# 	- prepares the list of tars
# 	- downloads all tars if --download
#
# Copyright (C) 2015, Snehasis Sinha <snehasis@cpan.org>
#

package R::Setup::Download;

use 5.010001;
use strict;
use warnings;
use LWP::UserAgent;

our @ISA = qw();
our $VERSION = '0.01';

BEGIN { $| = 1 } # flush STDOUT buffer

# package methods

sub new {
	my $class = shift;
	my %params = @_;
	my $self = {
		_url      => $params{'urlbase'} || 'http://cran.r-project.org/src',
		_packages => $params{'packages'},  # list ref of packages
		_tars     => undef, # list reference of tarballs
		_index    => undef, # \%hash_of id:tar extracted from $param{urlbase}
		_lwp      => undef,
		_verbose  => $params{'verbose'} || 1, # default:yes
	};
	bless $self, $class;
	return $self;
}

# returns package id, accepts tarball
# package=>pkg_ver.tar.gz
sub p_get_package_id {   
	my ($self, $pkg) = (@_);
	$pkg =~ s/\_.*//;
	return $pkg;
}

# returns tarball, accepts package name
# name=>pkgname
sub p_lookup {
	my ($self, $id) = (@_);
	return $self->{'_index'}->{$id};
}

# pulls down list of all packages available in CRAN
# loads a hash with package id : tarball
sub p_wget_index {
	my ($self) = (@_);
	
	# get baseurl index
	$self->pr ( message=>'index' );
	$self->p_wget (type => 'index') ? $self->pr (state=>'done') : $self->pr (state=>'failed');
}

sub p_create_index {
	my ($self) = (@_);
	my $findex = 'index.html';
	
	if ( -f $findex ) {
		open INDEX, "<".$findex or die $!;
		while ( <INDEX> ) {
			chomp;
			# grep "\.tar\.gz" index.html |sed 's|.*href="||g'|sed 's|\">.*||g';
			next unless m/\.tar\.gz/; 
			$_ =~ s/.*href="//g;
			$_ =~ s/\"\>.*//g;

			# store in hash
			$self->{'_index'}->{ $self->p_get_package_id ($_) } = $_;
		}
		#unlink $findex;
		close INDEX;
	}
}

# wget implementation
# package=>pkg_ver.tar.gz or R-3.1.2.tar.gz
# type=>package index source
sub p_wget {
	my ($self, %args) = (@_);
	my $res;
	my $filename;
	my $uri = $self->{'_url'};

	if ( $args{'type'} =~ /source/ ) {
		my $dir = (split /\./, $args{'package'})[0];
		$uri .= '/base/'.$dir.'/'.$args{'package'};
	   	$args{'filename'} = $args{'package'};
	} elsif ( $args{'type'} =~ /index/ ) {
		$uri .= '/contrib/';
	   	$args{'filename'} = 'index.html';
	} else {
		$uri .= "/contrib/".$args{'package'};
	   	$args{'filename'} = $args{'package'};
	}

	$res = $self->{'_lwp'}->get ( $uri );

	if ( $res->is_success ) {
		open TARGZ, '>'.$args{'filename'} or die $!;
		print TARGZ $res->decoded_content;
		close TARGZ;
	}
	return $res->is_success;
}

sub p_connect {
	my ($self) = (@_);
	
	unless (defined $self->{'_lwp'}) {
		$self->{'_lwp'} = LWP::UserAgent->new; 
		$self->{'_lwp'}->timeout(10);
		print "user agent connected\n" if $self->{'_verbose'};
	}
}

# converts package list to tarball list
sub p_create_list {
	my ($self) = (@_);
	my $tar;

	foreach my $id ( @{$self->{'_packages'}} ) {
		$tar = $self->p_lookup ( $id );
		push ( @{$self->{'_tars'}}, $tar ) if defined $tar;
	}
}

sub prepare {
	my ($self, %args) = (@_);

	$self->p_connect;
	$self->p_wget_index if $args{refresh};
	$self->p_create_index;

	$self->p_create_list;
}

sub dumplist {
	my ($self) = (@_);
	return $self->{'_tars'};
}

sub pr {
	my ($self, %args) = (@_);
	return unless $self->{'_verbose'};
	print sprintf "%-40s ... ", $args{message} if defined $args{message};
	print sprintf " _%s_\n", $args{state} if defined $args{state};
}

sub download_binary {
	my ($self, %args) = (@_);
	my $ret;
	
	if ( -f $args{'source'} ) {
		$self->pr ( message=>$args{'source'}, state=>'here' );
		return 1;
	}

	$self->p_connect;
	$self->pr ( message=>$args{'source'} );
	$self->p_wget(type => 'source', package => $args{'source'}) 
		? $self->pr ( state=>'done' )
		: $self->pr ( state=>'failed' );
	
	return 0;
}


sub download {
	my ($self) = (@_);

	foreach my $pkg ( @{$self->{'_tars'}} ) {
		if ( -f $pkg ) { 
			$self->pr ( message=>$pkg, state=>'here' );
			next; 
		}
		$self->pr ( message=>$pkg );
		$self->p_wget(type => 'package', package => $pkg) 
			? $self->pr ( state=>'done' )
			: $self->pr ( state=>'failed' )
	}
}

1;

__END__

=head1 NAME

R::Setup::Download - Perl extension for R package download for offline installation

=head1 SYNOPSIS

  # source download
  my $d = R::Setup::Download->new;
  $d->download_binary (source=>'R-3.1.2.tar.gz');

  # packages download
  my @list = qw/rshape2 ggplot2/;

  my $d = R::Setup::Download->new ( packages=>\@list, [ usrbase=>$cranurl, ] verbose=>1 );
  $d->prepare ( [ refresh=>1 ] );

  my $tarlistref = $d->dumplist;
  $d->download if defined $download;


=head1 DESCRIPTION

R::Setup::Download resolves all package list with tar files and download
from CRAN repo for further offline installation in an Internet denied
cluster running Hadoop.

=head1 SEE ALSO

R::Setup
R::Setup::Resolve
R::Setup::Install
R::Setup::Bootstrap


=head1 AUTHOR

Snehasis Sinha, <lt>snehasis@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
