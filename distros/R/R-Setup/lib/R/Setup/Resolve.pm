# perl program
# R instance with Internet connection
# accept: a list of package ids
# processes: 
# 	- reads package todo list (package id)
#	- gets 'depends' and 'imports' list for each package id
#	- constructs a linear list in order of deps
#
# Copyright (C) 2015, Snehasis Sinha <snehasis@cpan.org>
#

package R::Setup::Resolve;

use 5.010001;
use strict;
use warnings;
use IPC::Open3;

our @ISA = qw();
our $VERSION = '0.01';


# Preloaded methods go here.
BEGIN { $| = 1 }

sub new {
	my $class = shift;
	my %params = @_;
	my $self = {
		_rbin    => 'R -q --no-save',    # R command, should be in $PATH
		_packages=> $params{'packages'}, # array ref of packages wishlist 
		_final   => undef,               # final list is stored in order
		_tree    => undef,               # tree of packages with children as dependencies
		_dhash   => undef,               # dumb hash to generate unique list
		_verbose => $params{'verbose'} || 1, # default: yes
	};
	bless $self, $class;
	return $self;
}

# get dep list for a package
# returns list, accepts package id
# package=>pkgname
sub p_r_program {
	my ($self, %arg) = (@_);
	my $findr = qq|
options(repos=structure(c(CRAN="http://cran.r-project.org/")))

getPackages <- function(packs){
  packages <- unlist(
    tools::package_dependencies(
      packs,
      available.packages(),
      which=c("Depends", "Imports"),
      recursive=TRUE
    )
  )
  packages <- union(packs, packages)
  packages
}

pkgs <- getPackages (c("$arg{name}"))
pkgs
|;
	return $findr;
}

sub get_package_deps {
	my ($self, %arg) = (@_);
	my @list=();
	my @pkgs=();
	my $i=0;
	my $findr = $self->p_r_program ( name => $arg{name} );
	my $output="";

	my $pid = open3 ( \*INPUT, \*OUTPUT, \*ERROR, $self->{'_rbin'} ) or die $!;
	print INPUT $findr;
	close INPUT;

	while ( <OUTPUT> ) {
		next if m/^\>/;
		next if m/^\+/;
		chomp;
		$output.=" ".$_;
	}
	close OUTPUT;
	close ERROR;

	@pkgs = split /\s+/, $output;

	foreach (@pkgs) { 
		next if m/^$/;
		next if m/^\[/;
		$_ =~ s/\"//g;

		if ( $i eq 0 ) {
			$i++;
			next;
		}
		push (@list, $_);
	}
	print join ' ', @list, "\n";
	return \@list;
}

sub p_create_tree {
	my ($self, %args) = (@_);
	my $list;

	unless (exists $self->{'_tree'}->{ $args{name} }) {
		print "resolving deps for ".$args{name}." ...\n" if $self->{'_verbose'};
		$self->{'_tree'}->{ $args{name} } = $self->get_package_deps ( name => $args{name} );
	}

	foreach my $p ( @{$self->{'_tree'}->{ $args{name} } } ) {
		$self->p_create_tree ( name => $p );
	}
}

sub p_create_trees {
	# merge all lists
	my ($self) = (@_);

	foreach my $p ( @{$self->{'_packages'}} ) {
		$self->p_create_tree ( name => $p );
	}
}

sub p_set_node {
	my ($self, $node) = (@_);

	return unless exists $self->{'_tree'}->{$node};
	return if     exists $self->{'_dhash'}->{$node};

	foreach my $e ( @{$self->{'_tree'}->{$node}} ) {
		$self->p_set_node ( $e );
	}

	push ( @{$self->{'_final'}}, $node );
	$self->{'_dhash'}->{$node} = 1;
}

sub p_set_nodes {
	my ($self) = (@_);
	
	foreach ( @{$self->{'_packages'}} ) {
		$self->p_set_node ( $_ );
	}
}
	
sub resolve {
	my ($self) = (@_);

	$self->p_create_trees;
	$self->p_set_nodes;

	return $self->{'_final'};
}

1;

__END__

=head1 NAME

R::Setup::Resolve - Perl extension for resolving R package deps

=head1 SYNOPSIS

  use R::Setup::Resolve;

  my @asks = qw/reshape2 ggplot2 caret/;

  my $p = R::Setup::Resolve->new ( packages=>\@asks, verbose=>1 );

  my $list = $p->resolve;
  foreach ( @$list ) { print $_."\n"; }

  exit (0);
 

=head1 DESCRIPTION

R::Setup::Resolve resolves R package dependency for a list 
of given packages and produces a list for download and installation
in an Internet denied cluster running Hadoop.

=head1 SEE ALSO

R::Setup
R::Setup::Download
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
