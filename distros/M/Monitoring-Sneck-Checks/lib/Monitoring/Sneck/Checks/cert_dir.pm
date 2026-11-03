package Monitoring::Sneck::Checks::cert_dir;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Cwd        ();
use File::Find ();

=head1 NAME

Monitoring::Sneck::Checks::cert_dir - checks every certificate in directories

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ssl_dir|perl:cert_dir -d /usr/local/etc/ssl
    le_certs|perl:cert_dir -d /usr/local/etc/letsencrypt/live -r -m 'cert\.pem$' -w 21 -c 7

=head1 DESCRIPTION

Checks every certificate in the PEM files in each directory, without
having to name each file. Files with no certificates, such as keys
kept next to them, are skipped. A file reached more than once, such as
through a symlink, is only checked once, by its own name.

A directory that can not be read is CRITICAL. So is a expired
certificate, or one that is not good yet. Otherwise each certificate is
WARNING or CRITICAL by the days it has left. A file that can not be
read or parsed is UNKNOWN, as is finding no certificates at all.

The status line says how many were checked and which expires soonest.
Each one that is not OK gets its own line after it.

=head1 OPTIONS

- -d, --dir :: A directory. May be given more than once. Required.

- -r, --recursive :: Look in the directories under them too.

- -m, --match :: A regex the file names must match.
Default :: \.(?:pem|crt|cer)$

- -w, --warning :: Days left at or under which it is WARNING.
Default :: 30

- -c, --critical :: Days left at or under which it is CRITICAL.
Default :: 14

=cut

sub option_spec { return ( 'dir|d=s@', 'recursive|r', 'match|m=s', 'warning|w=i', 'critical|c=i' ) }

sub defaults { return { match => '\.(?:pem|crt|cer)$', warning => 30, critical => 14 } }

sub required { return ('dir') }

sub validate {
	my ( $self, $options ) = @_;

	return ('--match is not a valid regex') if !eval { qr/$options->{match}/; 1 };

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require IO::Socket::SSL::Utils;
	my @codes;
	my @problems;
	my $count = 0;
	my $soonest;
	my ( $files, $unreadable ) = $self->files;
	foreach my $dir ( @{$unreadable} ) {
		push( @codes,    $self->CRITICAL );
		push( @problems, 'can not read ' . $dir );
	}

	my $files_with_certs = 0;
	foreach my $file ( @{$files} ) {
		my $certs = eval { $self->pem_certs($file) };
		if ( !defined($certs) ) {
			my $why = $@;
			$why =~ s/\s+\z//;
			push( @codes,    $self->UNKNOWN );
			push( @problems, $why );
			next;
		}
		$files_with_certs++ if scalar( @{$certs} );
		my $number = 0;
		foreach my $cert ( @{$certs} ) {
			$number++;
			my $where = $file . ( scalar( @{$certs} ) > 1 ? ' #' . $number : '' );
			if ( !$cert ) {
				push( @codes,    $self->UNKNOWN );
				push( @problems, $where . ' can not be parsed' );
				next;
			}
			$count++;
			my $details = $self->cert_details($cert);
			IO::Socket::SSL::Utils::CERT_free($cert);
			my ( $code, $message ) = $self->cert_status( $details, $self->opt('warning'), $self->opt('critical') );
			push( @codes,    $code );
			push( @problems, $where . ' ' . $message ) if $code != $self->OK;
			if ( !defined($soonest) || $details->{not_after} < $soonest->{details}{not_after} ) {
				$soonest = { details => $details, where => $where, message => $message };
			}
		} ## end foreach my $cert ( @{$certs} )
	} ## end foreach my $file ( @{$files} )

	my $dirs = join( ', ', @{ $self->opt('dir') } );
	if ( !defined($soonest) ) {
		push( @codes, $self->UNKNOWN );
		return $self->finish( $self->worst(@codes), 'no certificates in ' . $dirs, @problems );
	}

	$self->perfdata(
		label    => 'days',
		value    => $soonest->{details}{days_left},
		warning  => $self->opt('warning'),
		critical => $self->opt('critical')
	);
	$self->perfdata( label => 'certificates', value => $count, min => 0 );
	my $message
		= $count
		. ' certificate'
		. ( $count == 1 ? '' : 's' ) . ' in '
		. $files_with_certs . ' file'
		. ( $files_with_certs == 1 ? '' : 's' ) . ' in '
		. $dirs;
	$message = $message . ', ' . scalar(@problems) . ' not OK' if defined( $problems[0] );
	$message = $message . ', soonest ' . $soonest->{where} . ' ' . $soonest->{message};

	return $self->finish( $self->worst(@codes), $message, @problems );
} ## end sub check

=head2 files

Finds the files to check.

Returns a array ref of the files whose names match, each only once,
real files first and then symlinks, each sorted, and a array ref of the
directories that could not be read.

    my ( $files, $unreadable ) = $check->files;

=cut

sub files {
	my ($self) = @_;

	my $match = $self->opt('match');
	my %seen;
	my @files;
	my @unreadable;
	foreach my $dir ( @{ $self->opt('dir') } ) {
		if ( !-d $dir || !opendir( my $handle, $dir ) ) {
			push( @unreadable, $dir );
			next;
		}
		my @found;
		File::Find::find(
			{
				no_chdir => 1,
				wanted   => sub {
					if ( -d $File::Find::name ) {
						$File::Find::prune = 1 if !$self->opt('recursive') && $File::Find::name ne $dir;
						return;
					}
					my $name = ( split( m{/}, $File::Find::name ) )[-1];
					push( @found, $File::Find::name ) if -f $File::Find::name && $name =~ /$match/;
				},
			},
			$dir
		);
		# real files before symlinks, so a file reached both ways goes by its own name
		foreach my $file ( sort { ( -l $a ? 1 : 0 ) <=> ( -l $b ? 1 : 0 ) || $a cmp $b } @found ) {
			my $real = Cwd::abs_path($file) // $file;
			next if $seen{$real}++;
			push( @files, $file );
		}
	} ## end foreach my $dir ( @{ $self->opt('dir') } )

	return ( \@files, \@unreadable );
} ## end sub files

1;
