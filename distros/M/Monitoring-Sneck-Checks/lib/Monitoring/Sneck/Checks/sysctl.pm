package Monitoring::Sneck::Checks::sysctl;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::sysctl - checks sysctl values

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    !aslr|control=CIS-1.5.3 framework=CIS|perl:sysctl -e kernel.randomize_va_space=2
    !no_forwarding||perl:sysctl -e net.ipv4.ip_forward=0 -e net.ipv6.conf.all.forwarding=0
    !securelevel||perl:sysctl -e 'kern.securelevel>=1'
    !ptrace||perl:sysctl -e 'kernel.yama.ptrace_scope=1|2|3' -m

=head1 DESCRIPTION

Checks each sysctl given is as wanted. One that is not, or is not
there, is CRITICAL, unless --missing-ok is given for those not there.

Each --expect is a name, a comparison, and a value. = and != take
values split by |, any of which is enough for =, and none of which may
match for !=. <, <=, >, and >= compare as numbers. Values are compared
with runs of spaces squashed, as some, such as net.ipv4.ip_local_port_range,
have tabs.

On Linux they are read from /proc/sys. A name with a / in it is taken
as the path under /proc/sys, for names with dots in parts of them,
such as net/ipv4/conf/eth0.100/forwarding. On FreeBSD they are read
through L<BSD::Sysctl>. Other OSes are UNKNOWN.

=head1 OPTIONS

- -e, --expect :: "name=value", or with !=, <, <=, >, or >=. May be
given more than once. Required.

- -m, --missing-ok :: Sysctls that are not there are OK, as for those
from a module that is not loaded.

=cut

sub option_spec { return ( 'expect|e=s@', 'missing-ok|m' ) }

sub required { return ('expect') }

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

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux' && $self->os ne 'freebsd';
	my @problems;
	my @seen;
	foreach my $expect ( @{ $self->opt('expect') } ) {
		my ( $name, $comparison, $wanted ) = $self->split_expect($expect);
		my $value = $self->value($name);
		if ( !defined($value) ) {
			push( @problems, $name . ' is not there' ) if !$self->opt('missing-ok');
			next;
		}
		push( @seen, $name . ' ' . $self->shown($value) );
		next if $self->expect_met( $value, $comparison, $wanted );
		push( @problems,
			$name . ' is ' . $self->shown($value) . ', wanted ' . $self->expect_wanted( $comparison, $wanted ) );
	} ## end foreach my $expect ( @{ $self->opt('expect') } )

	return $self->finish( $self->CRITICAL, join( ', ', @problems ) ) if defined( $problems[0] );
	return $self->finish( $self->OK,       defined( $seen[0] ) ? join( ', ', @seen ) : 'none of them are there' );
} ## end sub check

=head2 value

Returns the value of a sysctl with runs of space squashed, or undef if
it is not there, or on FreeBSD is a struct BSD::Sysctl can not give as
text.

=cut

sub value {
	my ( $self, $name ) = @_;

	my $value;
	if ( $self->os eq 'linux' ) {
		my $path = $name =~ m{/} ? $name : $name =~ tr{.}{/}r;
		return undef if $path =~ m{(?:\A|/)\.\.(?:/|\z)};
		$value = eval { $self->proc_file( 'sys/' . $path ) };
	} else {
		$value = eval { $self->sysctl($name) };
		$value = join( ' ', @{$value} ) if ref($value) eq 'ARRAY';
	}
	return undef if !defined($value) || ref($value);
	$value =~ s/\s+/ /g;
	$value =~ s/\A | \z//g;

	return $value;
} ## end sub value

1;
