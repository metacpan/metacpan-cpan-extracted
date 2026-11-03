package Monitoring::Sneck::Checks::hosts;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::hosts - checks /etc/hosts

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    hosts|perl:hosts
    hosts_db|perl:hosts -e db.example.org=192.0.2.20 -e db=192.0.2.20

=head1 DESCRIPTION

Reads the hosts file. Lines that do not start with a IP, have no names,
or have names that are not hostnames are WARNING, as is localhost not
being in it. Not being able to read it is CRITICAL, as is a name given
via --expect not mapping to the address given.

=head1 OPTIONS

- -f, --file :: The file.
Default :: /etc/hosts

- -e, --expect :: "name=address", a name that must map to that
address. May be given more than once.

- --no-localhost :: Do not require localhost to be in it.

=cut

sub option_spec { return ( 'file|f=s', 'expect|e=s@', 'no-localhost' ) }

sub defaults { return { file => '/etc/hosts' } }

sub validate {
	my ( $self, $options ) = @_;

	require Data::Validate::IP;
	my @problems;
	foreach my $expect ( @{ $options->{expect} // [] } ) {
		my ( $name, $address ) = split( /=/, $expect, 2 );
		if ( !defined($address) || !$self->is_host($name) || !Data::Validate::IP::is_ip($address) ) {
			push( @problems, '--expect "' . $expect . '" is not name=address' );
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

	require Data::Validate::IP;
	my $file    = $self->opt('file');
	my $content = read_file( $file, err_mode => 'quiet' );
	if ( !defined($content) ) {
		return $self->finish( $self->CRITICAL, 'can not read ' . $file . ', ' . $! );
	}

	my %addresses;
	my @problems;
	my $line_number = 0;
	my $entries     = 0;
	foreach my $line ( split( /\n/, $content ) ) {
		$line_number++;
		$line =~ s/#.*\z//;
		$line =~ s/\A\s+|\s+\z//g;
		next if $line eq '';

		my ( $address, @names ) = split( /\s+/, $line );
		if ( !Data::Validate::IP::is_ip( $address =~ s/%.*\z//r ) ) {
			push( @problems, 'line ' . $line_number . ' "' . $address . '" is not a IP' );
			next;
		}
		if ( !defined( $names[0] ) ) {
			push( @problems, 'line ' . $line_number . ' has no names' );
			next;
		}
		my $good_names = 0;
		foreach my $name (@names) {
			if ( !$self->is_host($name) ) {
				push( @problems, 'line ' . $line_number . ' "' . $name . '" is not a hostname' );
				next;
			}
			push( @{ $addresses{ lc($name) } }, lc($address) );
			$good_names++;
		}
		$entries++ if $good_names;
	} ## end foreach my $line ( split( /\n/, $content ) )

	if ( !$self->opt('no-localhost') && !defined( $addresses{localhost} ) ) {
		push( @problems, 'localhost is not in it' );
	}
	my @codes = ( defined( $problems[0] ) ? $self->WARNING : $self->OK );

	foreach my $expect ( @{ $self->opt('expect') // [] } ) {
		my ( $name, $address ) = split( /=/, $expect, 2 );
		next if grep { $_ eq lc($address) } @{ $addresses{ lc($name) } // [] };
		push( @codes, $self->CRITICAL );
		push( @problems,
				  $name . ' is '
				. ( defined( $addresses{ lc($name) } ) ? join( ', ', @{ $addresses{ lc($name) } } ) : 'not in it' )
				. ', not '
				. $address );
	} ## end foreach my $expect ( @{ $self->opt('expect') //...})

	my $message = $file . ', ' . $entries . ' entries';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

1;
