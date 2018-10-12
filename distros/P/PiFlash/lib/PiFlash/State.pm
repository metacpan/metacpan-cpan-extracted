# PiFlash::State - store program-site state information for PiFlash
# by Ian Kluft
#
# the information stored here includes configuration,command-line arguments, system hardware inspection results, etc
#

use strict;
use warnings;
use v5.18.0; # require 2014 or newer version of Perl
use autodie;
use Moose; 
use Carp;

# State class to hold program state, and print it all out in case of errors
# this is a low-level package - it stores state data but at this level has no knowledge of what is being stored in it
package PiFlash::State;
$PiFlash::State::VERSION = '0.0.3';
# ABSTRACT: PiFlash::State class to store configuration, device info and program state



# initialize state as empty
## no critic (ProhibitPackageVars)
#BEGIN { $PiFlash::State::state = undef; }
our $state;
## use critic

# initialize class' singleton object from parameters
# class method
sub init
{
	## no critic (ProhibitPackageVars)
	my $class = shift;
	(defined $PiFlash::State::state) and return; # don't damage data if called again
	$PiFlash::State::state = {};
	bless $PiFlash::State::state, $class;
	my $self = $PiFlash::State::state;
	while (scalar @_ > 0) {
		my $top_level_param = shift;

		# create top-level hash named for the parameter
		$self->{$top_level_param} = {};

		# generate class accessor methods named for the parameter
		{
			# get symbol table for State package so we can add accessor functions named for top-level hashes
			my $symtab = \%PiFlash::State::;

			# accessor fieldname()
			$symtab->{$top_level_param} = sub {
				my $name = shift;
				my $value = shift;
				if (defined $value) {
					# got name & value - set the new value for name
					$self->{$top_level_param}{$name} = $value;
				} elsif (defined $name) {
					# got only name - return the value/ref of name
					return (exists $self->{$top_level_param}{$name})
						? $self->{$top_level_param}{$name}
						: undef;
				} else {
					# no name or value - return ref to top-level hash (top_level_parameter from init() context)
					return $self->{$top_level_param};
				}
			};

			# accessor has_fieldname()
			$symtab->{"has_".$top_level_param} = sub {
				my $name = shift;
				return ((exists $self->{$top_level_param}) and (exists $self->{$top_level_param}{$name}));
			}
		}
	}
	return;
}

# return boolean value for verbose mode
sub verbose
{
	return PiFlash::State::option("verbose") // 0;
}

# dump data structure recursively, part of verbose state output
# intended as a lightweight equivalent of Data::Dumper without requiring installation of an extra package
# object method
sub odump
{
	my ($obj, $level) = @_;
	if (!defined $obj) {
		# bail out for undefined value
		return "";
	}
	if (!ref $obj) {
		# process plain scalar
		return ("    " x $level)."[value]".$obj."\n";
	}
	if (ref $obj eq "SCALAR") {
		# process scalar reference
		return ("    " x $level).($$obj // "undef")."\n";
	}
	if (ref $obj eq "HASH" or ref $obj eq "State") {
		# process hash reference
		my $str = "";
		foreach my $key (sort {lc $a cmp lc $b} keys %$obj) {
			if (ref $obj->{$key}) {
				$str .= ("    " x $level)."$key:"."\n";
				$str .= odump($obj->{$key}, $level+1);
			} else {
				$str .= ("    " x $level)."$key: ".($obj->{$key} // "undef")."\n";
			}
		}
		return $str;
	}
	if (ref $obj eq "ARRAY") {
		# process array reference
		my $str = "";
		foreach my $entry (@$obj) {
			if (ref $entry) {
				$str .= odump($entry, $level+1);
			} else {
				$str .= ("    " x $level)."$entry\n";
			}
		}
		return $str;
	}
	if (ref $obj eq "CODE") {
		# process function reference
		return ("    " x $level)."[function]$obj"."\n";
	}
	# other references/unknown type
	my $type = ref $obj;
	return ("    " x $level)."[$type]$obj"."\n";
}

# die/exception with verbose state dump
# class method
sub error
{
	## no critic (ProhibitPackageVars)
	my $class = shift;
	my $message = shift;
	Carp::croak "error: ".$message.(verbose() ? "\nProgram state dump...\n".odump($PiFlash::State::state,0) : "");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash::State - PiFlash::State class to store configuration, device info and program state

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

 $bool = PiFlash::State::verbose()
 PiFlash::State::odump
 PiFlash::State->error("error message");

=head1 DESCRIPTION

This class contains internal functions used by L<PiFlash> to gather data about available devices on the system and determine if they are SD card devices.

PiFlash uses this info to refuse to write/destroy a device which is not an SD card. This provides a safeguard while using root permissions against a potential error which has happened where users have accidentally erased the wrong block device, losing a hard drive they wanted to keep.

=head1 SEE ALSO

L<piflash>, L<PiFlash::Command>, L<PiFlash::Inspector>, L<PiFlash::State>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
