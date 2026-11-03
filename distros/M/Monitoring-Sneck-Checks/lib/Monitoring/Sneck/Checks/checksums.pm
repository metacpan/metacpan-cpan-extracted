package Monitoring::Sneck::Checks::checksums;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::checksums - checks files against stored checksums

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Algorithms, by the length of their hex digests.
our %BY_LENGTH = ( 32 => 'md5', 40 => 'sha1', 56 => 'sha224', 64 => 'sha256', 96 => 'sha384', 128 => 'sha512' );

=head1 SYNOPSIS

    !setuid_sums||perl:checksums -l /usr/local/etc/sneck/setuid.sha256
    !sshd_sum||perl:checksums -F /usr/sbin/sshd=5ea6737a5debfd2195a09cb910d8c0e8d6fa3dda458b6de2ac400a17febd276a

To make a list, on Linux or FreeBSD.

    sha256sum /usr/bin/sudo /usr/bin/passwd > /usr/local/etc/sneck/setuid.sha256
    sha256 /usr/local/bin/sudo /usr/bin/passwd > /usr/local/etc/sneck/setuid.sha256

=head1 DESCRIPTION

Hashes each file and compares it against what is stored for it, through
Digest::MD5 and Digest::SHA. A file that differs, is not there, or can
not be read is CRITICAL. A list that can not be read, a line in one
that is not understood, or nothing to check, is UNKNOWN.

Lists may be in the format of sha256sum and the like, "hash  path", or
that of FreeBSD's sha256 and the like, and sha256sum --tag,
"SHA256 (path) = hash". Blank lines and those starting with # are
skipped. md5, sha1, sha224, sha256, sha384, and sha512 are known by the
length of the hash.

Anyone who can change the files can most likely change the list too,
so keep it somewhere they can not, and check it with
L<Monitoring::Sneck::Checks::file_mode>.

=head1 OPTIONS

- -l, --list :: A checksum list. May be given more than once.

- -F, --file :: "path=hash", a file and its hash. May be given more
than once.

One of --list or --file must be given.

=cut

sub option_spec { return ( 'list|l=s@', 'file|F=s@' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $file ( @{ $options->{file} // [] } ) {
		my ( $path, $hash ) = $file =~ /\A(.+)=([0-9A-Fa-f]+)\z/;
		push( @problems, '--file "' . $file . '" is not path=hash' ) if !defined($hash) || !$BY_LENGTH{ length($hash) };
	}
	push( @problems, 'nothing to check, give --list or --file' )
		if !defined( $options->{list} ) && !defined( $options->{file} );

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @entries;
	my @unknown;
	foreach my $list ( @{ $self->opt('list') // [] } ) {
		my $content = read_file( $list, err_mode => 'quiet' );
		if ( !defined($content) ) {
			push( @unknown, 'can not read ' . $list . ', ' . $! );
			next;
		}
		my $line_number = 0;
		foreach my $line ( split( /\r?\n/, $content ) ) {
			$line_number++;
			next if $line =~ /\A\s*(?:#|\z)/;
			my $entry = _parse($line);
			if ( !defined($entry) ) {
				push( @unknown, $list . ' line ' . $line_number . ' is not understood' );
				next;
			}
			push( @entries, $entry );
		} ## end foreach my $line ( split( /\r?\n/, $content ) )
	} ## end foreach my $list ( @{ $self->opt('list') // [] ...})
	foreach my $file ( @{ $self->opt('file') // [] } ) {
		my ( $path, $hash ) = $file =~ /\A(.+)=([0-9A-Fa-f]+)\z/;
		push( @entries, { path => $path, hash => lc($hash), algorithm => $BY_LENGTH{ length($hash) } } );
	}

	my @problems;
	my $matched = 0;
	foreach my $entry (@entries) {
		my $hash = eval { $self->hash_file( $entry->{path}, $entry->{algorithm} ) };
		if ( !defined($hash) ) {
			my $why = $@;
			$why =~ s/\s+\z//;
			push( @problems, $why );
		} elsif ( $hash ne $entry->{hash} ) {
			push( @problems, $entry->{path} . ' does not match its ' . $entry->{algorithm} );
		} else {
			$matched++;
		}
	} ## end foreach my $entry (@entries)

	my @codes = ( defined( $problems[0] ) ? $self->CRITICAL : $self->OK );
	push( @codes, $self->UNKNOWN ) if defined( $unknown[0] ) || !defined( $entries[0] );
	$self->perfdata( label => 'matched', value => $matched, min => 0, max => scalar(@entries) );
	my $message = $matched . ' of ' . scalar(@entries) . ' files match';
	$message = $message . ', ' . scalar(@problems) . ' do not' if defined( $problems[0] );
	$message = $message . ', ' . join( ', ', @unknown )        if defined( $unknown[0] );

	return $self->finish( $self->worst(@codes), $message, @problems );
} ## end sub check

=head2 hash_file

Returns the hex digest of a file. Dies if it can not be read.

- path :: The file.

- algorithm :: md5, sha1, sha224, sha256, sha384, or sha512.

    my $hash = $check->hash_file( '/usr/sbin/sshd', 'sha256' );

=cut

sub hash_file {
	my ( $self, $path, $algorithm ) = @_;

	die( $path . ' is not a file' . "\n" ) if -e $path && !-f $path;
	open( my $fh, '<:raw', $path ) or die( 'can not read ' . $path . ', ' . $! . "\n" );
	my $digest;
	if ( $algorithm eq 'md5' ) {
		require Digest::MD5;
		$digest = Digest::MD5->new;
	} else {
		require Digest::SHA;
		$digest = Digest::SHA->new( $algorithm =~ s/\Asha//r );
	}
	$digest->addfile($fh);
	close($fh);

	return $digest->hexdigest;
} ## end sub hash_file

# Parses a line of a checksum list.
#
# Args...
#
#     - line :: The line, such as 'e3b0...b855  /etc/motd' or
#       'SHA256 (/etc/motd) = e3b0...b855'.
#
# Returns a hash ref of path, hash, lower cased, and algorithm, or undef
# if it is not understood.
#
# Example...
#
#     _parse('SHA256 (/etc/motd) = E3B0...B855');
#     # { path => '/etc/motd', hash => 'e3b0...b855', algorithm => 'sha256' }
sub _parse {
	my ($line) = @_;

	my ( $tag, $path, $hash );
	if ( $line =~ /\A([A-Z0-9]+) \((.+)\) = ([0-9A-Fa-f]+)\s*\z/ ) {
		( $tag, $path, $hash ) = ( lc($1), $2, $3 );
	} elsif ( $line =~ /\A([0-9A-Fa-f]+) [ *](.+?)\s*\z/ ) {
		( $hash, $path ) = ( $1, $2 );
	} else {
		return undef;
	}
	my $algorithm = $BY_LENGTH{ length($hash) };
	return undef if !defined($algorithm) || ( defined($tag) && $tag ne $algorithm );

	return { path => $path, hash => lc($hash), algorithm => $algorithm };
} ## end sub _parse

1;
