# perl package
# R binary installation routine
# it assumes: R-version.tar.gz is available in local directory
# it does:    build, test and install
# 
# Copyright (C) 2015, Snehasis Sinha <snehasis@cpan.org>
#

package R::Setup::Bootstrap;

use 5.010001;
use strict;
use warnings;
use POSIX;

our @ISA = qw();

our $VERSION = '0.01';


# Preloaded methods go here.
BEGIN { $| = 1 } # flush buffer

sub new {
	my $class = shift;
	my %params = (@_);
	my $self = {
		_tarball => $params{'tarball'} || 'R-3.1.2.tar.gz',
		_extract => sub { $a=qx(which tar); chomp $a; return $a.' -xzf'; }->() || undef, 
		_builddir=> undef,
		_config  => './configure --prefix=/usr --with-x=no --enable-R-shlib',
		_make    => sub { $a=qx(which make); chomp $a; return $a; }->() || undef, 
		_rtest   => 'R -q --no-save',           # R query command
		_verbose => (defined $params{'verbose'} ? $params{'verbose'} : 1 ), # default: yes
	};
	bless $self, $class;
	return $self;
}

sub p_pwd {
	my ($self, $root) = (@_);

	return getcwd();
}

sub p_delete {
	my ($self, $root) = (@_);

	unless ( -d $root ) {
		unlink $root;
		#print "rm ".$root."\n" if $self->{'_verbose'};
		return;
	}

	opendir DIR, $root or die $!;
	my @entries = readdir DIR;
	chomp @entries;
	closedir DIR;
	@entries = grep { !/^\.{1,2}$/ } @entries;

	foreach ( @entries ) {
		$self->p_delete ( $root.'/'.$_ );
	}

	rmdir $root;
	#print $root." removed with content\n" if $self->{'_verbose'};
}

sub p_builddir {
	my ($self) = (@_);
	my $dir = $self->{'_tarball'};
	$dir =~ s/\.tar\.gz//g;

	$self->{'_builddir'} =  $self->p_pwd.'/'.$dir;
}
	
sub p_exec {
	my ($self, $cmd) = (@_);
	my $i = 0;

	open CMD, $cmd.' 2>&1 |' or die $!;
	while ( <CMD> ) { 
		if ( $self->{'_verbose'} gt 1 ) { print $_; } 
		else { print '.' unless ($i++ % 20); }
	}
	close CMD;
	print "\n";
}
	
# extract from package list (persistency)
sub p_extract {
	my ($self) = (@_);
	my $builddir;

	unless ( -f $self->{'_tarball'} ) {
		print $self->{'_tarball'}." is not available!\n";
		exit (1);
	}

	$builddir = $self->{'_builddir'};

	# check if directory exists
	if ( -d $self->{'_builddir'} ) { # remove it
		print $self->{'_builddir'}." removing...\n" if $self->{'_verbose'};
		$self->p_delete ( $self->{'_builddir'} );
	}

	# extract
	my $cmd = $self->{'_extract'}.' '.$self->{'_tarball'};
	print $self->{'_tarball'}." extracting ...\n" if $self->{'_verbose'};
	qx($cmd);
}

sub p_configure {
	my ($self) = (@_);

	unless ( defined $self->{'_config'} ) {
		print "problem configuring!\n" if $self->{'_verbose'};
		exit (1);
	}
	print "configuring " if $self->{'_verbose'};
	$self->p_exec ( $self->{'_config'} );
}

sub p_make {
	my ($self) = (@_);

	unless ( defined $self->{'_make'} ) {
		print "problem building!\n" if $self->{'_verbose'};
		exit (1);
	}
	print "building " if $self->{'_verbose'};
	$self->p_exec ( $self->{'_make'} );
}

sub p_uninstall {
	my ($self) = (@_);

	unless ( defined $self->{'_make'} ) {
		print "problem uninstalling!\n" if $self->{'_verbose'};
		exit (1);
	}
	print "uninstalling " if $self->{'_verbose'};
	$self->p_exec ( $self->{'_make'}.' uninstall' );
}

sub p_install {
	my ($self) = (@_);

	unless ( defined $self->{'_make'} ) {
		print "problem installing!\n" if $self->{'_verbose'};
		exit (1);
	}
	print "installing " if $self->{'_verbose'};
	$self->p_exec ( $self->{'_make'}.' install' );
}

sub p_chdir {
	my ($self) = (@_);
	my $dir = $self->{'_builddir'};
	chdir $dir if -d $dir;
}

sub p_check_R {
	my ($self) = (@_);
	my $cmd = 'R';
	my $out = qx(whereis $cmd);

	$out =~ s/$cmd://g;
	$out =~ s/^\s+|\s+$//g;
	$out =~ s/\/usr\/lib64\/R//g;

	if($out ne "") {
		return 0;
	}
	return 1;
}
	
sub build {
	my ($self) = (@_);

	$self->p_builddir;
	$self->p_extract;
	$self->p_chdir;

	$self->p_configure;
	$self->p_make;
}

# gets package id
sub install {
	my ($self) = (@_);

	unless ( $self->p_check_R ) {
		print "R is already available\n" if $self->{'_verbose'};
		exit (1);
	}
		
	if ( getuid() ne 0 ) {
		print "requires root (sudo) access\n" if $self->{'_verbose'};
		exit (1);
	}

	print "installing \n";
	$self->p_builddir;
	$self->p_chdir;

	$self->p_install;
}

sub uninstall {
	my ($self) = (@_);

	if ( $self->p_check_R ) {
		print "R is missing\n" if $self->{'_verbose'};
		exit (1);
	}

	if ( getuid() ne 0 ) {
		print "requires root (sudo) access\n" if $self->{'_verbose'};
		exit (1);
	}

	# clean up packages first
	# todo
	
	print "removing \n";
	$self->p_builddir;
	$self->p_chdir;

	# uninstall binary
	$self->p_uninstall;
}
		
1;

__END__

=head1 NAME

R::Setup::Bootstrap - Perl extension for R bootstraping (from source)

=head1 SYNOPSIS

  use R::Setup::Bootstrap;

  use Getopt::Long;

  my %opts;
  GetOptions (\%opts, 'build', 'install');

  #my $b = R::Setup::Bootstrap->new ( tarball=>'R-3.1.2.tar.gz' );
  my $b = R::Setup::Bootstrap->new;

  $b->build if defined $opts{build};
  $b->install if defined $opts{install};

  exit (0);


=head1 DESCRIPTION

Documentation for R::Setup::Bootstrap, created by h2xs. 

This installs R from tarball on a internet denied cluster 
running Hadoop.



=head1 SEE ALSO

R::Setup
R::Setup::Resolve
R::Setup::Download
R::Setup::Install


=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

