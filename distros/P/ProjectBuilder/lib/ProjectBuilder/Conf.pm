#!/usr/bin/perl -w
#
# ProjectBuilder Conf module
# Conf files subroutines brought by the the Project-Builder project
# which can be easily used by wahtever perl project
#
# Copyright B. Cornec 2007-2016
# Eric Anderson's changes are (c) Copyright 2012 Hewlett Packard
# Provided under the GPL v2
#
# $Id$
#

package ProjectBuilder::Conf;

use strict;
use Carp 'confess';
use Data::Dumper;
use ProjectBuilder::Base;
use ProjectBuilder::Version;

# Inherit from the "Exporter" module which handles exporting functions.
 
use vars qw($VERSION $REVISION @ISA @EXPORT);
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
 
our @ISA = qw(Exporter);
our @EXPORT = qw(pb_conf_init pb_conf_add pb_conf_read pb_conf_read_if pb_conf_write pb_conf_get pb_conf_get_if pb_conf_print pb_conf_get_all pb_conf_get_hash pb_conf_cache);
($VERSION,$REVISION) = pb_version_init();

# Global hash of conf files
# Key is the conf file name
# Value is its rank
my %pbconffiles;

# Global hash of conf file content
# Key is the config keyword
# Value is a hash whose key depends on the nature of the config keyword as documented
# and value is the confguration value
# We consider that values can not change during the life of pb
my $h = ();

=pod

=head1 NAME

ProjectBuilder::Conf, part of the project-builder.org - module dealing with configuration files

=head1 DESCRIPTION

This modules provides functions dealing with configuration files.

=head1 SYNOPSIS

  use ProjectBuilder::Conf;

  #
  # Read hash codes of values from a configuration file and return table of pointers
  #
  my ($k1, $k2) = pb_conf_read_if("$ENV{'HOME'}/.pbrc","key1","key2");
  my ($k) = pb_conf_read("$ENV{'HOME'}/.pbrc","key");

=head1 USAGE

=over 4

=item B<pb_conf_init>

This function setup the environment PBPROJ for project-builder function usage from other projects.
The first parameter is the project name.
It sets up environment variables (PBPROJ) 

=cut

sub pb_conf_init {

my $proj=shift;

pb_log(1,"Entering pb_conf_init\n");
#
# Check project name
# Could be with env var PBPROJ
# or option -p
# if not defined take the first in conf file
#
if ((defined $ENV{'PBPROJ'}) &&
	(not defined $proj)) {
	pb_log(2,"PBPROJ env var setup ($ENV{'PBPROJ'}) so using it\n");
	$proj = $ENV{'PBPROJ'};
}

if (defined $proj) {
	$ENV{'PBPROJ'} = $proj;
} else {
	$ENV{'PBPROJ'} = "default";
}
pb_log(1,"PBPROJ = $ENV{'PBPROJ'}\n");
}


=item B<pb_conf_cache>

This function caches the configuration file content passed as first parameter into the a hash passed in second parameter
It returns the modified hash
Can be used in correlation with the %h hash to store permanently values or not if temporarily.

=cut

sub pb_conf_cache {

my $cf = shift;
my $lh = shift;

# Read the content of the config file and cache it in the %h hash then available for queries
open(CONF,$cf) || confess "Unable to open $cf";
while(<CONF>) {
	next if (/^#/);
	if (/^\s*([A-z0-9-_.]+)\s+([[A-z0-9-_.\?\[\]\*\+\\]+)\s*=\s*(.*)$/) {
		pb_log(3,"DEBUG: 1:$1 2:$2 3:$3\n");
		$lh->{$1}->{$2}=$3;
	}
}
close(CONF);
return($lh);
}

=item B<pb_conf_add>

This function adds the configuration file to the list last, and cache their content in the %h hash

=cut

sub pb_conf_add {

pb_log(2,"DEBUG: pb_conf_add with ".Dumper(@_)."\n");
my $lh;

foreach my $cf (@_) {
	if (! -r $cf) {
		pb_log(0,"WARNING: pb_conf_add can not read $cf\n");
		next;
	}
	# Skip already used conf files
	return($lh) if (defined $pbconffiles{$cf});
	
	# Add the new one at the end
	my $num = keys %pbconffiles;
	pb_log(2,"DEBUG: pb_conf_cache of $cf at position $num\n");
	$pbconffiles{$cf} = $num;

	# Read the content of the config file 
	$lh = pb_conf_cache($cf,$lh);
	# and cache it in the %h hash for further queries but after the previous
	# as we load conf files in reverse order (most precise first)
	pb_conf_add_last_in_hash($lh)
}
}


=item B<pb_conf_read_if>

This function returns a table of pointers on hashes
corresponding to the keys in a configuration file passed in parameter.
If that file doesn't exist, it returns undef.

The format of the configuration file is as follows:

key tag = value1,value2,...

Supposing the file is called "$ENV{'HOME'}/.pbrc", containing the following:

  $ cat $HOME/.pbrc
  pbver pb = 3
  pbver default = 1
  pblist pb = 12,25

calling it like this:

  my ($k1, $k2) = pb_conf_read_if("$ENV{'HOME'}/.pbrc","pbver","pblist");

will allow to get the mapping:

  $k1->{'pb'}  contains 3
  $k1->{'default'} contains 1
  $k2->{'pb'} contains 12,25

Valid chars for keys and tags are letters, numbers, '-' and '_'.

The file read is forgotten after its usage. If you want permanent caching of the data, use pb_conf_add then pb_conf_get

=cut

sub pb_conf_read_if {

my $conffile = shift;
my @param = @_;

open(CONF,$conffile) || return((undef));
close(CONF);
return(pb_conf_read($conffile,@param));
}

=item B<pb_conf_read>

This function is similar to B<pb_conf_read_if> except that it dies when the file in parameter doesn't exist.

=cut

sub pb_conf_read {

my $conffile = shift;
my @param = @_;
my @ptr;
my $lh;

$lh = pb_conf_cache($conffile,$lh);

foreach my $param (@param) {
	push @ptr,$lh->{$param};
}
return(@ptr);
}

=item B<pb_conf_write>

This function writes in the file passed ias first parameter the hash of values passed as second parameter

=cut

sub pb_conf_write {

my $conffile = shift;
my $h = shift;

confess "No configuration file defined to write into !" if (not defined $conffile);
confess "No hash defined to read from !" if (not defined $h);
open(CONF,"> $conffile") || confess "Unable to write into $conffile";

foreach my $p (sort keys %$h) {
	my $j = $h->{$p};
	foreach my $k (sort keys %$j) {
		print CONF "$p $k = $j->{$k}\n";
	}
}
close(CONF);
}



=item B<pb_conf_get_in_hash_if>

This function returns a table, corresponding to a set of values queried in the hash passed in parameter or undef if it doesn't exist. 
It takes a table of keys as an input parameter.

=cut

sub pb_conf_get_in_hash_if {

my $lh = shift || return(());
my @params = @_;
my @ptr = ();

pb_log(2,"DEBUG: pb_conf_get_in_hash_if on params ".join(' ',@params)."\n");
foreach my $k (@params) {
	push @ptr,$lh->{$k};
}

pb_log(2,"DEBUG: pb_conf_get_in_hash_if returns\n".Dumper(@ptr));
return(@ptr);
}



=item B<pb_conf_get_if>

This function returns a table, corresponding to a set of values queried in the %h hash or undef if it doen't exist. It takes a table of keys as an input parameter.

The format of the configurations file is as follows:

key tag = value1,value2,...

It will gather the values from all the configurations files passed to pb_conf_add, and return the values for the keys

  $ cat $HOME/.pbrc
  pbver pb = 1
  pblist pb = 4
  $ cat $HOME/.pbrc2
  pbver pb = 3
  pblist default = 5

calling it like this:

  pb_conf_add("$HOME/.pbrc","$HOME/.pbrc2");
  my ($k1, $k2) = pb_conf_get_if("pbver","pblist");

will allow to get the mapping:

  $k1->{'pb'} contains 3
  $k2->{'pb'} contains 4

Valid chars for keys and tags are letters, numbers, '-' and '_'.

=cut

sub pb_conf_get_if {

return(pb_conf_get_in_hash_if($h,@_));
}

=item B<pb_conf_add_last_in_hash>

This function merges the values passed in the hash parameter into the %h hash, but only if itdoesn't already contain a value, or if the value is more precise (real value instead of default)

It is used internally by pb_conf_add and is not exported.

=cut

sub pb_conf_add_last_in_hash {

my $ptr = shift;

return if (not defined $ptr);
# TODO: test $ptr is a hash pointer

# When called without correct initialization, try to work anyway with default as project
pb_conf_init("default") if (not defined $ENV{'PBPROJ'});

my @params = (sort keys %$ptr);

# Everything is returned via @h
# @h contains the values overloading what @ptr may contain.
my @h = pb_conf_get_if(@params);
my @ptr = pb_conf_get_in_hash_if($ptr,@params);

my $p1;
my $p2;

pb_log(2,"DEBUG: pb_conf_add_last_in_hash params: ".Dumper(@params)."\n");
pb_log(2,"DEBUG: pb_conf_add_last_in_hash hash: ".Dumper(@h)."\n");
pb_log(2,"DEBUG: pb_conf_add_last_in_hash input: ".Dumper(@ptr)."\n");

foreach my $i (0..$#params) {
	$p1 = $h[$i];
	$p2 = $ptr[$i];
	# Always try to take the param from h 
	# in order to mask what could be defined already in ptr
	if (not defined $p2) {
		# exit if no p1 either
		next if (not defined $p1);
		# No ref in p2 so use p1
		$p1->{$ENV{'PBPROJ'}} = $p1->{'default'} if ((not defined $p1->{$ENV{'PBPROJ'}}) && (defined $p1->{'default'}));
	} else {
		# Ref found in p2
		if (not defined $p1) {
			# No ref in p1 so use p2's value
			$p2->{$ENV{'PBPROJ'}} = $p2->{'default'} if ((not defined $p2->{$ENV{'PBPROJ'}}) && (defined $p2->{'default'}));
			$p1 = $p2;
		} else {
			# Both are defined - handling the overloading
			if (not defined $p1->{'default'}) {
				if (defined $p2->{'default'}) {
					$p1->{'default'} = $p2->{'default'};
				}
			}

			if (not defined $p1->{$ENV{'PBPROJ'}}) {
				if (defined $p2->{$ENV{'PBPROJ'}}) {
					$p1->{$ENV{'PBPROJ'}} = $p2->{$ENV{'PBPROJ'}};
				} else {
					$p1->{$ENV{'PBPROJ'}} = $p1->{'default'} if (defined $p1->{'default'});
				}
			}
			# Now copy back into p1 all p2 content which doesn't exist in p1
			# p1 content always has priority over p2
			foreach my $k (keys %$p2) {
				$p1->{$k} = $p2->{$k} if (not defined $p1->{$k});
			}
		}
	}
	$h->{$params[$i]} = $p1;
}
pb_log(2,"DEBUG: pb_conf_add_last_in_hash output: ".Dumper($h)."\n");
}

=item B<pb_conf_get>

This function is the same B<pb_conf_get_if>, except that it tests each returned value as they need to exist in that case.

=cut

sub pb_conf_get {

my @param = @_;
my @return = pb_conf_get_if(@param);
my $proj = undef;

if (not defined $ENV{'PBPROJ'}) {
	$proj = "unknown";
} else {
	$proj = $ENV{'PBPROJ'};
}

confess "No params found for $proj" if (not @return);

foreach my $i (0..$#param) {
	confess "No $param[$i] defined for $proj" if (not defined $return[$i]);
}
return(@return);
}


=item B<pb_conf_get_all>

This function returns an array with all configuration parameters

=cut

sub pb_conf_get_all {

return(sort keys %$h);
}


=item B<pb_conf_get_hash>

This function returns a pointer to the hash with all configuration parameters

=cut

sub pb_conf_get_hash {

return($h);
}

=back 

=head1 WEB SITES

The main Web site of the project is available at L<http://www.project-builder.org/>. Bug reports should be filled using the trac instance of the project at L<http://trac.project-builder.org/>.

=head1 USER MAILING LIST

None exists for the moment.

=head1 AUTHORS

The Project-Builder.org team L<http://trac.project-builder.org/> lead by Bruno Cornec L<mailto:bruno@project-builder.org>.

=head1 COPYRIGHT

Project-Builder.org is distributed under the GPL v2.0 license
described in the file C<COPYING> included with the distribution.

=cut


1;
