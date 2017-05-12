# Declare our package
package POE::Devel::Benchmarker::GetPOEdists;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# auto-export the only sub we have
use base qw( Exporter );
our @EXPORT = qw( getPOEdists );

# import the helper modules
use LWP::UserAgent;
use HTML::LinkExtor;
use URI::URL;
use Archive::Tar;

# autoflush, please!
use IO::Handle;
STDOUT->autoflush( 1 );

# actually retrieves the dists!
sub getPOEdists {
	# should we debug?
	my $debug = shift;

	# okay, should we change directory?
	if ( -d 'poedists' ) {
		if ( $debug ) {
			print "[GETPOEDISTS] chdir( 'poedists' )\n";
		}

		if ( ! chdir( 'poedists' ) ) {
			die "Unable to chdir to 'poedists' dir: $!";
		}
	} else {
		if ( $debug ) {
			print "[GETPOEDISTS] downloading to current directory\n";
		}
	}

	# set the default URL
	my $url = "http://backpan.cpan.org/authors/id/R/RC/RCAPUTO/";

	# create our objects
	my $ua = LWP::UserAgent->new;
	my $p = HTML::LinkExtor->new;
	my $tar = Archive::Tar->new;

	# Request document and parse it as it arrives
	print "Getting $url via LWP\n" if $debug;
	my $res = $ua->request( HTTP::Request->new( GET => $url ),
		sub { $p->parse( $_[0] ) },
	);

	# did we successfully download?
	if ( $res->is_error ) {
		die "unable to download directory index on BACKPAN: " . $res->status_line;
	}

	# Download every one!
	foreach my $link ( $p->links ) {
		# skip IMG stuff
		if ( $link->[0] eq 'a' and $link->[1] eq 'href' ) {
			# get the actual POE dists!
			if ( $link->[2] =~ /^POE\-\d/ and $link->[2] =~ /\.tar\.gz$/ ) {
				# download the tarball!
				print "Mirroring $link->[2] via LWP\n" if $debug;
				my $mirror_result = $ua->mirror( $url . $link->[2], $link->[2] );
				if ( $mirror_result->is_error ) {
					warn "unable to mirror $link->[2]: " . $mirror_result->status_line;
					next;
				}

				# did we already untar this one?
				my $dir = $link->[2];
				$dir =~ s/\.tar\.gz$//;
				if ( ! -d $dir ) {
					# extract it!
					print "Extracting $link->[2] via Tar\n" if $debug;
					my $files = $tar->read( $link->[2], undef, { 'extract' => 'true' } );
					if ( $files == 0 ) {
						warn "unable to extract $link->[2]";
					}
				}
			}
		}
	}

	return;
}

1;
__END__
=head1 NAME

POE::Devel::Benchmarker::GetPOEdists - Automatically download all POE tarballs

=head1 SYNOPSIS

	apoc@apoc-x300:~$ cd poe-benchmarker
	apoc@apoc-x300:~/poe-benchmarker$ perl -MPOE::Devel::Benchmarker::GetPOEdists -e 'getPOEdists()'

=head1 ABSTRACT

This package automatically downloads all the POE tarballs from BACKPAN.

=head1 DESCRIPTION

This uses LWP + HTML::LinkExtor to retrieve POE tarballs from BACKPAN.

The tarballs are automatically downloaded to the current directory. Then, we use Archive::Tar to extract them all!

NOTE: we use LWP's useful mirror() sub which doesn't re-download files if they already exist!

=head2 getPOEdists

Normally you should pass nothing to this sub. However, if you want to debug the downloads+extractions you should pass
a true value as the first argument.

	perl -MPOE::Devel::Benchmarker::GetPOEdists -e 'getPOEdists( 1 )'

=head1 EXPORT

Automatically exports the getPOEdists() sub

=head1 SEE ALSO

L<POE::Devel::Benchmarker>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

