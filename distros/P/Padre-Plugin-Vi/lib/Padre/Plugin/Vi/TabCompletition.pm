package Padre::Plugin::Vi::TabCompletition;
use strict;
use warnings;
use 5.008005;

use base 'Exporter';
our @EXPORT_OK = qw(clear_tab handle_tab set_original_cwd);

our $VERSION = '0.23';

my @commands = qw(e w);
my @current_options;
my $tab_started;
my $last_tab;
my $original_cwd;

sub set_original_cwd {
	$original_cwd = shift;
}

sub clear_tab {
	$tab_started = undef;
}

sub handle_tab {
	my ( $txt, $shift ) = @_;

	$txt = '' if not defined $txt;

	if ( not defined $tab_started ) {
		$last_tab    = '';
		$tab_started = $txt;

		# setup the loop
		if ( $tab_started eq '' ) {
			@current_options = @commands;

			#warn "C @current_options";
		} elsif ( $tab_started =~ /^e\s+(.*)$/ ) {
			my $prefix = $1;
			my $path   = $original_cwd;

			#warn "O: $path";
			if ($prefix) {
				if ( File::Spec->file_name_is_absolute($prefix) ) {
					$path = $prefix;
				} else {
					$path = File::Spec->catfile( $path, $prefix );
				}
			}

			#warn "O: $path";
			$prefix = '';
			my $dir = $path;
			if ( -e $path ) {
				if ( -f $path ) {
					return;
				} elsif ( -d $path ) {
					$dir    = $path;
					$prefix = '';

					# go ahead, opening the directory
				} else {

					# what shall we do here?
					return;
				}
			} else { # partial file or directory name
				$dir    = File::Basename::dirname($path);
				$prefix = File::Basename::basename($path);
			}
			if ( opendir my $dh, $dir ) {
				@current_options = sort
					map { -d File::Spec->catfile( $dir, "$prefix$_" ) ? "$_/" : $_ }
					map { $_ =~ s/^$prefix//; $_ }
					grep { $_ =~ /^$prefix/ }
					grep { $_ ne '.' and $_ ne '..' } readdir $dh;
			}
		} else {
			@current_options = ();
		}
	}

	return if not @current_options; # somehow alert the user?

	my $option;
	if ($shift) {
		if ( $last_tab eq 'for' ) {
			unshift @current_options, pop @current_options;
		}
		$option = pop @current_options;
		unshift @current_options, $option;
		$last_tab = 'back';
	} else {
		if ( $last_tab eq 'back' ) {
			push @current_options, shift @current_options;
		}
		$option = shift @current_options;
		push @current_options, $option;
		$last_tab = 'for';
	}

	return $tab_started . $option;
}

1;

# Copyright 2008-2010 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
