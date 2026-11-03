package Monitoring::Sneck::Checks::config_value;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::config_value - checks values in config files

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    !pass_max_days|control=CIS-5.5.1.1 framework=CIS|perl:config_value -f /etc/login.defs -e 'PASS_MAX_DAYS<=365' -e 'PASS_MIN_DAYS>=1'
    !no_forwarding||perl:config_value -f /etc/sysctl.conf -S = -e net.ipv4.ip_forward=0 -d net.ipv4.ip_forward=0
    !sendmail_off||perl:config_value -f /etc/rc.conf -S = -e sendmail_enable=NO|NONE
    !umask||perl:config_value -f /etc/login.defs -e UMASK=027|077

=head1 DESCRIPTION

Reads a file of settings, one per line, and checks each given with
--expect, the same way as L<Monitoring::Sneck::Checks::sysctl>, with =,
!=, <, <=, >, or >=. One that is not as wanted, or is not set and has
no --default, is CRITICAL, as is the file not being readable.

By default the name and value are split by spaces or a =, as for
login.defs and the like. --separator sets what splits them. Spaces
around it, and quotes around the value, are dropped, so 'x="YES"' is
x YES. Lines starting with # are left out, as is anything after a #
that has a space before it.

The last value wins, as for rc.conf and sysctl.conf, unless --first
is given. Names and values are compared without case, unless
--case-sensitive is given.

=head1 OPTIONS

- -f, --file :: The file. Required.

- -e, --expect :: "name=value", or with !=, <, <=, >, or >=. May be
given more than once. Required.

- -d, --default :: "name=value", what is used if it is not set. May be
given more than once.

- -S, --separator :: What splits a name and its value.
Default :: spaces or a =

- -F, --first :: The first value wins.

- -C, --case-sensitive :: Compare names and values with case.

=cut

sub option_spec { return ( 'file|f=s', 'expect|e=s@', 'default|d=s@', 'separator|S=s', 'first|F', 'case-sensitive|C' ) }

sub required { return ( 'file', 'expect' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $expect ( @{ $options->{expect} // [] } ) {
		my ( $name, $comparison, $value ) = $self->split_expect($expect);
		if ( !defined($name) ) {
			push( @problems, '--expect "' . $expect . '" is not name=value' );
		} elsif ( $comparison =~ /[<>]/ && $value !~ /\A-?[0-9]+(?:\.[0-9]+)?\z/ ) {
			push( @problems, '--expect "' . $expect . '" needs a number for ' . $comparison );
		}
	}
	foreach my $default ( @{ $options->{default} // [] } ) {
		push( @problems, '--default "' . $default . '" is not name=value' ) if $default !~ /\A[^=\s]+=/;
	}
	push( @problems, '--separator can not be empty' )
		if defined( $options->{separator} ) && $options->{separator} eq '';

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $settings = $self->settings;
	return $self->finish( $self->CRITICAL, $settings ) if !ref($settings);
	my $case = $self->opt('case-sensitive');
	my %defaults;
	foreach my $default ( @{ $self->opt('default') // [] } ) {
		my ( $name, $value ) = split( /=/, $default, 2 );
		$defaults{ $case ? $name : lc($name) } = $value;
	}

	my @problems;
	my @seen;
	foreach my $expect ( @{ $self->opt('expect') } ) {
		my ( $name, $comparison, $wanted ) = $self->split_expect($expect);
		my $key    = $case ? $name : lc($name);
		my $value  = $settings->{$key};
		my $source = '';
		if ( !defined($value) && defined( $defaults{$key} ) ) {
			$value  = $defaults{$key};
			$source = ' by default';
		}
		if ( !defined($value) ) {
			push( @problems, $name . ' is not set' );
			next;
		}
		push( @seen, $name . ' ' . $self->shown($value) . $source );
		next if $self->expect_met( $value, $comparison, $wanted, !$case );
		push( @problems,
				  $name . ' is '
				. $self->shown($value)
				. $source
				. ', wanted '
				. $self->expect_wanted( $comparison, $wanted ) );
	} ## end foreach my $expect ( @{ $self->opt('expect') } )

	return $self->finish( $self->CRITICAL, join( ', ', @problems ) ) if defined( $problems[0] );
	return $self->finish( $self->OK,       join( ', ', @seen ) );
} ## end sub check

=head2 settings

Reads the file into a hash ref of names, lower cased unless
--case-sensitive, to values. Returns why if it can not be read.

=cut

sub settings {
	my ($self) = @_;

	my $file    = $self->opt('file');
	my $content = read_file( $file, err_mode => 'quiet' );
	return 'can not read ' . $file . ', ' . $! if !defined($content);

	my $separator = defined( $self->opt('separator') ) ? qr/\s*\Q${\ $self->opt('separator')}\E\s*/ : qr/\s*=\s*|\s+/;
	my %settings;
	foreach my $line ( split( /\r?\n/, $content ) ) {
		next if $line =~ /\A\s*(?:#|\z)/;
		$line         =~ s/\s+#.*\z//;
		$line         =~ s/\A\s+|\s+\z//g;
		my ( $name, $value ) = split( $separator, $line, 2 );
		next if !defined($value) || $name eq '';
		$value =~ s/\A(["'])(.*)\1\z/$2/;
		$value =~ s/\s+/ /g;
		my $key = $self->opt('case-sensitive') ? $name : lc($name);
		next if $self->opt('first') && exists( $settings{$key} );
		$settings{$key} = $value;
	} ## end foreach my $line ( split( /\r?\n/, $content ) )

	return \%settings;
} ## end sub settings

1;
