package Monitoring::Sneck::Checks::resolv;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::resolv - checks /etc/resolv.conf and its nameservers

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# The keywords resolv.conf may have, across Linux and the BSDs.
our %KEYWORDS = map { $_ => 1 } ( 'nameserver', 'domain', 'search', 'sortlist', 'options', 'lookup', 'family' );

# How many nameservers the C library uses.
our $MAX_NAMESERVERS = 3;

=head1 SYNOPSIS

    resolv|perl:resolv
    resolv_works|perl:resolv -q www.example.org

=head1 DESCRIPTION

Reads resolv.conf. Lines it does not understand, keywords with nothing after them,
nameservers that are not IPs, bad domain or search domains, no
nameservers, or more than the C library uses, 3, are WARNING. Not being able to read it is CRITICAL.

With --query, each nameserver is asked for it through L<Net::DNS>. Any
answer counts, NXDOMAIN included, as the server answered. None
answering is CRITICAL, some not answering is WARNING.

=head1 OPTIONS

- -f, --file :: The file.
Default :: /etc/resolv.conf

- -q, --query :: A name to ask each nameserver for.

=cut

sub option_spec { return ( 'file|f=s', 'query|q=s' ) }

sub defaults { return { file => '/etc/resolv.conf' } }

sub validate {
	my ( $self, $options ) = @_;

	return ( '--query "' . $options->{query} . '" is not a hostname' )
		if defined( $options->{query} ) && !$self->is_host( $options->{query} );

	return ();
}

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

	my @nameservers;
	my @problems;
	my $line_number = 0;
	foreach my $line ( split( /\n/, $content ) ) {
		$line_number++;
		$line =~ s/[#;].*\z//;
		$line =~ s/\A\s+|\s+\z//g;
		next if $line eq '';

		my ( $keyword, @values ) = split( /\s+/, $line );
		if ( !$KEYWORDS{$keyword} ) {
			push( @problems, 'line ' . $line_number . ' has unknown keyword "' . $keyword . '"' );
		} elsif ( !defined( $values[0] ) ) {
			push( @problems, 'line ' . $line_number . ' has nothing after ' . $keyword );
		} elsif ( $keyword eq 'nameserver' ) {
			my $address = $values[0] =~ s/%.*\z//r;
			if ( Data::Validate::IP::is_ip($address) ) {
				push( @nameservers, $values[0] );
			} else {
				push( @problems, 'line ' . $line_number . ' nameserver "' . $values[0] . '" is not a IP' );
			}
		} elsif ( $keyword eq 'domain' || $keyword eq 'search' ) {
			foreach my $domain (@values) {
				next if $domain eq '.' || $self->is_host( $domain =~ s/\.\z//r );
				push( @problems, 'line ' . $line_number . ' ' . $keyword . ' "' . $domain . '" is not a domain' );
			}
		}
	} ## end foreach my $line ( split( /\n/, $content ) )

	if ( !defined( $nameservers[0] ) ) {
		push( @problems, 'no nameservers, so the local host is used' );
	} elsif ( scalar(@nameservers) > $MAX_NAMESERVERS ) {
		push( @problems, scalar(@nameservers) . ' nameservers, but only the first ' . $MAX_NAMESERVERS . ' are used' );
	}
	my @codes = ( defined( $problems[0] ) ? $self->WARNING : $self->OK );

	if ( defined( $self->opt('query') ) && defined( $nameservers[0] ) ) {
		my @silent;
		foreach my $nameserver (@nameservers) {
			my $resolver = $self->resolver( servers => [ $nameserver =~ s/%.*\z//r ] );
			my $reply    = $resolver->send( $self->opt('query'), 'A' );
			push( @silent, $nameserver ) if !defined($reply);
		}
		if ( scalar(@silent) == scalar(@nameservers) ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, 'no nameserver answered for ' . $self->opt('query') );
		} elsif ( defined( $silent[0] ) ) {
			push( @codes,    $self->WARNING );
			push( @problems, join( ', ', @silent ) . ' did not answer for ' . $self->opt('query') );
		}
	} ## end if ( defined( $self->opt('query') ) && defined...)

	my $message = $file . ', nameservers ' . ( defined( $nameservers[0] ) ? join( ', ', @nameservers ) : 'none' );
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

1;
