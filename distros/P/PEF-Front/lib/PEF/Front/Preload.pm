package PEF::Front::Preload;
use strict;
use warnings;
use PEF::Front::Config;
use PEF::Front::Validator;
use PEF::Front::Connector;
use File::Find;
use Data::Dumper;
use Carp;

my %preload_parts = (
	model         => 1,
	db_connect    => 1,
	local_modules => 1,
	in_filters    => 1,
	out_filters   => 1,
);

sub import {
	my ($class, @args) = @_;
	for my $arg (@args) {
		if ($arg =~ s/^no[-_:]//) {
			delete $preload_parts{$arg};
		} else {
			$preload_parts{$arg} = 1;
		}
	}
	for my $part (keys %preload_parts) {
		if ($preload_parts{$part}) {
			eval "preload_$part();";
			croak $@ if $@;
		}
	}
}

sub preload_model {
	opendir my $mdir, cfg_model_dir
	  or croak "can't open model description directory: $!";
	my @methods =
	  map { s/\.yaml$//; s/[[:upper:]]\K([[:upper:]])/ \l$1/g; s/[[:lower:]]\K([[:upper:]])/ \l$1/g; lcfirst }
	  grep { /\.yaml$/ } readdir $mdir;
	closedir $mdir;
	for (@methods) {
		eval { PEF::Front::Validator::load_validation_rules($_); };
		croak "model $_ validation exception: " . Dumper $@ if $@;
	}
}

sub preload_db_connect {
	PEF::Front::Connector::db_connect();
}

sub preload_any_modules {
	my ($mld, $mt) = @_;
	$mld =~ s|/+$||;
	my $skip_len = 1 + length $mld;
	my @modules;
	find(
		sub {
			my $lname = "$File::Find::dir/$_";
			push @modules, map { s|/|::|g; s|\.pm$||; $_ } substr ($lname, $skip_len)
			  if $lname =~ /\.pm$/;
		},
		$mld
	);
	for (@modules) {
		eval "use " . cfg_app_namespace . $mt . "::" . $_ . ";";
		croak $@ if $@;
	}
}

sub preload_local_modules {
	preload_any_modules(cfg_model_local_dir, "Local");
}

sub preload_in_filters {
	preload_any_modules(cfg_in_filter_dir, "InFilter");
}

sub preload_out_filters {
	preload_any_modules(cfg_out_filter_dir, "OutFilter");
}

1;

__END__

=head1 NAME
 
PEF::Front::Preload - Pre-load application parts

=head1 SYNOPSIS

  use PEF::Front::Preload;

=head1 DESCRIPTION

This module pre-loads application modules and makes database connect.

=head1 USAGE

You can turn off preloads of some unneeded parts.

  use PEF::Front::Preload qw(no_db_connect);
  
Following parts can be turned off:

=over

=item model

Don't load model description files.

  use PEF::Front::Preload qw(no_model);

=item db_connect

Don't connect to database.

  use PEF::Front::Preload qw(no_db_connect);

=item local_modules

Don't load local model handlers.

  use PEF::Front::Preload qw(no_local_modules);

=item in_filters

Don't load input filters.

  use PEF::Front::Preload qw(no_in_filters);

=item out_filters

Don't load output filters.

  use PEF::Front::Preload qw(no_out_filters);

=back

You can combine these switches as you wish:

  use PEF::Front::Preload qw(no_model no_db_connect);

Usually you use this module right after loading your configuration module
C<*::AppFrontConfig>.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

