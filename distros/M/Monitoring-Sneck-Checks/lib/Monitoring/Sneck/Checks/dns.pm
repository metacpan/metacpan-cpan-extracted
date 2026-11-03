package Monitoring::Sneck::Checks::dns;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::dns - checks a DNS lookup

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    dns_www|perl:dns -H www.example.org -a 192.0.2.10
    dns_auth|perl:dns -H example.org -q SOA -s 192.0.2.53 -A -w 0.5 -c 1
    dns_mx|perl:dns -H example.org -q MX -a '10 mail.example.org'
    dmarc|perl:dns -H _dmarc.example.org -q TXT -r '^"v=DMARC1; p=(quarantine|reject)'

=head1 DESCRIPTION

Looks up a name through L<Net::DNS>. No reply, a error such as NXDOMAIN,
or no records of the type is CRITICAL, as is a expected answer missing.

=head1 OPTIONS

- -H, --hostname :: The name to look up. Required.

- -q, --type :: The record type. ANY takes whatever records come
back, each said with its type, though many servers answer ANY with
only a HINFO record, as RFC 8482 lets them.
Default :: A

- -s, --server :: A server to ask. May be given more than once. The
system's if not given.

- -a, --expect :: A answer that must be there, as the record data, such
as 192.0.2.10 or "10 mail.example.org". May be given more than once.

- -r, --regex :: A regex some answer must match, as the record data,
such as '^"v=spf1 ' for a TXT record. May be given more than once,
each needing a match.

- -A, --authoritative :: The answer must be authoritative.

- --tcp :: Ask over TCP.

- -w, --warning :: Range of seconds for the lookup.

- -c, --critical :: Range of seconds for the lookup.

=cut

sub option_spec {
	return (
		'hostname|H=s',    'type|q=s', 'server|s=s@', 'expect|a=s@', 'regex|r=s@',
		'authoritative|A', 'tcp',      'warning|w=s', 'critical|c=s'
	);
}

sub defaults { return { type => 'A' } }

sub required { return ('hostname') }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--type "' . $options->{type} . '" is not a record type' )
		if $options->{type} !~ /\A[A-Za-z0-9]+\z/;
	foreach my $server ( @{ $options->{server} // [] } ) {
		push( @problems, '--server "' . $server . '" is not a IP or hostname' ) if !$self->is_host($server);
	}
	foreach my $regex ( @{ $options->{regex} // [] } ) {
		push( @problems, '--regex "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/; 1 };
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $resolver = $self->resolver( servers => $self->opt('server'), tcp => $self->opt('tcp') );
	my $name     = $self->opt('hostname');
	my $type     = uc( $self->opt('type') );

	my $start   = Time::HiRes::time;
	my $reply   = $resolver->send( $name, $type );
	my $seconds = sprintf( '%.3f', Time::HiRes::time - $start );
	if ( !defined($reply) ) {
		return $self->finish( $self->CRITICAL, 'no reply for ' . $name . ' ' . $type . ', ' . $resolver->errorstring );
	}

	$self->perfdata(
		label    => 'time',
		value    => $seconds,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $from  = ' from ' . ( $reply->answerfrom // 'unknown' );
	my $rcode = $reply->header->rcode;
	if ( $rcode ne 'NOERROR' ) {
		return $self->finish( $self->CRITICAL, $name . ' ' . $type . ' got ' . $rcode . $from );
	}

	# ANY takes every record, so those are said with their types. Net::DNS wraps long ones, such as
	# DNSKEY and RRSIG, over lines, which the status line can not have, so runs of space are squashed
	my @records = grep                 { $type eq 'ANY' || $_->type eq $type } $reply->answer;
	my @answers = map                  { $_->rdstring =~ s/\s+/ /gr } @records;
	my @said    = $type eq 'ANY' ? map { $_->type . ' ' . ( $_->rdstring =~ s/\s+/ /gr ) } @records : @answers;
	if ( !defined( $answers[0] ) ) {
		return $self->finish( $self->CRITICAL, $name . ' has no ' . $type . ' records' . $from );
	}

	my @codes = ( $self->threshold_status( $seconds, $self->opt('warning'), $self->opt('critical') ) );
	my @problems;
	push( @problems, 'slow' ) if $codes[0] != $self->OK;
	my %have = map { _normal($_) => 1 } @answers;
	foreach my $expected ( @{ $self->opt('expect') // [] } ) {
		next if $have{ _normal($expected) };
		push( @codes,    $self->CRITICAL );
		push( @problems, 'missing ' . $expected );
	}
	foreach my $regex ( @{ $self->opt('regex') // [] } ) {
		next if grep { $_ =~ /$regex/ } @answers;
		push( @codes,    $self->CRITICAL );
		push( @problems, 'nothing matching /' . $regex . '/' );
	}
	if ( $self->opt('authoritative') && !$reply->header->aa ) {
		push( @codes,    $self->CRITICAL );
		push( @problems, 'not authoritative' );
	}

	my $message = $name . ' ' . $type . ' ' . join( ', ', @said ) . ' in ' . $seconds . ' seconds' . $from;
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

# Normalizes record data so answers can be compared with what is
# expected. Lower cases it, squashes runs of space, and drops trailing
# dots on names, as Net::DNS ends names in them.
#
# Args...
#
#     - data :: The record data, such as '10 mail.example.org.'.
#
# Returns the normalized text.
#
# Example...
#
#     _normal('10  Mail.Example.org.');
#     # '10 mail.example.org'
sub _normal {
	my ($data) = @_;

	$data = lc($data);
	$data =~ s/\s+/ /g;
	$data =~ s/\.(\s|\z)/$1/g;

	return $data;
}

1;
