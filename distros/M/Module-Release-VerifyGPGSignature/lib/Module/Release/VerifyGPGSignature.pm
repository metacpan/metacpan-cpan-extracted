use v5.20;

package Module::Release::VerifyGPGSignature;
use strict;
use experimental qw(signatures);

use warnings;
no warnings;
use Exporter qw(import);

our @EXPORT = qw(check_all_gpg_signatures check_gpg_signature);

our $VERSION = '0.002';

=encoding utf8

=head1 NAME

Module::Release::VerifyGPGSignature - Verify GPG signatures in the distro

=head1 SYNOPSIS

	use Module::Release::VerifyGPGSignature;

=head1 DESCRIPTION

Configure in F<.releaserc> as a list of pairs:

    gpg_signatures \
    	file.txt file.txt.gpg \
    	file2.txt file2.txt.gpg

=over 4

=cut

sub _get_file_pairs ( $self ) {
	state $rc = require Getopt::Long;
	my $key = _key($self);
	my $string = $self->config->$key();

	my( $ret, $args ) = Getopt::Long::GetOptionsFromString($string);

	$self->_print( "Odd number of arguments in $key." ) if @$args % 2;

	my @pairs;
	while( @$args > 1 ) {
		push @pairs, [ splice @$args, 0, 2, () ];
		}
	push @pairs, [ @$args ] if @$args;

	\@pairs
	}

sub _key ( $self ) { 'gpg_signatures' }

=item * check_all_gpg_signatures

Go through all files and signature files listed in the C<gpg_signatures>
and verify that the signatures match.

=cut

sub check_all_gpg_signatures ( $self ) {
	my $pairs = $self->_get_file_pairs;
	foreach my $pair ( $pairs->@* ) {
		$self->check_gpg_signature( $pair->@* )
		}
	return 1;
	}

=item * check_gpg_signature( FILE, SIGNATURE_FILE )

Checks the PGP signature in SIGNATURE_FILE matches for FILE.

=cut

sub check_gpg_signature ( $self, $file, $signature_file ) {
	$self->_print( "Checking GPG signature of <$file>...\n" );

	$self->_die( "\nERROR: Could not verify signature of <$file>: file does not exist\n" )
		unless -e $file;

	$self->_die( "\nERROR: Could not verify signature of <$file> with <$signature_file>: signature file does not exist\n" )
		unless -e $signature_file;

	my $result = $self->run( qq(gpg --verify "$signature_file" "$file" 2>&1) );
	$result =~ s/^/    /mg;
	$self->_print( "$result" );

	unless( $result =~ /\bGood signature from\b/ ) {
		$self->_die( "\nERROR: signature verification failed" );
		}

	return 1;
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/module-release-verifygpgsignature

=head1 AUTHOR

brian d foy, C<< <brian d foy> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2022, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
