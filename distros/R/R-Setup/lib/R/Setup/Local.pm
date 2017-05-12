# perl program
# requires: R instance with local repo
# pulls: a list of package ids and the package tars
# isntalls: R binary, R packages on local machine
#
# Copyright (C) 2015, Snehasis Sinha <snehasis@cpan.org>
#

package R::Setup::Local;

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
		_url      => $params{'urlbase'}, # local url
		_pkglist  => $params{'packagelist'} || 'tarlist', #list of tars 
		_binary   => $params{'binary'} || 'R-3.1.2.tar.gz',
		_lwp      => undef,
		_verbose  => $params{'verbose'} || 1, # default:yes
	};
	bless $self, $class;
	return $self;
}

# wget implementation
# package=>pkg_ver.tar.gz or R-3.1.2.tar.gz
# type=>package index source
sub p_wget {
	my ($self, %args) = (@_);
	my $res;
	my $uri = $self->{'_url'};

	$uri .= "/".$args{'package'};
	$res = $self->{'_lwp'}->get ( $uri );

	if ( $res->is_success ) {
		open TARGZ, '>'.$args{'package'} or die $!;
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

sub pr {
	my ($self, %args) = (@_);
	return unless $self->{'_verbose'};
	print sprintf "%-40s ... ", $args{message} if defined $args{message};
	print sprintf " _%s_\n", $args{state} if defined $args{state};
}

sub download_local {
	my ($self) = (@_);

	# connect
	$self->p_connect;

	# download binary
	if ( -f $self->{'_binary'} ) {
		$self->pr ( message=>$self->{'_binary'}, state=>'here' );
	} else {
		$self->pr ( message=>$self->{'_binary'} );
		$self->p_wget( package => $self->{'_binary'} ) 
			? $self->pr ( state=>'done' )
			: $self->pr ( state=>'failed' )
	}

	# download package list
	unless ( -f $self->{'_pkglist'} ) {
		$self->pr ( message=>$self->{'_pkglist'} );
		$self->p_wget( package => $self->{'_pkglist'} ) 
			? $self->pr ( state=>'done' )
			: $self->pr ( state=>'failed' )
	}
		
	# download packages
	open PACKAGES, '<'.$self->{'_pkglist'} or die $!;
	while ( <PACKAGES> ) {
		chomp;
		if ( -f $_ ) { 
			$self->pr ( message=>$_, state=>'here' );
			next; 
		}
		$self->pr ( message=>$_ );
		$self->p_wget( package => $_ ) 
			? $self->pr ( state=>'done' )
			: $self->pr ( state=>'failed' )
	}
	close PACKAGES;
}

1;

__END__

=head1 NAME

R::Setup::Local - Perl extension for R package download from local repo

=head1 SYNOPSIS

  # download locally
  my $d = R::Setup::Local->new;

  my $d = R::Setup::Local->new ( binary=>'R-3.1.2.tar.gz' );

  my $d = R::Setup::Local->new ( binary=>'R-3.1.2.tar.gz', packagelist=>'tarlist' );

  $d->download_local;


=head1 DESCRIPTION

R::Setup::Download resolves all package list with tar files and download
from CRAN repo for further offline installation in an Internet denied
cluster running Hadoop.

=head1 SEE ALSO

R::Setup
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
