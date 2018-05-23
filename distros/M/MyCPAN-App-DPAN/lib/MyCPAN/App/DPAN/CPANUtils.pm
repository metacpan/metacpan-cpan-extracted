package MyCPAN::App::DPAN::CPANUtils;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.281';

use File::Spec::Functions;

{
package Local::Null::Logger;
no warnings 'redefine';

sub new { bless \ my $x, $_[0] }
sub AUTOLOAD { 1 }
sub DESTROY { 1 }
}


=encoding utf8

=head1 NAME

MyCPAN::App::DPAN::CPANUtils - various things to interact with CPAN

=head1 SYNOPSIS


	use MyCPAN::App::DPAN::CPANUtils;

	MyCPAN::App::DPAN::CPANUtils->pull_latest_whois( $directory );

=head1 DESCRIPTION

This is a base class for MyCPAN reporters. It mostly deals with file
and directory names that it composes from configuration and run details.
Most things should just use what is already there.

There is one abstract method that a subclass must implement on its own.
The C<get_report_file_extension> methods allows each reporter to have
a unique extension by which it can recognize its own reports.

=head2 Methods

=over 4

=item get_cpan_mirrors()

Return a list of true CPAN mirrors so you can download canonical index
files.

=cut

sub get_cpan_mirrors
	{
	my( $class, $logger ) = @_;

	my @mirrors = ();

	push @mirrors, qw(http://www.cpan.org http://www.perl.com/CPAN);

	return @mirrors;
	}

=item pull_latest_whois( $directory )

Grab the latest canonical F<01mailrc.txt.gz> and F<00whois.xml> files
and put them in C<$directory/authors>.

=cut

sub pull_latest_whois
	{
	my( $class, $directory, $logger ) = @_;
	$logger = Local::Null::Logger->new unless eval { $logger->can( 'debug' ) };

	unless( eval { require LWP::Simple } )
		{
		$logger->warn( "You need LWP::Simple to pull files from CPAN" );
		return;
		}

	unless( -d $directory )
		{
		$logger->warn( "The directory [$directory] does not exist" );
		return;
		}

	my $author_dir = catfile( $directory, 'authors' );
	unless( -d $author_dir or mkdir( $author_dir ) )
		{
		$logger->warn( "Could not create [$author_dir]: $!" );
		return;
		}

	my @mirrors = $class->get_cpan_mirrors;

	my %success;
	FILE: foreach my $file (
		map { catfile( 'authors', $_ ) }
		map { $class->$_() }
		qw(mailrc_filename whois_filename)
		)
		{
		if( -e $file and -M $file < 10*60 ) { $success{ $file }++; next FILE }
		MIRROR: foreach my $mirror ( $class->get_cpan_mirrors )
			{
			$mirror =~ s|/\z||;
			my $url = "$mirror/$file";

			$logger->info( "Trying to get $url" );
			my $http_status = LWP::Simple::getstore(
				$url,
				catfile( $directory, $file )
				);
			$logger->info( "$url returned $http_status" );

			if( LWP::Simple::is_success( $http_status ) )
				{
				$success{ $file }++;
				last MIRROR;
				}
			}
		}

	keys %success;
	}

=item make_fake_whois( $directory )

Create stub F<01mailrc.txt.gz> and F<00whois.xml> files
and put them in C<$directory/authors>.

=cut

sub make_fake_whois
	{
	my( $class, $directory, $logger ) = @_;
	$logger = Local::Null::Logger->new unless eval { $logger->can( 'debug' ) };

	unless( -d $directory )
		{
		$logger->warn( "The directory [$directory] does not exist" );
		return;
		}

	my $author_dir = catfile( $directory, 'authors' );
	unless( -d $author_dir or mkdir( $author_dir ) )
		{
		$logger->warn( "Could not create [$author_dir]: $!" );
		return;
		}

	no warnings;
	return
		$class->make_fake_01mailrc( $author_dir, $logger )
			+
		$class->make_fake_00whois(  $author_dir, $logger )
		;
	}

=item make_fake_01mailrc( $directory )

Create a stub F<01mailrc.txt.gz> in C<$directory>.

=cut

sub make_fake_01mailrc
	{
	my( $class, $directory, $logger ) = @_;

	$class->_shove_in_file(
		catfile( $directory, $class->mailrc_filename ),
		'',
		$logger
		);
	}

=item make_fake_00whois( $directory )

Create a stub F<00whois.xml> in C<$directory>.

=cut

sub make_fake_00whois
	{
	my( $class, $directory, $logger ) = @_;

	my $date = gmtime() . ' GMT';

	my $content = <<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<cpan-whois xmlns='http://www.cpan.org/xmlns/whois'
            last-generated='$date'
            generated-by='dpan'>
</cpan-whois>
HERE

	$class->_shove_in_file(
		catfile( $directory, $class->whois_filename ),
		$content,
		$logger
		);
	}

sub _shove_in_file
	{
	my( $class, $filename, $content, $logger ) = @_;

	return if -e $filename;

	my $fh;
	unless( open $fh, '>:utf8', $filename )
		{
		$logger->warn( "Could not open $filename for writing: $!" );
		return;
		}

	print $fh $content;
	}

=item mailrc_filename

Returns the filename for F<01mailrc.txt.gz>.

=cut

sub mailrc_filename { '01mailrc.txt.gz' }

=item whois_filename

Returns the filename for F<00whois.xml>.

=cut

sub whois_filename { '00whois.xml' }

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-app-dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut


1;
