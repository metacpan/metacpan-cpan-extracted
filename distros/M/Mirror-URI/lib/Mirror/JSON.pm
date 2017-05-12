package Mirror::JSON;

use 5.006;
use strict;
use Mirror::URI ();
use JSON        ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.90';
	@ISA     = 'Mirror::URI';
}





#####################################################################
# Implementation-Specific Methods

sub filename {
	return 'mirror.json';
}

sub parse {
	my $class = shift;

	# Make sure we actually have a YAML document
	unless ( $_[0] =~ /^{/ ) {
		return undef;
	}

	# Parse the file
	my $docs = JSON::from_json($_[0]);

	# We only care about the first document
	unless ( defined $docs ) {
		Carp::croak("Illegal JSON document");
	}

	return $docs;
}

1;

=pod

=head1 NAME

Mirror::JSON - Mirror Configuration and Auto-Discovery

=head1 DESCRIPTION

A C<mirror.json> file is used to allow a repository client to reliably and
robustly locate, identify, validate and age a repository.

It contains a timestamp for when the repository was last updated, the URI
for the master repository, and a list of all the current mirrors at the
time the repository was last updated.

B<Mirror::JSON> contains all the functionality requires to both create
and read the F<mirror.json> files, and the logic to select one or more
mirrors entirely automatically.

It currently scales cleanly for a dozen or so mirrors, but may be slow
when used with very large repositories with a hundred or more mirrors.

=head2 Methodology

A variety of simple individual mechanisms are combined to provide a
completely robust discovery and validation system.

B<URI Validation>

The F<mirror.json> file should exist in a standard location, typically at
the root of the repository. The file is very small (no more than a few
kilobytes at most) so the overhead of fetching one (or several) of them
is negligable.

The file is pulled via FTP or HTTP. Once pulled, the first three
characters are examined to validate it is a JSON file and not a
login page for a "captured hotspot" such as at hotels and airports.

B<Responsiveness>

Because the F<mirror.json> file is small (in simple cases only one or two
packets) the download time can be used to measure the responsiveness of
that mirror.

By pulling the files from several mirrors, the comparative download
times can be used as part of the process of selecting the fastest mirror.

B<Timestamp>

The mirror.json file contains a timestamp that records the last update time
for the repository. This timestamp should be updated every repository
update cycle, even if there are no actual changes to the repository.

Once a F<mirror.json> file has been fetched correctly, the timestamp can
then be used to verify the age of the mirror. Whereas a perfectly up to
date mirror will show an age of less than an hour (assuming that the
repository master updates every hour) a repository that has stopped
updating will show an age that is greater than the longest mirror rate
plus the update cycle time.

Thus, any mirror that as "gone stale" can be filter out of the potential
mirrors to use.

For portability, the timestamp is recording in ISO format Zulu time.

B<Master Repository URI>

The F<mirror.json> file contains a link to the master repository.

If the L<Mirror::JSON> client has an out-of-date current state at some
point, it will use the master repository URI in the current state to 
pull a fresh F<mirror.json> from the master repository.

This solves the most-simple case, but other cases require a little
more complexity (which we'll address later).

B<Mirror URI List>

The F<mirror.json> file contains a simple list of all mirror URIs.

Apart from filtering the list to try and find the best mirror to use,
the mirror list allows the B<Mirror::JSON> client to have backup
options for locating the master repository if it moves, or the
bootstrap F<mirror.json> file has gotten old.

If the client can't find the master repository (because it has moved)
the client will scan the list of mirrors to try to find the location
of the updated repository.

B<The Bootstrap mirror.json>

To bootstrap the client, it should come with a default bootstrap
F<mirror.json> file built into it. When the client starts up for the
first time, it will attempt to fetch an updated mirror.json from the
master repository, and if that doesn't exist will pull from the
default list of mirrors until it can find more than one up to date
mirror that agrees on the real location of the master server.

B<Anti-Hijacking Functionality>

On top of the straight forward mirror discovery functionality, the
client algorithm contains additional logic to deal with either a
mirror or the master server goes bad. While likely not 100% secure
it heads off several attack scenarios to prevent anyone trying them,
and provides as much as can be expected without resorting to cryto
and certificates.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mirror-URI>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Mirror::YAML>, L<Mirror::CPAN>, L<JSON>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
