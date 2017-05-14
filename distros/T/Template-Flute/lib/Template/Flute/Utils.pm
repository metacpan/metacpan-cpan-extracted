package Template::Flute::Utils;

use strict;
use warnings;

use File::Basename;
use File::Spec;

=head1 NAME

Template::Flute::Utils - Template::Flute utility functions

=head1 FUNCTIONS

=head2 derive_filename FILENAME SUFFIX [FULL] [ARGS]

Derives a filename with a different SUFFIX from FILENAME, e.g.

    derive_filename('templates/helloworld.html', '.xml')

returns

    templates/helloworld.xml

With the FULL parameter set it can be used to produce a path
for a relative filename from another filename with a directory,
e.g.

    derive_filename('templates/helloworld.html', 'foobar.png', 1)

returns

    templates/foobar.png

Also, with the C<pass_absolute> argument a SUFFIX containing
an absolute file path will be returned verbatim, e.g.

    derive_filename('templates/helloword.html',
                    '/home/racke/components/login.html',
                    1,
                    pass_absolute => 1)

produces

   /home/racke/components/login.html

=cut

sub derive_filename {
	my ($orig_filename, $suffix, $full, %args) = @_;
	my ($orig_dir, @frags);

	if ($args{pass_absolute} && File::Spec->file_name_is_absolute($suffix)) {
		# pass through suffixes with absolute file paths
		return $suffix;
	}
	
	@frags = fileparse($orig_filename, qr/\.[^.]*/);

	if ($full) {
		return $frags[1] . $suffix;
	}
	else {
		return $frags[1] . $frags[0] . $suffix;
	}
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
