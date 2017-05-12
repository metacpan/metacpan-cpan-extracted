package Postfix::Mailgroups::Expand;
{
  $Postfix::Mailgroups::Expand::VERSION = '1.131020';
}
# ABSTRACT: Expand postfix mailgroups.

use 5.006;
use strict;
use warnings;

use File::Slurp;
use List::MoreUtils qw(uniq);
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

our @ISA = qw(Exporter AutoLoader);
our @EXPORT = qw();


sub new {
	my $class = shift;
  my %passed_parms = @_;
	my $self  = {};
	$self->{exclude_addresses} = $passed_parms{'exclude_addresses'} || '^backup' ;
	$self->{exclude_groups} = $passed_parms{'exclude_groups'} || '^owner' ;
	bless($self, $class);
	$self->{ALIASES} = $self->_get_alias_maps($passed_parms{'aliases'});
	$self->{GROUPS} = $self->_get_virtual_alias_maps($passed_parms{'groups'});
	return $self;
}

sub write2dir{
	my ($self,$dir) = @_;

	my $groups = $self->{GROUPS};
	my $alias_map = $self->{ALIASES};

	if( ! -d $dir){
		mkdir($dir);
	}

	foreach my $k (keys %$groups) {
		my @adr = $self->_get_addresses($alias_map->{$groups->{$k}});
		write_file("$dir/$k",join("\n",@adr)."\n");
	}
}

sub _get_virtual_alias_maps{
	my ($self,$filename) = @_;
	my $navrat;
	my @aliases = read_file($filename, chomp=>1);
	foreach my $line(@aliases){
  	if ($line =~ /^[^#]+.*@/) {
   	 my ($adr, $alias) = split(/\s/,$line);
		 $navrat->{$adr}=$alias;
		}
	}
	return $navrat;
}

sub _get_alias_maps{
	my ($self,$filename) = @_;
	my $navrat;
	my @aliases = read_file($filename, chomp=>1);
	foreach my $line(@aliases){
  	if ($line =~ /^[^#]+:include:/ and $line !~ /$self->{exclude_groups}/) {
   	 my ($adr, $alias) = split(/:.*:include:/,$line);
		 $navrat->{$adr}=$alias;
		}
	}
	return $navrat;
}

sub _get_addresses{
	my ($self,$filename) = @_;
	my @navrat;
	my @addresses = read_file($filename, chomp=>1);
	my @foo = map /$self->{exclude_addresses}/ ? () : $_, @addresses;
	foreach my $adr(@foo){
		if($self->{GROUPS}{$adr}){
			push(@navrat,$self->_get_addresses($self->{ALIASES}{$self->{GROUPS}{$adr}}));
		}else{
			push(@navrat,$adr);
		}
	}
	return sort uniq(@navrat);
}

1;

=pod

=head1 NAME

Postfix::Mailgroups::Expand - Expand postfix mailgroups.

=head1 VERSION

version 1.131020

=head1 SYNOPSIS

	use Postfix::Mailgroups::Expand;
	
	my $groups = new Postfix::Mailgroups::Expand('groups'=>'/etc/postfix/virtual.groups','aliases'=>'/etc/postfix/aliases');

	$groups->write2dir('dirname');

=head1 METHODS

=head2 my $groups = new Postfix::Mailgroups::Expand('groups'=>'/etc/postfix/virtual.groups','aliases'=>'/etc/postfix/aliases');

Create new object instance.

=head2 $groups->write2dir($outdir);

Write expanded groups to $outdir.

=head2 $groups->_get_virtual_alias_maps($alias_file);

Return virtual aliases maps.

=head2 $groups->_get_alias_maps($alias_file);

Return aliases maps.

=head2 $groups->_get_addresses($filename);

Read addresses from file.

=head1 SEE ALSO

https://metacpan.org/module/Mail::ExpandAliases

=head1 AUTHOR

Petr Kletecka <pek@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Petr Kletecka.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

1;
