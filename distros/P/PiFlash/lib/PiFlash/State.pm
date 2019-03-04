# PiFlash::State - store program-site state information for PiFlash
# by Ian Kluft
#
# the information stored here includes configuration,command-line arguments, system hardware inspection results, etc
#

use strict;
use warnings;
use v5.18.0; # require 2014 or newer version of Perl

# State class to hold program state, and print it all out in case of errors
# this is a low-level package - it stores state data but at this level has no knowledge of what is being stored in it
package PiFlash::State;
$PiFlash::State::VERSION = '0.2.0';
use autodie;
use YAML::XS; # RPM: perl-YAML-LibYAML, DEB: libyaml-libyaml-perl
use Carp qw(croak);

# ABSTRACT: PiFlash::State class to store configuration, device info and program state



# initialize state as empty
## no critic (ProhibitPackageVars)
our $state;
## use critic

# initialize class' singleton object from parameters
# class method
sub init
{
	## no critic (ProhibitPackageVars)
	my $class = shift;
	(defined $PiFlash::State::state) and return; # avoid damaging data if called again

	# global security settings for YAML::XS parser
	# since PiFlash can run parts as root, we don't want any external code to be run without user authorization
	$YAML::XS::LoadBlessed = 0;
	$YAML::XS::UseCode = 0;
	$YAML::XS::LoadCode = 0;

	# instantiate the state object as a singleton (only one instance in the system)
	$PiFlash::State::state = {};
	bless $PiFlash::State::state, $class;
	my $self = $PiFlash::State::state;

	# get symbol table for State package so we can add accessor functions named for top-level hashes
	my $symtab = \%PiFlash::State::;

	# loop through parameters adding each name as a top-level state hash and accessor functions
	while (scalar @_ > 0) {
		my $top_level_param = shift;

		# create top-level hash named for the parameter
		$self->{$top_level_param} = {};

		# generate class accessor methods named for the parameter
		{
			# accessor fieldname()
			$symtab->{$top_level_param} = sub {
				my $name = shift;
				my $value = shift;
				if (defined $value) {
					# got name & value - set the new value for name
					$self->{$top_level_param}{$name} = $value;
					return;
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
	return PiFlash::State::cli_opt("verbose") // 0;
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
	if (ref $obj eq "HASH" or ref $obj eq "PiFlash::State") {
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
	croak "error: ".$message.(verbose() ? "\nProgram state dump...\n".odump($PiFlash::State::state,0) : "");
}

# read YAML configuration file
sub read_config
{
	my $filepath = shift;

	# if the provided file name exists and ...
	if ( -f $filepath) {
		# capture as many YAML documents as can be parsed from the configuration file
		my @yaml_docs = eval { YAML::XS::LoadFile($filepath); };
		if ($@) {
			PiFlash::State->error("PiFlash::State::read_config error reading $filepath: $@");
		}

		# save the first YAML document as the configuration
		my $yaml_config = shift @yaml_docs;
		if (ref $yaml_config eq "HASH") {
			# if it's a hash, then use all its mappings in PiFlash::State::config
			$PiFlash::State::state->{config} = $yaml_config;
		} else {
			# otherwise save the reference in a config entry called config
			PiFlash::State::config("config", $yaml_config);
		}

		# if any other YAML documents were parsed, save them as a list in a config called "docs"
		# these are available for plugins but not currently defined
		if (@yaml_docs) {
			# save the YAML doc structures as a list
			PiFlash::State::config("docs", \@yaml_docs);

			# the first doc must be the table of contents with a list of metadata about following docs
			# others after that are categorized by the plugin name in the metadata
			my $toc = $yaml_docs[0];
			if (ref $toc eq "ARRAY") {
				PiFlash::State::plugin("docs", {toc => $toc});
				my $docs = PiFlash::State::plugin("docs");
				for (my $i=1; $i < scalar @yaml_docs; $i++) {
					if (ref $yaml_docs[$i] eq "HASH" and exists $yaml_docs[$i]{plugin}) {
						my $type = $yaml_docs[$i]{plugin};
						$docs->{$type} = $yaml_docs[$i];
					}
				}
			}
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash::State - PiFlash::State class to store configuration, device info and program state

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

 # initialize: creates empty sub-objects and accessor functions as shown below
 PiFlash::State->init("system", "input", "output", "cli_opt", "log");

 # core functions
 $bool = PiFlash::State::verbose()
 PiFlash::State::odump
 PiFlash::State->error("error message");

 # system accessors
 my $system = PiFlash::State::system();
 my $bool = PiFlash::State::has_system($key);
 my $value = PiFlash::State::system($key);
 PiFlash::State::system($key, $value);

 # input accessors
 my $input = PiFlash::State::input();
 my $bool = PiFlash::State::has_input($key);
 my $value = PiFlash::State::input($key);
 PiFlash::State::input($key, $value);

 # output accessors
 my $output = PiFlash::State::output();
 my $bool = PiFlash::State::has_output($key);
 my $value = PiFlash::State::output($key);
 PiFlash::State::output($key, $value);

 # cli_opt accessors
 my $cli_opt = PiFlash::State::cli_opt();
 my $bool = PiFlash::State::has_cli_opt($key);
 my $value = PiFlash::State::cli_opt($key);
 PiFlash::State::cli_opt($key, $value);

 # log accessors
 my $log = PiFlash::State::log();
 my $bool = PiFlash::State::has_log($key);
 my $value = PiFlash::State::log($key);
 PiFlash::State::log($key, $value);

=head1 DESCRIPTION

This class contains internal functions used by L<PiFlash> to store command-line parameters, input & output file data, available device data and program logs.

PiFlash uses the device info to refuse to write/destroy a device which is not an SD card. This provides a safeguard while using root permissions against a potential error which has happened where users have accidentally erased the wrong block device, losing a hard drive they wanted to keep.

=head1 SEE ALSO

L<piflash>, L<PiFlash::Command>, L<PiFlash::Inspector>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
