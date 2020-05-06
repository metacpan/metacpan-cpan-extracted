package Module::Generate::YAML;
use 5.006; use strict; use warnings; our $VERSION = '0.02';
use Module::Generate::Hash; use PerlIO::via::YAML;
use base 'Import::Export'; our %EX = ( generate => [qw/all/] );
sub generate { open my $fh, '<via(YAML)', $_[0] or die $!; my $yaml = load $fh; close $fh; Module::Generate::Hash::generate($yaml); }
1;
__END__;

=head1 NAME

Module::Generate::YAML - Assisting with module generation via YAML.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Module::Generate::YAML qw/generate/;

	generate('/path/to/file.yml');	

=head1 EXPORT

=head2 generate

This module exports a single method generate which accepts a file path that is a distribution specification in yaml format.

	generate('/path/to/file.yml')

=head1 EXAMPLE

	# planes.yml
	---
	author: LNATION
	classes:
	  Planes:
	    abstract: Over my head.
	    accessors:
	    - airline
	    begin: |-
	      {
		$type = 'boeing';
	      }
	    our: $type
	    subs:
	    - type
	    - code: sub { $type }
	      example: $plane->type
	      pod: Returns the type of plane.
	    - altitude
	    - code: |-
		{
		  $_[1] / $_[2];
		}
	      example: $plane->altitude(100, 100)
	      pod: Discover the altitude of the plane.
	dist: Planes
	email: email@lnation.org
	version: '0.01'
	
	# command line

	perl -MModule::Generate::YAML=all -e "generate('planes.yml')"

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-generate-yaml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Generate-YAML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Generate::YAML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Generate-YAML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Generate-YAML>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Module-Generate-YAML>

=item * Search CPAN

L<https://metacpan.org/release/Module-Generate-YAML>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Module::Generate::YAML
